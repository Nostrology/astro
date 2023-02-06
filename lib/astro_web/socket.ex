defmodule AstroWeb.Socket do
  use Nostr.Socket

  def connect(_, socket) do
    {:ok, socket}
  end

  def handle_event(%{"id" => event_id} = event_map, socket) do
    case Astro.Events.create_event(event_map) do
      {:ok, _event} ->
        # Created event will be send to the user via their subscription (if subscribed!)
        send_message(["OK", event_id, true, "OK!"])

      _ ->
        send_message(["OK", event_id, false, "invalid: Not OK!"])
    end

    {:ok, socket}
  end

  def handle_request(subscription_id, list_of_filters, socket) do
    # Fetch the searched events and async them out to the client
    list_of_filters
    |> Enum.map(&Astro.Events.list_events_with_filters/1)
    |> List.flatten()
    |> Enum.map(fn event ->
      send_message(["EVENT", subscription_id, event])
    end)

    send_message(["EOSE", subscription_id])
    Astro.EventRouter.push_subscription(self(), subscription_id, list_of_filters)

    {:ok, socket}
  end

  def handle_other(_req, socket) do
    {:ok, socket}
  end

  def handle_close(subscription_id, socket) do
    Astro.EventRouter.close_subscription(subscription_id)
    {:ok, socket}
  end
end
