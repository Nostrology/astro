defmodule Nostr.Socket do
  @moduledoc ~S"""
  A socket implementation for Nostr.

  Used for building a relay.
  """

  require Logger
  require Phoenix.Endpoint

  alias Nostr.Socket

  @callback connect(params :: map, Socket.t()) :: {:ok, Socket.t()} | {:error, term} | :error
  @callback handle_event(event_map :: Map.t(), Socket.t()) ::
              {:ok, Socket.t()} | {:error, term} | :error
  @callback handle_request(subscription_id :: String.t(), filters :: map(), Socket.t()) ::
              {:ok, Socket.t()} | {:error, term} | :error
  @callback handle_other(request :: list(String.t()), Socket.t()) ::
              {:ok, Socket.t()} | {:error, term} | :error
  @callback handle_close(subscription_id :: String.t(), Socket.t()) ::
              {:ok, Socket.t()} | {:error, term} | :error

  defstruct assigns: %{},
            endpoint: nil,
            handler: nil,
            id: nil,
            private: %{},
            pubsub_server: nil,
            transport: nil,
            transport_pid: nil,
            serializer: nil

  @type t :: %Socket{
          assigns: map,
          endpoint: atom,
          handler: atom,
          id: String.t() | nil,
          private: map,
          pubsub_server: atom,
          serializer: atom,
          transport: atom,
          transport_pid: pid
        }

  defmacro __using__(_opts) do
    quote do
      ## User API

      import Nostr.Socket
      @behaviour Nostr.Socket

      def send_message(message), do: Nostr.Socket.__send_message__(message)

      ## Callbacks

      @behaviour Phoenix.Socket.Transport

      @doc false
      def child_spec(opts) do
        Nostr.Socket.__child_spec__(__MODULE__, opts, [])
      end

      @doc false
      def connect(map), do: Nostr.Socket.__connect__(__MODULE__, map)

      @doc false
      def init(state), do: Nostr.Socket.__init__(state)

      @doc false
      def handle_in(message, state), do: Nostr.Socket.__in__(message, state)

      @doc false
      def handle_info(message, state), do: Nostr.Socket.__info__(message, state)

      @doc false
      def terminate(reason, state), do: Nostr.Socket.__terminate__(reason, state)
    end
  end

  def __send_message__(message) when is_list(message) do
    send(self(), {:socket_push, :text, Jason.encode!(message)})
  end

  ## CALLBACKS IMPLEMENTATION

  def __child_spec__(handler, opts, socket_options) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    opts = Keyword.merge(socket_options, opts)
    partitions = Keyword.get(opts, :partitions, System.schedulers_online())
    args = {endpoint, handler, partitions}
    Supervisor.child_spec({Phoenix.Socket.PoolSupervisor, args}, id: handler)
  end

  def __connect__(user_socket, map) do
    {:ok, {map, user_socket}}
  end

  def __init__(state) do
    {:ok, state}
  end

  def __in__({message, [opcode: :text]}, {state, socket}) do
    handle_in(message, state, socket)
  end

  def __info__({:DOWN, ref, _, pid, reason}, {state, socket}) do
    dbg("DOWN!")
    {:ok, {state, socket}}
  end

  # def __info__(%Broadcast{event: "disconnect"}, state) do
  #   {:stop, {:shutdown, :disconnected}, state}
  # end

  def __info__({:socket_push, opcode, payload}, state) do
    Logger.info("SEND: #{payload}")
    {:push, {opcode, payload}, state}
  end

  def __info__({:new_event, event, subscription_id}, state) do
    {:push, {:text, Jason.encode!(["EVENT", subscription_id, event])}, state}
  end

  # def __info__({:socket_close, pid, _reason}, {state, socket}) do
  #   dbg("socket closed?")
  #   # socket_close(pid, {state, socket})
  #   {:ok, state}
  # end

  def __info__(:garbage_collect, state) do
    :erlang.garbage_collect(self())
    {:ok, state}
  end

  def __info__(_, state) do
    {:ok, state}
  end

  def __terminate__(_reason, _state_socket) do
    :ok
  end

  defp handle_in(
         message,
         state,
         socket
       ) do
    Logger.info("RECV: #{message}")

    handler_response =
      case Jason.decode(message) do
        {:ok, request} ->
          case request do
            ["REQ", subscription_id | filters] ->
              socket.handle_request(subscription_id, filters, socket)

            ["EVENT", event_map] ->
              socket.handle_event(event_map, socket)

            ["CLOSE", subscription_id] ->
              socket.handle_close(subscription_id, socket)

            # ["AUTH", signed_event_json] ->
            #   nil

            other ->
              Logger.warning("Unexpected Nostr request: #{inspect(other)}")
              socket.handle_other(request, socket)
          end

        {:error, _} ->
          Logger.warning("Invalid JSON request: #{inspect(message)}")
          :error
      end

    case handler_response do
      {:noreply, socket} ->
        {:ok, {state, socket}}

      {:ok, socket} ->
        {:ok, {state, socket}}

      :error ->
        :error
    end
  end
end
