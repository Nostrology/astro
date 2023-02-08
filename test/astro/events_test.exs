defmodule Astro.EventsTest do
  use Astro.DataCase, async: true

  import Astro.Events

  alias Astro.Events.Event
  alias Astro.Events.Tag

  @event %Event{
    id: "a8b2d39d300b5a3ff91fc7b943944ebfd829a63ce2c0289431237473619a6975",
    pubkey: "74fcb177b758df25487504a0bf9b69bdd7ec99ed3d422a18f932709974f80875",
    created_at: 1_675_428_746,
    kind: 1,
    tags: [],
    content: "derp",
    sig:
      "21d32b2df6fc4f92557afca56200f462d969a935203fe5726bc202a2bab26a3d673f12b7d6d45cc7e06f98f75b0835689384b87066999e6a636f27511a9cff59"
  }

  describe "Create Event" do
    test "create_event/1 creates an event" do
      assert {:ok, _} =
               create_event(%{
                 "id" => "d2472b7bcd2490f82dfc06b6fad1695898581a21312a7aa7d4a3b4e1f06d358a",
                 "pubkey" => "74fcb177b758df25487504a0bf9b69bdd7ec99ed3d422a18f932709974f80875",
                 "created_at" => 1_675_599_987,
                 "kind" => 1,
                 "tags" => [
                   [
                     "e",
                     "a8b2d39d300b5a3ff91fc7b943944ebfd829a63ce2c0289431237473619a6975"
                   ]
                 ],
                 "content" => "hello world",
                 "sig" =>
                   "74837ea05b3568b9979777cef2c3d0b3e587f113811cc7405230837aa15122e3645ecd2f162ca1e31618f1d335266c85a19cb0ec62e9b4654fabc9e9b8f5f917"
               })
    end
  end

  describe "Filter Tests" do
    Enum.each(
      [
        {%{"ids" => ["a8b2d39d300b5a3ff91fc7b94"]}, true},
        {%{"ids" => ["foobar"]}, false},
        {%{"since" => 1_675_428_747}, true}
      ],
      fn {filters, result} ->
        # escaped = Macro.escape(filters)

        @tag filters: filters, result: result
        test "match_filters/2 matches filters #{inspect(filters)} == #{result}", %{
          filters: filters,
          result: result
        } do
          assert matches_filters(@event, filters) == result
        end
      end
    )
  end

  describe "Event JSON" do
    test "generates valid json from an event struct" do
      event = %Event{
        id: "d2472b7bcd2490f82dfc06b6fad1695898581a21312a7aa7d4a3b4e1f06d358a",
        pubkey: "74fcb177b758df25487504a0bf9b69bdd7ec99ed3d422a18f932709974f80875",
        created_at: 1_675_599_987,
        kind: 1,
        content: "hello world",
        sig:
          "74837ea05b3568b9979777cef2c3d0b3e587f113811cc7405230837aa15122e3645ecd2f162ca1e31618f1d335266c85a19cb0ec62e9b4654fabc9e9b8f5f917",
        event_tags: [
          %Tag{
            event_id: "d2472b7bcd2490f82dfc06b6fad1695898581a21312a7aa7d4a3b4e1f06d358a",
            key: "e",
            value: "a8b2d39d300b5a3ff91fc7b943944ebfd829a63ce2c0289431237473619a6975",
            params: []
          }
        ]
      }

      assert Jason.encode!(event) ==
               "{\"content\":\"hello world\",\"created_at\":1675599987,\"id\":\"d2472b7bcd2490f82dfc06b6fad1695898581a21312a7aa7d4a3b4e1f06d358a\",\"kind\":1,\"pubkey\":\"74fcb177b758df25487504a0bf9b69bdd7ec99ed3d422a18f932709974f80875\",\"sig\":\"74837ea05b3568b9979777cef2c3d0b3e587f113811cc7405230837aa15122e3645ecd2f162ca1e31618f1d335266c85a19cb0ec62e9b4654fabc9e9b8f5f917\",\"tags\":[[\"e\",\"a8b2d39d300b5a3ff91fc7b943944ebfd829a63ce2c0289431237473619a6975\"]]}"
    end

    test "handles when tags have empty values" do
      event = %Event{
        content:
          "\nFree Airdrop for Damus verify users\n\n1. Join Telegram group\n2. Get your Damus verified and show proof\n3. Get free Sats\n\nJoin Group👉 https://t.me/zclub_app\n",
        created_at: 1_675_698_976,
        id: "eac9973a081c0b1c9189143bf76cb5dd3e58fb45c3470353b6f07e2ed4e137dd",
        kind: 42,
        pubkey: "4e0ebe6254074e8a0f7cfecce8ae504884ac7ee377ee2dff00b395664d162efd",
        sig:
          "99af079e9de9cfc0485d5f1439f23d3c17d55117008f85d3ed1e580740437fee2274e069cbe50c4caa613eeb0b827e9c5a62baf5d11b81566068fa8ccf01a4af",
        event_tags: [
          %Tag{
            event_id: "eac9973a081c0b1c9189143bf76cb5dd3e58fb45c3470353b6f07e2ed4e137dd",
            key: "e",
            value: "42224859763652914db53052103f0b744df79dfc4efef7e950fc0802fc3df3c5",
            params: ["", "root"]
          }
        ]
      }

      assert Jason.encode!(event) ==
               "{\"content\":\"\\nFree Airdrop for Damus verify users\\n\\n1. Join Telegram group\\n2. Get your Damus verified and show proof\\n3. Get free Sats\\n\\nJoin Group👉 https://t.me/zclub_app\\n\",\"created_at\":1675698976,\"id\":\"eac9973a081c0b1c9189143bf76cb5dd3e58fb45c3470353b6f07e2ed4e137dd\",\"kind\":42,\"pubkey\":\"4e0ebe6254074e8a0f7cfecce8ae504884ac7ee377ee2dff00b395664d162efd\",\"sig\":\"99af079e9de9cfc0485d5f1439f23d3c17d55117008f85d3ed1e580740437fee2274e069cbe50c4caa613eeb0b827e9c5a62baf5d11b81566068fa8ccf01a4af\",\"tags\":[[\"e\",\"42224859763652914db53052103f0b744df79dfc4efef7e950fc0802fc3df3c5\",\"\",\"root\"]]}"
    end
  end

  describe "Tags" do
    test "transmute_tags/1 keeps empty tags" do
      assert transmute_tags([
               [
                 "e",
                 "42224859763652914db53052103f0b744df79dfc4efef7e950fc0802fc3df3c5",
                 "",
                 "root"
               ]
             ]) ==
               [
                 %{
                   key: "e",
                   value: "42224859763652914db53052103f0b744df79dfc4efef7e950fc0802fc3df3c5",
                   params: ["", "root"]
                 }
               ]
    end
  end

  test "generate_id/1 generates the correct id" do
    event = %{
      id: "a8b2d39d300b5a3ff91fc7b943944ebfd829a63ce2c0289431237473619a6975",
      pubkey: "74fcb177b758df25487504a0bf9b69bdd7ec99ed3d422a18f932709974f80875",
      created_at: 1_675_428_746,
      kind: 1,
      tags: [],
      content: "derp",
      sig:
        "21d32b2df6fc4f92557afca56200f462d969a935203fe5726bc202a2bab26a3d673f12b7d6d45cc7e06f98f75b0835689384b87066999e6a636f27511a9cff59"
    }

    assert generate_id(event) ==
             "a8b2d39d300b5a3ff91fc7b943944ebfd829a63ce2c0289431237473619a6975"
  end

  test "generate_id/1 works for a problem child" do
    event = %{
      id: "eac9973a081c0b1c9189143bf76cb5dd3e58fb45c3470353b6f07e2ed4e137dd",
      pubkey: "4e0ebe6254074e8a0f7cfecce8ae504884ac7ee377ee2dff00b395664d162efd",
      created_at: 1_675_698_976,
      kind: 42,
      tags: [
        ["e", "42224859763652914db53052103f0b744df79dfc4efef7e950fc0802fc3df3c5", "", "root"]
      ],
      content:
        "\nFree Airdrop for Damus verify users\n\n1. Join Telegram group\n2. Get your Damus verified and show proof\n3. Get free Sats\n\nJoin Group👉 https://t.me/zclub_app\n",
      sig:
        "99af079e9de9cfc0485d5f1439f23d3c17d55117008f85d3ed1e580740437fee2274e069cbe50c4caa613eeb0b827e9c5a62baf5d11b81566068fa8ccf01a4af"
    }

    assert generate_id(event) ==
             "eac9973a081c0b1c9189143bf76cb5dd3e58fb45c3470353b6f07e2ed4e137dd"
  end

  test "verify_signature/1 verifies signatures" do
    event = %Event{
      id: "a8b2d39d300b5a3ff91fc7b943944ebfd829a63ce2c0289431237473619a6975",
      pubkey: "74fcb177b758df25487504a0bf9b69bdd7ec99ed3d422a18f932709974f80875",
      created_at: 1_675_428_746,
      kind: 1,
      tags: [],
      content: "derp",
      sig:
        "21d32b2df6fc4f92557afca56200f462d969a935203fe5726bc202a2bab26a3d673f12b7d6d45cc7e06f98f75b0835689384b87066999e6a636f27511a9cff59"
    }

    assert verify_signature(event) == true
  end

  test "filter matches prefixes and full ids" do
    # pubkey =
    #   Base.decode16!("02" <> "74fcb177b758df25487504a0bf9b69bdd7ec99ed3d422a18f932709974f80875",
    #     case: :lower
    #   )
    #   |> Curvy.Key.from_pubkey()

    # sig =
    #   "02" <>
    #     "21d32b2df6fc4f92557afca56200f462d969a935203fe5726bc202a2bab26a3d673f12b7d6d45cc7e06f98f75b0835689384b87066999e6a636f27511a9cff59"

    # id =
    #   "a8b2d39d300b5a3ff91fc7b943944ebfd829a63ce2c0289431237473619a6975"
    #   |> Base.decode16!(case: :lower)

    # Curvy.verify(sig, id, pubkey, encoding: :hex) |> dbg()

    list_events_with_filters(%{
      "ids" => [
        "05723332ff5169111c3dd58824f2d41fa87528c12d715ac3f8c5dd89b4aab927",
        "1234",
        "abcd"
      ],
      "authors" => [
        "74fcb177b758df25487504a0bf9b69bdd7ec99ed3d422a18f932709974f80875"
      ],
      "foo" => "bar",
      "since" => "SQL DROP;",
      "#e" => 123
    })

    assert_dynamic_match(
      build_and(%{ids: ["abcd"]}),
      "ilike(e.id, ^\"abcd%\")"
    )

    assert_dynamic_match(
      build_and(%{
        ids: [
          "05723332ff5169111c3dd58824f2d41fa87528c12d715ac3f8c5dd89b4aab927",
          "1234"
        ]
      }),
      "ilike(e.id, ^\"1234%\") or e.id == ^\"05723332ff5169111c3dd58824f2d41fa87528c12d715ac3f8c5dd89b4aab927\""
    )

    assert_dynamic_match(
      build_and(%{
        ids: [
          "1234",
          "abcd"
        ]
      }),
      "ilike(e.id, ^\"abcd%\") or ilike(e.id, ^\"1234%\")"
    )

    assert_dynamic_result(
      build_and(%{
        "#e": [
          "1234"
        ]
      }),
      "dynamic([tags: t], t.key == ^\"e\" and ilike(t.value, ^\"1234%\"))"
    )
  end

  # defp match(dynamic) do
  #   assert true
  #   String.replace(inspect(dynamic), "\n ", "")
  # end

  defp assert_dynamic_result(dynamic, result) do
    assert String.replace(inspect(dynamic), "\n ", "") == result
  end

  defp assert_dynamic_match(dynamic, string) do
    assert String.replace(inspect(dynamic), "\n ", "") == "dynamic([e], #{string})"
  end
end
