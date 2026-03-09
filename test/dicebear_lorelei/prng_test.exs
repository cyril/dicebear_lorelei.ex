defmodule DicebearLorelei.PrngTest do
  use ExUnit.Case, async: true

  alias DicebearLorelei.Prng

  # ---------------------------------------------------------------------------
  # new/1 — seed hashing
  # ---------------------------------------------------------------------------

  describe "new/1" do
    test "produces deterministic state from ASCII seed" do
      assert %Prng{value: 595_565_380} = Prng.new("Felix")
      assert %Prng{value: 1_057_944_975} = Prng.new("Mia")
      assert %Prng{value: 25_701_511} = Prng.new("a")
    end

    test "produces deterministic state from multibyte UTF-8 seed" do
      assert %Prng{value: -259_899_991} = Prng.new("🎲")
    end

    test "empty seed defaults to value 1" do
      assert %Prng{value: 1} = Prng.new("")
    end

    test "long seed produces bounded 32-bit value" do
      prng = Prng.new(String.duplicate("x", 1_000))
      assert %Prng{value: 252_591_587} = prng
    end

    test "different seeds produce different states" do
      seeds = ["Felix", "Mia", "a", "🎲", "alpha", "beta"]
      values = Enum.map(seeds, fn s -> Prng.new(s).value end)
      assert length(Enum.uniq(values)) == length(seeds)
    end
  end

  # ---------------------------------------------------------------------------
  # next/1 — xorshift32 stepping
  # ---------------------------------------------------------------------------

  describe "next/1" do
    test "produces reference sequence from known seed" do
      prng = Prng.new("Felix")
      {v1, prng} = Prng.next(prng)
      {v2, prng} = Prng.next(prng)
      {v3, _prng} = Prng.next(prng)

      assert v1 == -755_590_481
      assert v2 == 902_575_550
      assert v3 == -603_870_109
    end

    test "same state always yields same output" do
      prng = Prng.new("Felix")
      {a, prng_a} = Prng.next(prng)
      {b, _} = Prng.next(prng_a)

      {a2, prng_a2} = Prng.next(prng)
      {b2, _} = Prng.next(prng_a2)

      assert a == a2
      assert b == b2
    end

    test "values stay within signed 32-bit range" do
      prng = Prng.new("range_check")

      {_, prng} =
        Enum.reduce(1..1_000, {nil, prng}, fn _, {_, p} ->
          {val, p} = Prng.next(p)
          assert val >= -2_147_483_648
          assert val <= 2_147_483_647
          {val, p}
        end)

      assert %Prng{} = prng
    end
  end

  # ---------------------------------------------------------------------------
  # integer/3 — bounded integer generation
  # ---------------------------------------------------------------------------

  describe "integer/3" do
    test "produces reference values from known seed" do
      prng = Prng.new("Felix")
      {i1, prng} = Prng.integer(prng, 0, 47)
      {i2, prng} = Prng.integer(prng, 0, 3)
      {i3, prng} = Prng.integer(prng, 1, 100)
      {i4, _prng} = Prng.integer(prng, -100, 100)

      assert i1 == 15
      assert i2 == 2
      assert i3 == 36
      assert i4 == -31
    end

    test "returns exact value when min equals max" do
      prng = Prng.new("test")
      {result, _} = Prng.integer(prng, 5, 5)
      assert result == 5
    end

    test "results stay within bounds over many iterations" do
      prng = Prng.new("bounds_check")

      Enum.reduce(1..1_000, prng, fn _, p ->
        {val, p} = Prng.integer(p, 10, 20)
        assert val >= 10
        assert val <= 20
        p
      end)
    end

    test "negative range is respected" do
      prng = Prng.new("negative")

      Enum.reduce(1..500, prng, fn _, p ->
        {val, p} = Prng.integer(p, -100, -50)
        assert val >= -100
        assert val <= -50
        p
      end)
    end
  end

  # ---------------------------------------------------------------------------
  # bool/2 — probability-based boolean
  # ---------------------------------------------------------------------------

  describe "bool/2" do
    test "likelihood 0 always returns false" do
      prng = Prng.new("Felix")
      {result, _} = Prng.bool(prng, 0)
      assert result == false
    end

    test "likelihood 100 always returns true" do
      prng = Prng.new("Felix")
      {result, _} = Prng.bool(prng, 100)
      assert result == true
    end

    test "likelihood 0 returns false for many seeds" do
      for i <- 1..100 do
        prng = Prng.new("seed_#{i}")
        {result, _} = Prng.bool(prng, 0)
        assert result == false
      end
    end

    test "likelihood 100 returns true for many seeds" do
      for i <- 1..100 do
        prng = Prng.new("seed_#{i}")
        {result, _} = Prng.bool(prng, 100)
        assert result == true
      end
    end
  end

  # ---------------------------------------------------------------------------
  # pick_tuple/2 and pick_tuple/3 — element selection
  # ---------------------------------------------------------------------------

  describe "pick_tuple/2" do
    test "picks reference element from known seed" do
      prng = Prng.new("Felix")
      {picked, _} = Prng.pick_tuple(prng, {:a, :b, :c, :d})
      assert picked == :b
    end

    test "always returns the only element from singleton tuple" do
      for i <- 1..100 do
        prng = Prng.new("seed_#{i}")
        {picked, _} = Prng.pick_tuple(prng, {:only})
        assert picked == :only
      end
    end

    test "returns nil for empty tuple" do
      prng = Prng.new("Felix")
      {picked, _} = Prng.pick_tuple(prng, {})
      assert picked == nil
    end

    test "picked element is always a member of the tuple" do
      items = {:alpha, :beta, :gamma, :delta, :epsilon}
      allowed = Tuple.to_list(items) |> MapSet.new()

      Enum.reduce(1..200, Prng.new("membership"), fn _, p ->
        {picked, p} = Prng.pick_tuple(p, items)
        assert MapSet.member?(allowed, picked)
        p
      end)
    end
  end

  describe "pick_tuple/3" do
    test "returns fallback for empty tuple" do
      prng = Prng.new("Felix")
      {picked, _} = Prng.pick_tuple(prng, {}, :fallback)
      assert picked == :fallback
    end

    test "ignores fallback when tuple is non-empty" do
      prng = Prng.new("Felix")
      {picked, _} = Prng.pick_tuple(prng, {:a, :b, :c, :d}, :fallback)
      assert picked in [:a, :b, :c, :d]
    end
  end

  # ---------------------------------------------------------------------------
  # Cross-seed determinism snapshots
  # ---------------------------------------------------------------------------

  @reference_sequences %{
    "alpha" => [-1_929_473_918, -2_093_940_395, -1_066_767_400, 792_397_648, -1_242_220_616],
    "beta" => [960_008_644, 1_258_327_236, 161_222_792, -98_009_970, 1_116_638_226],
    "gamma" => [1_410_336_369, -820_015_138, -496_089_812, 1_941_035_369, 1_527_216_583],
    "delta" => [-156_059_270, -1_842_929_868, 1_240_816_980, -1_448_762_597, -1_524_665_608],
    "epsilon" => [-1_634_492_446, 1_083_507_701, -39_967_872, 69_849_495, -42_009_126],
    "zeta" => [630_756_762, -766_373_905, -430_644_936, 872_963_105, -838_852_857],
    "eta" => [1_165_689_813, -2_059_953_163, -1_083_630_863, 450_259_370, 730_106_171],
    "theta" => [1_205_765_683, 1_946_327_647, -832_285_029, -766_145_344, 444_209_638],
    "iota" => [-2_095_113_104, 1_924_442_936, 497_500_913, 1_255_512_493, -974_688_515],
    "kappa" => [1_464_395_318, 978_222_545, 1_266_631_243, -973_633_072, -1_384_127_114]
  }

  describe "determinism snapshots" do
    for {seed, expected} <- @reference_sequences do
      test "sequence for seed #{inspect(seed)} matches reference" do
        prng = Prng.new(unquote(seed))

        {values, _} =
          Enum.map_reduce(1..5, prng, fn _, p ->
            Prng.next(p)
          end)

        assert values == unquote(expected)
      end
    end
  end
end
