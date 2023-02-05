defmodule Astro.Events.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  @derive Jason.Encoder
  schema "event_tags" do
    field :event_id, :string
    field :key, :string
    field :value, :string
    field :params, {:array, :string}
  end

  def changeset(event, params \\ %{}) do
    event
    |> cast(params, [
      # :event_id,
      :key,
      :value,
      :params
    ])
    |> validate_required([
      # :event_id,
      :key,
      :value
    ])
  end
end
