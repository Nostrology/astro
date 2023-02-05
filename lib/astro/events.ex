defmodule Astro.Events do
  import Ecto.Query

  alias Astro.Repo
  alias Astro.Events.Event
  alias Astro.Events.Tag
  alias Astro.Events.Filter

  def create_event(%{"tags" => input_tags} = event_map) do
    case Astro.Events.Event.changeset(%Astro.Events.Event{}, event_map) do
      %Ecto.Changeset{valid?: true} = changeset ->
        tags = transmute_tags(input_tags)
        changeset = Ecto.Changeset.put_assoc(changeset, :event_tags, tags)

        {:ok, event} = Astro.Repo.insert(changeset)

        Astro.EventRouter.push_event(event)

        {:ok, event}

      errored ->
        dbg(errored)
        # NIP-01 doesn't define success / fail on event publishing
        :error
    end
  end

  defp transmute_tags(tags) do
    Enum.map(tags, fn
      [key, value | params] ->
        params = %{
          key: key,
          value: value,
          params: params
        }

        Astro.Events.Tag.changeset(%Astro.Events.Tag{}, params)
        params
    end)
  end

  def list_events_with_filters(unsafe_filters) do
    case Filter.changeset(%Filter{}, unsafe_filters) do
      %Ecto.Changeset{valid?: true, changes: safe_filters} ->
        limit = Map.get(safe_filters, :limit, 100)
        safe_filters = Map.delete(safe_filters, :limit)

        from(e in Event,
          join: t in Tag,
          as: :tags,
          on: e.id == t.event_id,
          where: ^build_and(safe_filters),
          order_by: [desc: e.created_at],
          limit: ^limit,
          preload: [:event_tags]
        )
        |> Repo.all()

      _ ->
        # TODO Some kind of warning?
        []
    end
  end

  def matches_filters(%Event{} = event, unsafe_filters) do
    case Filter.changeset(%Filter{}, unsafe_filters) do
      %Ecto.Changeset{valid?: true, changes: safe_filters} ->
        Enum.map(safe_filters, fn
          {:ids, values} ->
            Enum.map(values, fn value ->
              String.starts_with?(event.id, value)
            end)
            |> Enum.any?()

          {:authors, values} ->
            Enum.map(values, fn value ->
              String.starts_with?(event.pubkey, value)
            end)
            |> Enum.any?()

          {:kinds, kinds} ->
            event.kind in kinds

          {:since, since} ->
            event.created_at < since

          {:until, until} ->
            event.created_at > until

          _ ->
            false
        end)
        |> Enum.any?()

      _ ->
        # TODO Some kind of warning?
        :error
    end
  end

  @types %{
    :ids => :id,
    :authors => :pubkey,
    :"#e" => [:tags, :"#e"],
    :"#p" => [:tags, :"#p"]
  }

  @tags %{
    :"#e" => "e",
    :"#p" => "p"
  }

  def build_and(filters) do
    Enum.reduce(filters, nil, fn
      {k, v}, nil -> build_condition(k, v)
      {k, v}, conditions -> dynamic([e], ^build_condition(k, v) and ^conditions)
    end)
  end

  defp build_condition(:kinds, values) do
    dynamic([e], e.kind in ^values)
  end

  defp build_condition(:since, value) do
    dynamic([e], e.created_at < ^value)
  end

  defp build_condition(:until, value) do
    dynamic([e], e.created_at > ^value)
  end

  # Special condition for nested lists
  defp build_condition(key, values) when is_list(values) do
    Enum.reduce(values, nil, fn
      v, nil -> build_condition(key, v)
      v, conditions -> dynamic([e], ^build_condition(key, v) or ^conditions)
    end)
  end

  # Special condition for prefixable search values
  defp build_condition(key, value) when key in [:ids, :authors] do
    field = @types[key]

    if byte_size(value) < 64 do
      value = value <> "%"
      dynamic([e], ilike(field(e, ^field), ^value))
    else
      dynamic([e], field(e, ^field) == ^value)
    end
  end

  # Special condition for tags
  defp build_condition(key, value) when key in [:"#e", :"#p"] do
    tag_field = @tags[key]

    if byte_size(value) < 64 do
      value = value <> "%"
      dynamic([tags: t], t.key == ^tag_field and ilike(t.value, ^value))
    else
      dynamic([tags: t], t.key == ^tag_field and t.value == ^value)
    end
  end

  defp build_condition(key, value) do
    field = @types[key]
    dynamic([e], field(e, ^field) == ^value)
  end

  defp field_selector([:tags, selector]) do
    :tags
  end

  def json(%Event{} = event) do
    # tags = event.tags |> Enum.map(fn {k, v} -> [k, v] end) |> Enum.into([])
    # dbg(tags)

    json(%{
      pubkey: event.pubkey,
      created_at: event.created_at,
      kind: event.kind,
      tags: event.tags,
      content: event.content
    })
  end

  def json(%{pubkey: pubkey, created_at: created_at, kind: kind, tags: tags, content: content}) do
    [0, pubkey, created_at, kind, tags, content]
    |> Jason.encode!()
  end

  def generate_id(event) do
    payload = json(event)

    :crypto.hash(:sha256, payload)
    |> Base.encode16(case: :lower)
  end

  def verify_signature(%Event{id: id, pubkey: pubkey, sig: sig}) do
    verify_signature(%{id: id, pubkey: pubkey, sig: sig})
  end

  def verify_signature(%{id: id, pubkey: pubkey, sig: sig}) do
    id = Base.decode16!(id, case: :lower)
    pubkey = Base.decode16!(pubkey, case: :lower)
    sig = Base.decode16!(sig, case: :lower)

    # Curvy is native Elixir, but wasn't able to get it working appropriately.
    # Curvy.verify(sig, id, pubkey, hash: false)
    :ok == K256.Schnorr.verify_message_digest(id, sig, pubkey)
  end
end
