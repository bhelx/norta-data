ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Norta.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Norta.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Norta.Repo)

