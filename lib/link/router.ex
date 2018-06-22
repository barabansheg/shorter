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

    def get_url_record(query) do
      Mongo.find(:mongo, "urls", query, pool: DBConnection.Poolboy) |> Enum.to_list |> List.first
    end

    def redirect_to_url(conn) do
      query = %{hash: conn.path_params["hash"]}
      url_record = get_url_record(query)
      url = url_record["url"]
      case url do
        nil -> send_resp(conn, 404, 'Url not found')
        _ ->  Mongo.update_one(:mongo, "urls", query, %{"$inc": %{count: 1}}, pool: DBConnection.Poolboy)
              conn = Plug.Conn.put_resp_header(conn, "Location", url) 
              send_resp(conn, 301, "Redirecting...")
        end
    end
    
    def get_info_by_token(conn) do
      query = %{token: conn.path_params["token"]}
      url_record = get_url_record(query)
      count = url_record["count"]
      case count do
        nil -> send_resp(conn, 404, 'Token not found')
        _ ->   send_resp(conn, 200, to_string(count))
        end
    end


       
    get("/", do: send_resp(conn, 200, "Welcome"))
    get("/ping", do: send_resp(conn, 200, "pong"))
    post("/add", do: add_link(conn))
    get("/:hash", do: redirect_to_url(conn))
    get("/info/:token", do: get_info_by_token(conn))
    match(_, do: send_resp(conn, 404, "Oops!"))

  end