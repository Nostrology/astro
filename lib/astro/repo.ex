defmodule Astro.Repo do
  use Ecto.Repo,
    otp_app: :astro,
    adapter: Ecto.Adapters.Postgres
end
