defmodule Link.CowboyServer do
    def start_link() do
        Link.CowboyServer.start()
        Link.Supervisor.start_link()
    end  

    def start() do
        dispatch_config = :cowboy_router.compile([
            { :_,
              [
                {'/', Link.WelcomeHandler, []},
                {'/add', Link.UrlAddHandler, []},
                {'/:hash', Link.RedirectHandler, []},
                {:_, Link.NotFoundHandler, []},
                
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
   
  