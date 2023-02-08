defmodule Astro.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "events" do
    field :id, :string
    field :pubkey, :string
    field :created_at, :integer
    field :kind, :integer
    field :tags, {:array, {:array, :string}}, virtual: true
    field :content, :string
    field :sig, :string

    has_many :event_tags, Astro.Events.Tag, references: :id, foreign_key: :event_id
  end

  def changeset(event, params \\ %{}) do
    event
    |> cast(params, [
      :id,
      :pubkey,
      :created_at,
      :kind,
      :content,
      :sig
    ])
    # Tags must be cast to allow for empty values, eg ["e", "id", "", "root"]
    |> cast(params, [:tags], empty_values: [])
    |> validate_required([
      :id,
      :pubkey,
      :created_at,
      :kind,
      :tags,
      :content,
      :sig
    ])
    |> validate_length(:id, is: 64)
    |> validate_length(:pubkey, is: 64)
    |> validate_number(:created_at, greater_than: 0)
    |> validate_length(:sig, is: 128)
    |> validate_id()
    |> validate_signature()
    |> unique_constraint(:id, name: :events_id_index)
  end

  @doc """
  Validates an ID by generating one from the event JSON
  """
  def validate_id(changeset) do
    validate_change(changeset, :id, fn field, value ->
      generated_id = Astro.Events.generate_id(changeset.changes)

      if generated_id == value do
        []
      else
        [{field, "invalid id"}]
      end
    end)
  end

  @doc """
  Validates that the event is properly signed
  """
  def validate_signature(changeset) do
    # TODO!
    validate_change(changeset, :sig, fn field, _sig ->
      case Astro.Events.verify_signature(changeset.changes) do
        true ->
          []

        _ ->
          [{field, "invalid signature"}]
      end
    end)
  end
end

defimpl Jason.Encoder, for: Astro.Events.Event do
  @doc """
  Special JSON encoding for the Event struct is required to pluck out the event_tags into tags
  and format them appropriately.
  """
  def encode(%Astro.Events.Event{} = event, opts) do
    tags = Enum.map(event.event_tags, fn tag -> [tag.key, tag.value] ++ tag.params end)

    Jason.Encode.map(
      %{
        id: event.id,
        pubkey: event.pubkey,
        created_at: event.created_at,
        kind: event.kind,
        tags: tags,
        content: event.content,
        sig: event.sig
      },
      opts
    )
  end
end
