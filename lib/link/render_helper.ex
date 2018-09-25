defmodule Link.RenderHelper do
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

end