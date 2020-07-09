defmodule VisitJsonTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defp init_empty() do
    VisitJson.Endpoint.init([])
  end

  defp check_status(conn, is_ok) do
    conn = VisitJson.Endpoint.call(conn, init_empty())

    assert conn.state == :sent
    assert conn.status == 200

    {_, response} = Poison.decode(conn.resp_body)
    assert Map.has_key?(response, "status")
    if is_ok do
      assert response["status"] == "ok"
    else
      assert response["status"] != "ok"
    end
  end

  @tag missed_parameters: true
  test "Missed parameters" do
    tests = [
      ["/visited_domains", false],
      ["/visited_domains?to=3883838", false],
      ["/visited_domains?from=823737", false],
      ["/visited_domains?from=1545217638&to=1545221231", true],
      ["/visited_domains?from=1545221231&to=1545217638", false]
    ]
    Enum.each(
      tests,
      fn elem ->
        input = hd elem
        result = hd tl elem

        conn = conn(:get, input)
               |> put_req_header("content-type", "application/json")
        check_status(conn, result)
      end
    )
  end


  test "Check status" do
    tests = [
      %{path: "/visited_links", req_type: :post, params: nil, waiting: false},
      %{
        path: "/visited_links",
        req_type: :post,
        params: %{
          "links" => ["https://ya.ru", "https://ya.ru?q=123"]
        },
        waiting: true
      }
    ]

    Enum.each(
      tests,
      fn elem ->
        conn = conn(elem.req_type, elem.path, elem.params)
        check_status(conn, elem.waiting)
      end
    )
  end

  test "Endpoint availability" do
    tests = [
      %{path: "/", state: :sent, status: 200, resp_body: "It works!"},
      %{path: "/something_crazy_path/300", state: :sent, status: 404, resp_body: "You are moved somewhere... Q|*_*|Q"},
      %{path: "/path", state: :sent, status: 404, resp_body: "You are moved somewhere... Q|*_*|Q"},
    ]

    Enum.each(
      tests,
      fn elem ->
        conn = conn(:get, elem.path)
        conn = VisitJson.Endpoint.call(conn, init_empty())

        assert conn.state == elem.state
        assert conn.status == elem.status
        assert conn.resp_body == elem.resp_body
      end
    )
  end

  @tag link_corectness: true
  test "Link corectness" do
    tests = [
      ["http://ya.ru", "ya.ru",],
      ["http://ya.ru?q=123", "ya.ru",],
      ["http://ya.ru?q=123&&w=993", "ya.ru"],
      ["https://stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor", "stackoverflow.com"],
      ["funbox.ru", "funbox.ru"]
    ]

    Enum.each(
      tests,
      fn elem ->
        result = VisitJson.Helpers.get_domain_from_link(hd elem)
        assert result == hd tl elem
      end
    )
  end

  @tag get_domains_from_list: true
  test "get_domains_from_list" do
    input = ["https://ya.ru/q=123", "www.sub.hello.com/sub/sub/3"]
    waiting = ["ya.ru", "hello.com"]

    result = VisitJson.Helpers.get_domains_from_links(input)

    assert result == waiting
  end

  @tag main_test: true
  test "Main tests" do
    VisitJson.TestHelpers.clear_redis_links()

    # Send info
    input = %{"links" => ["https://ya.ru", "https://ya.ru?q=123"]}

    conn = conn(:post, "/visited_links", input)
    conn = VisitJson.Endpoint.call(conn, init_empty())

    assert conn.state == :sent
    assert conn.status == 200

    # Receive info
    conn = conn(:get, "/visited_domains")
           |> put_req_header("content-type", "application/json")
    conn = VisitJson.Endpoint.call(conn, init_empty())

    assert conn.state == :sent
    assert conn.status == 200
  end
end
