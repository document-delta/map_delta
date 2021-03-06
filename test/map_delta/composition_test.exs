defmodule MapDelta.CompositionTest do
  use ExUnit.Case
  use EQC.ExUnit

  doctest MapDelta.Composition

  alias MapDelta.Operation
  import MapDelta.Generators

  property "(a + b) + c = a + (b + c)" do
    forall {map, delta_a, delta_b} <- {state(), delta(), delta()} do
      map_a = MapDelta.compose(map, delta_a)
      map_b = MapDelta.compose(map_a, delta_b)

      delta_c = MapDelta.compose(delta_a, delta_b)
      map_c = MapDelta.compose(map, delta_c)

      ensure map_b == map_c
    end
  end

  describe "compose add" do
    test "with add" do
      a = MapDelta.add("a", nil)
      b = MapDelta.add("a", 5)
      assert MapDelta.compose(a, b) == b
    end

    test "with remove" do
      a = MapDelta.add("a", nil)
      b = MapDelta.remove("a")
      assert MapDelta.compose(a, b) == MapDelta.new()
    end

    test "with replace" do
      a = MapDelta.add("a", nil)
      b = MapDelta.replace("a", 2)
      assert MapDelta.compose(a, b) == MapDelta.add("a", 2)
    end

    test "with change" do
      a = MapDelta.add("a", 2)
      b = MapDelta.change("a", 3)
      assert MapDelta.compose(a, b) == MapDelta.add("a", 3)
    end
  end

  describe "compose change" do
    test "with add" do
      a = MapDelta.change("a", 5)
      b = MapDelta.add("a", 3)
      assert MapDelta.compose(a, b) == MapDelta.replace("a", 3)
    end

    test "with remove" do
      a = MapDelta.change("a", 5)
      b = MapDelta.remove("a")
      assert MapDelta.compose(a, b) == b
    end

    test "with replace" do
      a = MapDelta.change("a", 3)
      b = MapDelta.replace("a", nil)
      assert MapDelta.compose(a, b) == b
    end

    test "with change" do
      a = MapDelta.change("a", 3)
      b = MapDelta.change("a", 5)
      assert MapDelta.compose(a, b) == MapDelta.change("a", 5)
    end
  end

  describe "compose remove" do
    test "with add" do
      a = MapDelta.remove("a")
      b = MapDelta.add("a", 3)
      assert MapDelta.compose(a, b) == MapDelta.replace("a", 3)
    end

    test "with remove" do
      a = MapDelta.remove("a")
      b = MapDelta.remove("a")
      assert MapDelta.compose(a, b) == b
    end

    test "with replace" do
      a = MapDelta.remove("a")
      b = MapDelta.replace("a", 5)
      assert MapDelta.compose(a, b) == b
    end

    test "with change" do
      # Technically this should never happen as
      # it is obviously a broken-state operation,
      # resulting in a change loss.
      #
      # But I'm covering it anyways, just in case.
      a = MapDelta.remove("a")
      b = MapDelta.change("a", 5)
      assert MapDelta.compose(a, b) == a
    end
  end

  describe "compose replace" do
    test "with add" do
      a = MapDelta.replace("a", 3)
      b = MapDelta.add("a", 5)
      assert MapDelta.compose(a, b) == MapDelta.replace("a", 5)
    end

    test "with remove" do
      a = MapDelta.replace("a", 3)
      b = MapDelta.remove("a")
      assert MapDelta.compose(a, b) == b
    end

    test "with replace" do
      a = MapDelta.replace("a", 3)
      b = MapDelta.replace("a", 5)
      assert MapDelta.compose(a, b) == b
    end

    test "with change" do
      a = MapDelta.replace("a", 3)
      b = MapDelta.change("a", 5)
      assert MapDelta.compose(a, b) == MapDelta.replace("a", 5)
    end
  end

  describe "compose" do
    test "operations on different keys" do
      a = MapDelta.add("a", 5)
      b = MapDelta.replace("b", 3)
      assert MapDelta.compose(a, b) == MapDelta.new([
        Operation.add("a", 5),
        Operation.replace("b", 3)])
    end

    test "nothing with add" do
      a = MapDelta.add("a", nil)
      b = MapDelta.new()
      assert MapDelta.compose(a, b) == a
    end

    test "add against nothing" do
      a = MapDelta.new()
      b = MapDelta.add("a", nil)
      assert MapDelta.compose(a, b) == b
    end

    test "recursively" do
      a = MapDelta.change("a", MapDelta.remove(".c"))
      b = MapDelta.change("a", MapDelta.add(".c", 6))
      assert MapDelta.compose(a, b) ==
        MapDelta.change("a", MapDelta.replace(".c", 6))
    end
  end
end
