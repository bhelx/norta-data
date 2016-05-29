defmodule Norta.Repo.Migrations.AddStaleToVehicles do
  use Ecto.Migration

  def change do
    alter table(:vehicles) do
      add :stale, :boolean
    end
  end
end
