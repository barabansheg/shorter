defmodule Link.RedirectHandler do
    alias Link.Response
    alias Link.DB

    def init(_protocol, _request, _options) do
        {:upgrade, :protocol, :cowboy_rest}
    end

    def allowed_methods(request, state) do
        {["GET"], request, state}
    end
    
    def to_html(request, state) do
        {hash, request} = :cowboy_req.binding(:hash, request)
        query = %{"hash": hash}
        url_record = DB.get_url_record(query)
        url = url_record["url"]
        case url do
            nil -> Response.send_response(request, 404, %{}, ["UrlNotFound"])
            _   -> DB.update_one(query, %{"$inc": %{count: 1}})
                   :cowboy_req.reply(301, [{"location", url}], "", request)
            end
        {:halt, request, state}
    end

    def terminate(_reason, _request, _state), do:    :ok
end
