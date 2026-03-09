defmodule DicebearLorelei.Prng do
  @moduledoc false

  import Bitwise

  @int32_min -2_147_483_648
  @int32_max 2_147_483_647
  @int32_range @int32_max - @int32_min
  @mask32 0xFFFFFFFF

  @enforce_keys [:value]
  defstruct [:value]

  @opaque t :: %__MODULE__{value: integer()}

  @spec new(String.t()) :: t()
  def new(seed) when is_binary(seed) do
    hash = hash_seed(seed)
    %__MODULE__{value: if(hash == 0, do: 1, else: hash)}
  end

  @spec next(t()) :: {integer(), t()}
  def next(%__MODULE__{value: value}) do
    stepped = xorshift(value)
    {stepped, %__MODULE__{value: stepped}}
  end

  @spec bool(t(), 0..100) :: {boolean(), t()}
  def bool(prng, likelihood) do
    {val, prng} = integer(prng, 1, 100)
    {val <= likelihood, prng}
  end

  # Float arithmetic mirrors the JS upstream (`Math.floor(normalized * range + min)`).
  # Replacing with integer-only `rem` would change output values and break
  # seed-for-seed compatibility with @dicebear/lorelei.
  @spec integer(t(), integer(), integer()) :: {integer(), t()}
  def integer(prng, min, max) do
    {raw, prng} = next(prng)
    normalized = (raw - @int32_min) / @int32_range
    result = floor(normalized * (max + 1 - min) + min)
    {clamp(result, min, max), prng}
  end

  @spec pick_tuple(t(), tuple(), any()) :: {any(), t()}
  def pick_tuple(prng, tuple, fallback) when tuple_size(tuple) == 0 do
    {_raw, prng} = next(prng)
    {fallback, prng}
  end

  def pick_tuple(prng, tuple, _fallback) do
    {idx, prng} = integer(prng, 0, tuple_size(tuple) - 1)
    {elem(tuple, idx), prng}
  end

  @spec pick_tuple(t(), tuple()) :: {any(), t()}
  def pick_tuple(prng, tuple) do
    pick_tuple(prng, tuple, nil)
  end

  # -- xorshift32 --------------------------------------------------------

  defp xorshift(value) do
    value = bxor(value, value <<< 13) |> to_int32()
    value = bxor(value, value >>> 17) |> to_int32()
    bxor(value, value <<< 5) |> to_int32()
  end

  defp to_int32(value) do
    unsigned = band(value, @mask32)
    if unsigned > @int32_max, do: unsigned - 0x1_0000_0000, else: unsigned
  end

  defp hash_seed(seed), do: hash_seed_loop(seed, 0)

  defp hash_seed_loop(<<char_code::utf8, rest::binary>>, hash) do
    new_hash = ((hash <<< 5) - hash + char_code) |> to_int32() |> xorshift()
    hash_seed_loop(rest, new_hash)
  end

  defp hash_seed_loop(<<>>, hash), do: hash

  defp clamp(value, min, max), do: value |> max(min) |> min(max)
end
