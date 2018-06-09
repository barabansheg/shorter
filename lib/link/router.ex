defmodule Link.Router do
    use Plug.Router
    use Plug.ErrorHandler
    alias Link.Plug.VerifyRequest
    alias Link.Randomizer
    alias Link.UrlValidator

    plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)  
    
    plug(
      VerifyRequest,
      fields: ["url"],
      paths: ["/add"]
    )
    
    plug(:match)
    plug(:dispatch)
    def do_new_link(conn) do
      %{"url" => url} = conn.body_params
      case UrlValidator.valid_url(url) do
        {:ok, valid_url} ->
          Mongo.insert_one(:mongo, "urls", %{url: valid_url, count: 0, hash: Randomizer.randomizer(6)}, pool: DBConnection.Poolboy)
          send_resp(conn, 200, "OK")
        _ ->
          send_resp(conn, 422, "Validation Error")
      end
    end
    get("/", do: send_resp(conn, 200, "Welcome"))
    get("/ping", do: send_resp(conn, 200, "pong"))
    post("/add", do: do_new_link(conn))
    match(_, do: send_resp(conn, 404, "Oops!"))

  end