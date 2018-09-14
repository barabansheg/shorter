defmodule Link do
  use Application
  require Logger
  import Supervisor.Spec

    def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Link.Router, [], port: 8080),
      worker(Mongo, [[name: :mongo, database: "test", pool: DBConnection.Poolboy, hostname: "localhost"]])
    ]

    Logger.info("Started application")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
