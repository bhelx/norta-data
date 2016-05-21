defmodule Norta.Repo.Migrations.AddEventIds do
  use Ecto.Migration

  def change do
    alter table(:vehicles) do
      add :event_id, :bigint, null: false
    end
    alter table(:server_responses) do
      add :event_id, :bigint, null: false
    end
  end
end
