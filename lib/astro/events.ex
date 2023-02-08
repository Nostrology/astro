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

        case process_event(changeset) do
          {:ok, event} ->
            Astro.EventRouter.push_event(event)
            {:ok, event}

          error ->
            dbg(error)
            :error
        end

      errored ->
        # Good
        dbg(errored)
        # NIP-01 doesn't define success / fail on event publishing
        :error
    end
  end

  defp process_event(changeset) do
    %{kind: kind} = new_event = changeset.changes

    cond do
      kind >= 10000 and kind < 20000 ->
        # Replaceable Event
        # A replaceable event is defined as an event with a kind 10000 <= n < 20000. Upon a replaceable event
        # with a newer timestamp than the currently known latest replaceable event with the same kind being
        # received, and signed by the same key, the old event SHOULD be discarded and replaced with the newer event.

        # Ignore deletion error as we may not have the event yet
        from(e in Event,
          where:
            e.pubkey == ^new_event.pubkey and e.kind == ^new_event.kind and
              e.created_at < ^new_event.created_at
        )
        |> Repo.delete()

        Astro.Repo.insert(changeset)

      kind >= 20000 and kind < 30000 ->
        # Ephemeral Event
        # An ephemeral event is defined as an event with a kind 20000 <= n < 30000. Upon an ephemeral event being
        # received, the relay SHOULD send it to all clients with a matching filter, and MUST NOT store it.

        {:ok, Ecto.Changeset.apply_changes(changeset.changes)}

      true ->
        # kind >= 1000 and kind < 10000
        # Regular Event
        # A regular event is defined as an event with a kind 1000 <= n < 10000. Upon a regular event being received,
        # the relay SHOULD send it to all clients with a matching filter, and SHOULD store it. New events of the
        # same kind do not affect previous events in any way.

        Astro.Repo.insert(changeset)
    end
  end

  def transmute_tags(tags) do
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

  def json(%Event{} = event) do
    tags = Enum.map(event.event_tags, fn tag -> [tag.key, tag.value] ++ tag.params end)

    json(%{
      pubkey: event.pubkey,
      created_at: event.created_at,
      kind: event.kind,
      tags: tags,
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
