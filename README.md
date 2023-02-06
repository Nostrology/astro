# Astro
An Nostr relay, built using Elixir.

## Implementation

- [x] NIP-01
- [x] NIP-11
- [x] NIP-15
- [x] NIP-16
- [x] NIP-20


### Implementation Development Notes
#### Efficient Publication
Publication should be done through a FIFO based GenServer queue, that instantly consumes the event & adds it to a buffer. On every x events, or y time, we bulk save the events into the database and trigger their associated PubSub events. For latency purposes, we should likely have an automatically configured mode that direct inserts vs queue inserts these events. The GenServer could handle that too.

#### Efficient Subscriptions
ids = ["1234", "1234some64-byte-thing"]

PubSub.subscribe("1234")

We need to keep a stateful list of all subscriptions, and have a PubSub interceptor that listens for new events, runs them through the stateful list, and then actually fires off the real events.
* Optionally: Instead of firing "real events" we could just notify the process that cares about it. 


## Running

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
