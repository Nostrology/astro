defmodule AstroWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :astro

  @doc """
  Funky function to manually handle websocket connections so we can intercept the upgrade request to send NIP-11
  """
  def socket_dispatch(conn, _opts) do
    case Plug.Conn.get_req_header(conn, "accept") do
      ["application/nostr+json"] ->
        conn
        |> Plug.Conn.resp(
          200,
          Jason.encode!(%{
            name: "astro",
            description: "Astro Nostr Relay",
            pubkey: "npub1hmrjq05azqwrfcrffr35w6037c6y9h6y8vd9k7tlngqw5s7h8x6qae9s57",
            contact: "mailto:luke@axxim.net",
            supported_nips: [1, 11, 15, 20],
            software: "https://github.com/Nostrology/astro",
            version: "deadbeef"
          })
        )
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp()

      _ ->
        Phoenix.Transports.WebSocket.call(
          conn,
          {AstroWeb.Endpoint, AstroWeb.Socket,
           [
             path: "/",
             check_origin: false,
             timeout: :infinity
           ]}
        )
    end
  end

  # socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # socket "/", AstroWeb.Socket,
  #   longpoll: false,
  #   websocket: [
  #     path: "/",
  #     timeout: :infinity
  #   ]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :astro,
    gzip: false,
    only: AstroWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :astro
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug AstroWeb.Router
end
