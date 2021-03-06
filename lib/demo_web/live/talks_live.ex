defmodule DemoWeb.TalksLive do
  use Phoenix.LiveView
  alias DemoWeb.Router.Helpers, as: Routes

  @talks_cache :talks_cache
  @normal_style "width: 200px"
  @error_style "width: 200px; border: 2px solid red"

  def render(assigns) do
    ~L"""
    Add talks for the meetup
    <form phx-submit="add_talk">
      <input type="text" name="talk_name" value="<%= if @talk_name, do: @talk_name %>" placeholder="talk..." style="<%= @talk_name_style %>" />
      <input type="text" name="talk_by" value="<%= if @talk_by, do: @talk_by %>" placeholder="by..." style="<%= @talk_by_style %>"/>
      <input type="submit" value="add!"/>
    </form>
    <ul>
      <%= for {talk, by} <- @talks do %>
        <li><%= talk %> (by <%= by %>)
        <input type="image" value="<%= talk <> "###" <> by %>" phx-click="remove" src="<%= Routes.static_path(DemoWeb.Endpoint, "/images/trash.png") %>" alt="Remove it!" style="width: 20px; cursor: pointer; margin: 0" /></li>
      <% end %>
    </ul>
    """
  end

  def mount(_session, socket) do
    Cachex.load(@talks_cache, "/tmp/talks_cache")

    {:ok,
     assign(socket,
       talks: Cachex.get!(@talks_cache, "talks") || [],
       talk_name: "",
       talk_by: "",
       talk_name_style: @normal_style,
       talk_by_style: @normal_style
     )}
  end

  def handle_event("add_talk", %{"talk_name" => "", "talk_by" => ""}, socket) do
    {:noreply, assign(socket, talk_name_style: @error_style, talk_by_style: @error_style)}
  end

  def handle_event("add_talk", %{"talk_name" => "", "talk_by" => talk_by}, socket) do
    {:noreply,
     assign(socket, talk_by: talk_by, talk_name_style: @error_style, talk_by_style: @normal_style)}
  end

  def handle_event("add_talk", %{"talk_name" => talk_name, "talk_by" => ""}, socket) do
    {:noreply,
     assign(socket,
       talk_name: talk_name,
       talk_name_style: @normal_style,
       talk_by_style: @error_style
     )}
  end

  def handle_event("add_talk", %{"talk_name" => talk_name, "talk_by" => talk_by}, socket) do
    talks = [{talk_name, talk_by} | socket.assigns.talks] |> Enum.reverse()
    send(self(), {:save, talks})

    {:noreply,
     assign(socket,
       talks: talks,
       talk_name: "",
       talk_by: "",
       talk_name_style: @normal_style,
       talk_by_style: @normal_style
     )}
  end

  def handle_event("remove", talk, socket) do
    [talk_name, talk_by] = String.split(talk, "###")
    talks = List.delete(socket.assigns.talks, {talk_name, talk_by})
    send(self(), {:save, talks})

    {:noreply,
     assign(socket,
       talks: talks
     )}
  end

  def handle_info({:save, talks}, socket) do
    Cachex.put(@talks_cache, "talks", talks)
    {:ok, true} = Cachex.dump(@talks_cache, "/tmp/talks_cache")
    {:noreply, socket}
  end
end
