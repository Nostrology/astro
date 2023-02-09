defmodule AstroWeb.HomeLive do
  use AstroWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center h-screen">
      <a href="https://github.com/Nostrology/astro">https://github.com/Nostrology/astro</a>
    </div>
    """
  end
end
