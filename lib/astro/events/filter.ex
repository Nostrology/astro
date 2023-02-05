defmodule Astro.Events.Filter do
  @moduledoc """

  <filters> is a JSON object that determines what events will be sent in that subscription, it can have the following attributes:

  {
    "ids": <a list of event ids or prefixes>,
    "authors": <a list of pubkeys or prefixes, the pubkey of an event must be one of these>,
    "kinds": <a list of a kind numbers>,
    "#e": <a list of event ids that are referenced in an "e" tag>,
    "#p": <a list of pubkeys that are referenced in a "p" tag>,
    "since": <an integer unix timestamp, events must be newer than this to pass>,
    "until": <an integer unix timestamp, events must be older than this to pass>,
    "limit": <maximum number of events to be returned in the initial query>
  }
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :ids, {:array, :string}
    field :authors, {:array, :string}
    field :kinds, {:array, :integer}
    field :"#e", {:array, :string}
    field :"#p", {:array, :string}
    field :since, :integer
    field :until, :integer
    field :limit, :integer
  end

  def changeset(filter, params \\ %{}) do
    filter
    |> cast(params, [
      :name,
      :ids,
      :authors,
      :kinds,
      :"#e",
      :"#p",
      :since,
      :until,
      :limit
    ])
  end
end
