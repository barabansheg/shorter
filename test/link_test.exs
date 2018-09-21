defmodule LinkTest do
  use ExUnit.Case
  use Plug.Test
  doctest Link.Router
  alias Link.Router

  @opts Router.init([])

  setup_all do
    Mongo.remove(:mongo, "urls", %{}, pool: DBConnection.Poolboy)
  end

  test "got ping" do
    conn = conn(:get, "/ping") |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.resp_body == "{\"result\":\"pong\",\"errors\":[]}"
  end

  test "got 404 RouteNotFound" do
    conn = conn(:get, "/does/not/exists/route") |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "{\"result\":\"\",\"errors\":[\"RouteNotFound\"]}"
  end

  test "add not valid url" do
    body = %{"url" => "notvalid"}
    conn = put_req_header(conn(:post, "/add", body), "content-type", "application/json") |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 422
    assert Enum.member?(conn.resp_headers, {"content-type", "application/json"}) == true
    assert conn.resp_body == "{\"result\":{},\"errors\":[\"UrlValidationError\"]}"
  end

  test "add valid url" do
    body = %{"url" => "https://example.com"}
    conn = put_req_header(conn(:post, "/add", body), "content-type", "application/json") |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 201
    assert Enum.member?(conn.resp_headers, {"content-type", "application/json"}) == true
  end

  test "url must be in db" do
    url_record = Link.Router.get_url_record(%{})
    assert url_record["url"] === "https://example.com"
  end

end
