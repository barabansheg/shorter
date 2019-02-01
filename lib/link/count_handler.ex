defmodule Link.CountHandler do
    alias Link.Response
    alias Link.DB

    def init(_protocol, _request, _options) do
        {:upgrade, :protocol, :cowboy_rest}
    end

    def allowed_methods(request, state) do
        {["GET"], request, state}
    end

    def to_html(request, state) do
        {token, request} = :cowboy_req.binding(:token, request)
        query = %{"token": token}
        url_record = DB.get_url_record(query)
        count = url_record["count"]
        case count do
            nil -> Response.send_response(request, 404, %{}, ["TokenNotfound"])
            _   -> Response.send_response(request, 200, %{count: count})
        end
        {:halt, request, state}
    end 

    def terminate(_reason, _request, _state), do:    :ok
end