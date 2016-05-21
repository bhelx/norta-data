defmodule Norta.Repo.Migrations.CreateVehicle do
  use Ecto.Migration

  def change do
    create table(:vehicles) do
      add :route, :string
      add :rt_name, :string
      add :name, :integer
      add :lat, :float
      add :lng, :float
      add :bearing, :float
      add :speed, :float
      add :car_type, :string
      add :train, :integer
      add :reading_time, :datetime

      timestamps
    end

  end
end
