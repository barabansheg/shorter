defmodule Link.Response do
    def render_response(result, errors) do
        Poison.encode!(%{"result" => result, "errors" => errors})
    end

    def send_response(request, status, data, errors \\ []) do
        :cowboy_req.reply(status, [{"content-type", "application/json"}], render_response(data, errors), request)

    end
end