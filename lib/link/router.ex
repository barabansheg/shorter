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

    @doc ~S"""
    Take type and result and errors params, return json string

    ## Example
      iex>Link.Router.render_response(:json, %{"test" => "test ok"}, [])  
      "{\"result\":{\"test\":\"test ok\"},\"errors\":[]}"

      iex>Link.Router.render_response(:plain, "test", [])  
      "{\"result\":\"test\",\"errors\":[]}"
    """

    def render_response(type, result \\ %{}, errors \\ [])

    def render_response(:json, result, errors) do
      Poison.encode!(%{"result" => result, "errors" => errors})
    end

    def render_response(:plain, result, errors) do
      Poison.encode!(%{"result" => result, "errors" => errors})
    end

    def send_response_plain(conn, status, data, errors \\ []) do
      send_resp(conn, status, render_response(:plain, data, errors))
    end

    def send_response_json(conn, status, data, errors \\ []) do
      conn = Plug.Conn.put_resp_header(conn, "content-type", "application/json") 
      send_resp(conn, status, render_response(:json, data, errors))
    end

    def add_link(conn) do
      %{"url" => url} = conn.body_params
      case UrlValidator.valid_url(url) do
        {:ok, valid_url} ->
          token = Randomizer.randomizer(10)
          hash = Randomizer.randomizer(6)
          Mongo.insert_one(:mongo, "urls", %{url: valid_url, count: 0, hash: hash, token: token}, pool: DBConnection.Poolboy)
          send_response_json(conn, 201, %{"token" => token, "hash" => hash})
        _ ->  
          send_response_json(conn, 422, %{}, ["UrlValidationError"])
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
        nil -> send_response_json(conn, 404,  %{}, ["UrlNotFound"])
        _ ->  Mongo.update_one(:mongo, "urls", query, %{"$inc": %{count: 1}}, pool: DBConnection.Poolboy)
              conn = Plug.Conn.put_resp_header(conn, "Location", url) 
              send_response_plain(conn, 301, "Redirecting...")
        end
    end
    
    def get_info_by_token(conn) do
      query = %{token: conn.path_params["token"]}
      url_record = get_url_record(query)
      count = url_record["count"]
      case count do
        nil -> send_response_json(conn, 404, %{}, ["TokenNotfound"])
        _ ->   send_response_json(conn, 200, %{count: count})
        end
    end


       
    get("/", do: send_response_plain(conn, 200, "Welcome"))
    get("/ping", do: send_response_plain(conn, 200, "pong"))
    post("/add", do: add_link(conn))
    get("/:hash", do: redirect_to_url(conn))
    get("/info/:token", do: get_info_by_token(conn))
    match(_, do: send_response_plain(conn, 404, "", ["RouteNotFound"]))
  end