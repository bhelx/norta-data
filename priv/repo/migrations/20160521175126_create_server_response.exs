defmodule Norta.Repo.Migrations.CreateServerResponse do
  use Ecto.Migration

  def change do
    create table(:server_responses) do
      add :status_code, :integer
      add :xml_valid, :boolean
      add :response_valid, :boolean
      add :md5_match, :boolean

      timestamps
    end

  end
end
