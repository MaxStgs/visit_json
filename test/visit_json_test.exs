defmodule VisitJsonTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defp init_empty() do
    VisitJson.Endpoint.init([])
  end

  test "It works!" do
    conn = conn(:get, "/")
    conn = VisitJson.Endpoint.call(conn, init_empty())

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "It works!"
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

  test "Missed parameters(both)" do
    conn = conn(:get, "/visited_domains")
           |> put_req_header("content-type", "application/json")
    check_status(conn, false)
  end

  test "Missed parameters(to)" do
    conn = conn(:get, "/visited_domains?to=3883838")
           |> put_req_header("content-type", "application/json")
    check_status(conn, false)
  end

  test "Missed parameters(from)" do
    conn = conn(:get, "/visited_domains?from=823737")
           |> put_req_header("content-type", "application/json")
    check_status(conn, false)
  end

  test "Fine parameters" do
    conn = conn(:get, "/visited_domains?from=1545217638&to=1545221231")
           |> put_req_header("content-type", "application/json")
    check_status(conn, true)
  end

  test "From > to" do
    conn = conn(:get, "/visited_domains?from=1545221231&to=1545217638")
           |> put_req_header("content-type", "application/json")
    check_status(conn, false)
  end

  @tag missed_links: true
  test "Missed links" do
    conn = conn(:post, "/visited_links")
    check_status(conn, false)
  end

  # TODO: better way?
  defp get_test_data() do
    %{"links" => ["https://ya.ru", "https://ya.ru?q=123"]}
  end

  @tag missed_links: true
  test "Fine links" do
    # TODO: how to solve this better? Some information was pushed to DB
    conn = conn(:post, "/visited_links", get_test_data())
    check_status(conn, true)
  end

  test "Random moving 1" do
    conn = conn(:get, "/something_crazy_path/300")
    conn = VisitJson.Endpoint.call(conn, init_empty())

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "You are moved somewhere... Q|*_*|Q"
  end

  test "Random moving 2" do
    conn = conn(:get, "/path")
    conn = VisitJson.Endpoint.call(conn, init_empty())

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "You are moved somewhere... Q|*_*|Q"
  end

  @tag link_correctness: true
  test "Link correctness 1" do
    link = "http://ya.ru"
    waiting = "ya.ru"

    new_link = VisitJson.Helpers.get_domain_from_link(link)
    assert new_link == waiting
  end

  @tag link_correctness: true
  test "Link correctness 2" do
    link = "http://ya.ru?q=123"
    waiting = "ya.ru"

    new_link = VisitJson.Helpers.get_domain_from_link(link)
    assert new_link == waiting
  end

  @tag link_correctness: true
  test "Link correctness 3" do
    link = "http://ya.ru?q=123&&w=993"
    waiting = "ya.ru"

    new_link = VisitJson.Helpers.get_domain_from_link(link)
    assert new_link == waiting
  end

  @tag link_correctness: true
  test "Link correctness 4" do
    link = "https://stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor"
    waiting = "stackoverflow.com"

    new_link = VisitJson.Helpers.get_domain_from_link(link)
    assert new_link == waiting
  end

  @tag link_correctness: true
  test "Link correctness 5" do
    link = "funbox.ru"
    waiting = "funbox.ru"

    new_link = VisitJson.Helpers.get_domain_from_link(link)
    assert new_link == waiting
  end

  @tag link_correctness: true
  test "Link correctness 6" do
    link = "https://ru.stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor"
    waiting = "stackoverflow.com"

    new_link = VisitJson.Helpers.get_domain_from_link(link)
    assert new_link == waiting
  end

  test "get_domains_from_list" do
    input = ["https://ya.ru/q=123", "www.sub.hello.com/sub/sub/3"]
    waiting = ["ya.ru", "hello.com"]

    result = VisitJson.Helpers.get_domains_from_links(input)

    assert result == waiting
  end

  @tag main_test: true
  test "Main test 1" do
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
