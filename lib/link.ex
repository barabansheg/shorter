defmodule Link do
  use Application
  require Logger
  import Supervisor.Spec

    def start(_type, _args) do
      db_url = Application.get_env(:link, :db_url)
      children = [
        %{ id: Link.CowboyServer,
          start: {Link.CowboyServer, :start_link, []}
        },    
        worker(Mongo, [[name: :mongo, pool: DBConnection.Poolboy, url: db_url]])
      ] 

    Logger.info("Started application")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
