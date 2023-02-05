defmodule Astro.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AstroWeb.Telemetry,
      # Start the Ecto repository
      Astro.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Astro.PubSub},
      # Start the Endpoint (http/https)
      AstroWeb.Endpoint,
      Astro.EventRouter
      # Start a worker by calling: Astro.Worker.start_link(arg)
      # {Astro.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Astro.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AstroWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
