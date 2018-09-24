defmodule LinkTest do
  use ExUnit.Case
  use Plug.Test
  doctest Link.Router
  alias Link.Router

  @opts Router.init([])

  setup do
   {result_ok, _} = Mongo.delete_many(:mongo, "urls", %{}, pool: DBConnection.Poolboy)
   result_ok
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
    body = %{"url" => "https://example-add.com"}
    conn = put_req_header(conn(:post, "/add", body), "content-type", "application/json") |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 201
    assert Enum.member?(conn.resp_headers, {"content-type", "application/json"}) == true
    {:ok, decoded_body} = Poison.decode(conn.resp_body)
    errors = decoded_body['errors']
    assert errors = []
  end

  test "url must be in db" do
    body = %{"url" => "https://example-get.com"}
    put_req_header(conn(:post, "/add", body), "content-type", "application/json") |> Router.call(@opts)
    url_record = Link.Router.get_url_record(%{})
    assert url_record["url"] === "https://example-get.com"
  end

  test "check redirect" do
    body = %{"url" => "https://example-hash.com"}
    conn = put_req_header(conn(:post, "/add", body), "content-type", "application/json") |> Router.call(@opts)
    {:ok, decoded_body} = Poison.decode(conn.resp_body)
    url_hash = decoded_body["result"]["hash"]
    conn = conn(:get, "/#{url_hash}") |> Router.call(@opts)
    assert conn.status == 301
    assert Enum.member?(conn.resp_headers, {"location", "https://example-hash.com"}) == true
  end

  test "check counter" do
    body = %{"url" => "https://example-counter.com"}
    conn = put_req_header(conn(:post, "/add", body), "content-type", "application/json") |> Router.call(@opts)
    {:ok, decoded_body} = Poison.decode(conn.resp_body)
    token = decoded_body["result"]["token"]
    url_hash = decoded_body["result"]["hash"]
    conn(:get, "/#{url_hash}") |> Router.call(@opts)
    conn = conn(:get, "/info/#{token}") |> Router.call(@opts)
    {:ok, decoded_body} = Poison.decode(conn.resp_body)
    count = decoded_body["result"]["count"]
    assert conn.status == 200
    assert count == 1
  end

end
