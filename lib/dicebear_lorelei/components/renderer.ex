defmodule DicebearLorelei.Components.Renderer do
  @moduledoc false

  @doc false
  @spec render(map(), atom(), map()) :: iodata()
  def render(components, component_name, colors) do
    case Map.get(components, component_name) do
      {variant, module} -> module.svg(variant, components, colors)
      nil -> []
    end
  end
end
