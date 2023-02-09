# Astro
An [Nostr](https://github.com/nostr-protocol/nostr) relay, built using Elixir.

### Implementation
- [x] NIP-01: Basic protocol flow description
- [ ] NIP-02: Contact List and Petnames
- [ ] NIP-03: OpenTimestamps Attestations for Events
- [ ] NIP-05: Mapping Nostr keys to DNS-based internet identifiers
- [ ] NIP-09: Event Deletion
- [x] NIP-11: Relay Information Document
- [ ] NIP-12: Generic Tag Queries
- [x] NIP-15: End of Stored Events Notice
- [x] NIP-16: Event Treatment
- [x] NIP-20: Command Results
- [ ] NIP-22: Event created_at limits (future-dated events only)
- [ ] NIP-26: Event Delegation (implemented, but currently disabled)
- [ ] NIP-28: Public Chat
- [ ] NIP-33: Parameterized Replaceable Events

## Development
You can setup your own development / production environment of Astro easily by grabbing your dependencies, creating your database, and running the server.

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check out the deployment guides](https://hexdocs.pm/phoenix/deployment.html).


### Contributing
1. [Fork it!](http://github.com/Nostrology/astro/fork)
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request


## Testing
Astro includes a comprehensive and very fast test suite, so you should be encouraged to run tests as frequently as possible.

```sh
mix test
```

## Help
If you need help with anything, please feel free to open [a GitHub Issue](https://github.com/Nostrology/astro/issues/new).

## License
WebSubHub is licensed under the [MIT License](LICENSE.md).
