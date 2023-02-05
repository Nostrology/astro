defmodule Astro.Repo.Migrations.AddEventsTable do
  use Ecto.Migration

  def change do
    create table("events") do
      add :id, :string, size: 64, primary_key: true
      add :pubkey, :string, size: 64
      add :created_at, :integer
      add :kind, :integer
      add :content, :text
      add :sig, :string, size: 128
    end

    create table("event_tags") do
      add :event_id, references(:events, type: :string, on_delete: :delete_all)
      add :key, :string
      add :value, :string
      add :params, {:array, :string}
    end
  end
end
