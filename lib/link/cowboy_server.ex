defmodule Link.CowboyServer do
    def start_link() do
        Link.CowboyServer.start(1, 2)
        Link.Supervisor.start_link()
    end  

    def start(_type, _args) do
        dispatch_config = :cowboy_router.compile([
            { :_,
              [
                {:_, Link.CowboyHandler, []},
              ]
            }
          ])
          

        { :ok, _ } = :cowboy.start_http(:http,
                                        100,
                                       [{:port, 8080}],
                                       [{ :env, [{:dispatch, dispatch_config}]}]
                                       )
    end
 
    def terminate(_reason, _request, _state), do:    :ok
end
   
  