defmodule Norta.ServerResponse do
  use Norta.Web, :model

  schema "server_responses" do
    field :status_code, :integer
    field :xml_valid, :boolean
    field :response_valid, :boolean
    field :md5_match, :boolean
    field :event_id, :integer

    timestamps
  end

  @required_fields ~w(status_code xml_valid response_valid event_id)
  @optional_fields ~w(md5_match)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
