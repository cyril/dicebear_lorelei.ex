defmodule DicebearLorelei.Options do
  @moduledoc false

  # Variant tuples computed once at compile time.
  # Order matches upstream @dicebear/lorelei schema.js exactly.

  @hair_variants (for n <- 48..1//-1, do: :"variant#{String.pad_leading("#{n}", 2, "0")}")
                 |> List.to_tuple()

  @head_variants {:variant04, :variant03, :variant02, :variant01}

  @eyes_variants (for n <- 24..1//-1, do: :"variant#{String.pad_leading("#{n}", 2, "0")}")
                 |> List.to_tuple()

  @eyebrows_variants (for n <- 13..1//-1, do: :"variant#{String.pad_leading("#{n}", 2, "0")}")
                     |> List.to_tuple()

  @mouth_variants {:happy01, :happy02, :happy03, :happy04, :happy05, :happy06,
                   :happy07, :happy08, :happy18, :happy09, :happy10, :happy11,
                   :happy12, :happy13, :happy14, :happy17, :happy15, :happy16,
                   :sad01, :sad02, :sad03, :sad04, :sad05, :sad06, :sad07, :sad08, :sad09}

  @nose_variants (for n <- 1..6, do: :"variant#{String.pad_leading("#{n}", 2, "0")}")
                 |> List.to_tuple()

  @glasses_variants (for n <- 1..5, do: :"variant#{String.pad_leading("#{n}", 2, "0")}")
                    |> List.to_tuple()

  @beard_variants {:variant01, :variant02}
  @earrings_variants {:variant01, :variant02, :variant03}
  @freckles_variants {:variant01}
  @hair_accessories_variants {:flowers}

  @defaults %{
    seed: "",
    flip: false,
    rotate: 0,
    scale: 100,
    radius: 0,
    size: nil,
    background_color: {},
    background_type: {"solid"},
    background_rotation: {0, 360},
    translate_x: 0,
    translate_y: 0,
    clip: true,
    beard: @beard_variants,
    beard_probability: 5,
    earrings: @earrings_variants,
    earrings_color: {"000000"},
    earrings_probability: 10,
    eyebrows: @eyebrows_variants,
    eyebrows_color: {"000000"},
    eyes: @eyes_variants,
    eyes_color: {"000000"},
    freckles: @freckles_variants,
    freckles_color: {"000000"},
    freckles_probability: 5,
    glasses: @glasses_variants,
    glasses_color: {"000000"},
    glasses_probability: 10,
    hair: @hair_variants,
    hair_accessories: @hair_accessories_variants,
    hair_accessories_color: {"000000"},
    hair_accessories_probability: 5,
    hair_color: {"000000"},
    head: @head_variants,
    mouth: @mouth_variants,
    mouth_color: {"000000"},
    nose: @nose_variants,
    nose_color: {"000000"},
    skin_color: {"ffffff"}
  }

  @spec defaults() :: map()
  def defaults, do: @defaults
end
