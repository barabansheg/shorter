defmodule Link.UrlAddHandler do
    alias Link.Randomizer
    alias Link.UrlValidator
    alias Link.Response

    def init(_protocol, _request, _options) do
        {:upgrade, :protocol, :cowboy_rest}
    end

    def allowed_methods(request, state) do
        request = :cowboy_req.set_resp_header("access-control-allow-origin", "*", request)
        request = :cowboy_req.set_resp_header("access-control-allow-methods", "POST, OPTIONS", request)
        request = :cowboy_req.set_resp_header("access-control-allow-headers", "content-type", request)
        {["POST", "OPTIONS"], request, state}
    end

    def content_types_accepted(request, state) do
        {[{"application/json", :from_json}], request, state}
    end

    def from_json(request, state) do
        {:ok, body, request} = :cowboy_req.body(request)
        %{"url" => url} = Poison.decode!(body)

        case UrlValidator.valid_url(url) do
          {:ok, valid_url} ->
            token = Randomizer.randomizer(10)
            hash = Randomizer.randomizer(6)
            Mongo.insert_one(:mongo, "urls", %{url: valid_url, count: 0, hash: hash, token: token}, pool: DBConnection.Poolboy)
            Response.send_response(request, 201, %{"token" => token, "hash" => hash})
           
          _ ->
            Response.send_response(request, 422, %{}, ["UrlValidationError"])
        end
        {:halt, request, state}
      end

    def terminate(_reason, _request, _state), do:    :ok
end
