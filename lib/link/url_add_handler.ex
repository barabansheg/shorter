defmodule Link.UrlAddHandler do
    alias Link.Randomizer
    alias Link.UrlValidator

    def render_response(result, errors) do
        Poison.encode!(%{"result" => result, "errors" => errors})
    end

    def send_response(request, status, data, errors \\ []) do
        :cowboy_req.reply(status, [{"content-type", "application/json"}], render_response(data, errors), request)
    end

    def init(_protocol, _request, _options) do
        {:upgrade, :protocol, :cowboy_rest}
    end

    def allowed_methods(request, state) do
        {["POST"], request, state}
    end

    def content_types_accepted(request, state) do
        {[{"application/json", :add_link}], request, state}
    end

    def add_link(request, state) do
        {:ok, body, request} = :cowboy_req.body(request)
        %{"url" => url} = Poison.decode!(body)

        case UrlValidator.valid_url(url) do
          {:ok, valid_url} ->
            token = Randomizer.randomizer(10)
            hash = Randomizer.randomizer(6)
            Mongo.insert_one(:mongo, "urls", %{url: valid_url, count: 0, hash: hash, token: token}, pool: DBConnection.Poolboy)
            send_response(request, 201, %{"token" => token, "hash" => hash})
           
          _ ->
            send_response(request, 422, %{}, ["UrlValidationError"])
        end
        {:halt, request, state}
      end

    def terminate(_reason, _request, _state), do:    :ok
end
