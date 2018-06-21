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
    def add_link(conn) do
      %{"url" => url} = conn.body_params
      case UrlValidator.valid_url(url) do
        {:ok, valid_url} ->
          Mongo.insert_one(:mongo, "urls", %{url: valid_url, count: 0, hash: Randomizer.randomizer(6)}, pool: DBConnection.Poolboy)
          send_resp(conn, 200, "OK")
        _ ->  
          send_resp(conn, 422, "Validation Error")
      end
    end

    def get_url_by_hash(hash) do
      url_record = Mongo.find(:mongo, "urls", %{hash: hash}, pool: DBConnection.Poolboy) |> Enum.to_list |> List.first
      Mongo.update_one(:mongo, "urls", %{hash: hash}, %{"$inc": %{count: 1}}, pool: DBConnection.Poolboy)
      url_record["url"]
    end

    def redirect_to_url(conn) do
      url = get_url_by_hash(conn.path_params["hash"])
      case url do
        nil -> send_resp(conn, 404, 'Url not found')
        _ ->  conn = Plug.Conn.put_resp_header(conn, "Location", url  ) 
              send_resp(conn, 301, "Redirecting...")
        end
    end
    
    get("/", do: send_resp(conn, 200, "Welcome"))
    get("/ping", do: send_resp(conn, 200, "pong"))
    post("/add", do: add_link(conn))
    get("/:hash", do: redirect_to_url(conn))
    match(_, do: send_resp(conn, 404, "Oops!"))

  end