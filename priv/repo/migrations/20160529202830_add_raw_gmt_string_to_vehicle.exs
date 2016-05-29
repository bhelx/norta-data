defmodule Norta.Repo.Migrations.AddRawGmtStringToVehicle do
  use Ecto.Migration

  def change do
    alter table(:vehicles) do
      add :gmt, :string
    end
  end
end
