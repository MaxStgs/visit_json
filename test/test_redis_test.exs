defmodule VisitJsonRedisTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @tag redis_test: true
  test "Connection" do
    VisitJson.TestHelpers.clear_redis_links()
    time = :os.system_time(:second)

    {:ok, links} = VisitJson.Redix.get_links(0, time)

    assert length(links) == 0
  end

  @tag redis_test: true
  test "Insert" do
    VisitJson.TestHelpers.clear_redis_links()
    time = :os.system_time(:second)

    VisitJson.Redix.insert_domains_by_time(["ya.ru", "google.ru"], time)
    {:ok, links} = VisitJson.Redix.get_links(0, time)

    assert length(links) == 2
  end

  @tag redis_test: true
  test "Insert with unique" do
    VisitJson.TestHelpers.clear_redis_links()
    time = :os.system_time(:second)

    VisitJson.Redix.insert_domains_by_time(["ya.ru", "ya.ru", "google.ru"], time)
    {:ok, links} = VisitJson.Redix.get_links(0, time)

    assert length(links) == 2
  end

  @tag redis_test: true
  test "hard insert 1" do
    VisitJson.TestHelpers.clear_redis_links()

    VisitJson.Redix.insert_domains_by_time(["ya.ru", "google.ru"], 50)
    VisitJson.Redix.insert_domains_by_time(["funbox.ru"], 75)
    VisitJson.Redix.insert_domains_by_time(["ya.ru"], 100)
    {:ok, links} = VisitJson.Redix.get_links(55, 105)

    assert length(links) == 2
  end

  @tag redis_test: true
  test "hard insert 2" do
    VisitJson.TestHelpers.clear_redis_links()

    VisitJson.Redix.insert_domains_by_time(["ya.ru", "google.ru"], 50)
    VisitJson.Redix.insert_domains_by_time(["funbox.ru"], 75)
    VisitJson.Redix.insert_domains_by_time(["ya.ru"], 100)
    {:ok, links} = VisitJson.Redix.get_links(0, 110)

    assert length(links) == 3
  end
end