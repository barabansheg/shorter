defmodule Link do
  use Application
  require Logger
  import Supervisor.Spec

    def start(_type, _args) do
      db_url = Application.get_env(:link, :db_url)
      children = [
        Plug.Adapters.Cowboy.child_spec(:http, Link.Router, [], port: 8080),
        worker(Mongo, [[name: :mongo, pool: DBConnection.Poolboy, url: db_url]])
      ] 

    Logger.info("Started application")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
