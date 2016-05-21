defmodule Norta.Repo.Migrations.AddEventIdIndexes do
  use Ecto.Migration

  def change do
    create index(:vehicles, [:event_id])
    create index(:server_responses, [:event_id])
  end
end
