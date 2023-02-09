defmodule Astro.EventRouter do
  @doc """
  EventRouter is responsible for handling _all_ events and seeing if they match against filter subscriptions registered on the server.

  Each server is responsible for their own event handling / filtering / re-dispatching.

  Phoenix.PubSub is used to route events to all servers.
  """
  use GenServer

  require Logger

  alias Astro.Events.Event
  alias Phoenix.PubSub

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def push_subscription(pid, subscription_id, list_of_filters) do
    Logger.info("Astro.EventRouter: Got push_subscription for #{subscription_id}")
    GenServer.cast(__MODULE__, {:push_subscription, pid, subscription_id, list_of_filters})
  end

  def close_subscription(subscription_id) do
    Logger.info("Astro.EventRouter: Got close_subscription for #{subscription_id}")
    GenServer.cast(__MODULE__, {:close_subscription, subscription_id})
  end

  def push_event(%Event{} = event) do
    PubSub.broadcast(Astro.PubSub, "events", {:new_event, event})
  end

  @impl true
  def init(_) do
    Logger.info("Running Astro.EventRouter")
    PubSub.subscribe(Astro.PubSub, "events")

    {:ok, %{filters: %{}}}
  end

  @impl true
  def handle_cast({:push_subscription, pid, subscription_id, list_of_filters}, state) do
    filters = Map.put(state.filters, subscription_id, {pid, list_of_filters})
    {:noreply, %{state | filters: filters}}
  end

  def handle_cast({:close_subscription, subscription_id}, state) do
    filters = Map.delete(state.filters, subscription_id)
    {:noreply, %{state | filters: filters}}
  end

  @impl true
  def handle_info({:new_event, event}, state) do
    {time, subscribers} =
      :timer.tc(fn ->
        Enum.map(state.filters, fn {subscription_id, {pid, list_of_filters}} ->
          Enum.each(list_of_filters, fn filters ->
            if Astro.Events.matches_filters(event, filters) do
              Logger.info(
                "Astro.EventRouter: Sending event to #{subscription_id} on #{inspect(pid)}"
              )

              send(pid, {:new_event, event, subscription_id})
            end
          end)
        end)
        |> length()
      end)

    :telemetry.execute(
      [:astro, :event_router, :event_filter_match],
      %{duration: time},
      %{
        subscribers: subscribers
      }
    )

    {:noreply, state}
  end
end
