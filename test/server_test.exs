Code.require_file "test_helper.exs", __DIR__
Code.require_file "../lib/server.exs", __DIR__

defmodule ServerTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup_all do
    on_exit fn ->
      {_status, files} = File.ls Path.expand("fixtures", __DIR__)
      files |> Enum.each fn(file) ->
        unless file == ".gitkeep" do
          File.rm Path.expand("fixtures/#{file}", __DIR__)
        end
      end
    end
  end

  test "Expression completion" do
    assert send_signal("COMP { 'def', [context: Elixir, imports: [], aliases: []]}") =~ """
    defoverridable/1
    """
  end

  test "Documentation lookup" do
    assert send_signal("DOCL { 'List', [context: Elixir, imports: [], aliases: []]}") =~ """
    Implements functions that only make sense for lists and cannot be part of the
    """
  end

  test "Getting the definition source file information of code" do
    assert send_signal("DEFL {\"List,delete\", [context: Elixir, imports: [], aliases: []]}") =~ "/lib/elixir/lib/list.ex"
  end

  test "Evaluate the content of a file" do
    filename = Path.expand("fixtures/eval_fixture.exs", __DIR__)
    File.write(filename, "1+1")
    assert send_signal("EVAL #{filename}") =~ "2"
  end

  test "Evaluate and quote the content of a file" do
    filename = Path.expand("fixtures/eval_and_quote_fixture.exs", __DIR__)
    File.write(filename, "[4,2,1,3] |> Enum.sort")
    assert send_signal("QUOTE #{filename}") =~ """
    {{:., [line: 1], [{:__aliases__, [counter: 0, line: 1], [:Enum]}, :sort]},\n   [line: 1], []}]}
    """
  end

  test "Get all mix tasks by name" do
    assert send_signal("MIXTASKS") =~ """
    app.start
    archive
    archive.build
    archive.install
    archive.uninstall
    clean
    cmd
    compile
    """
  end

  defp send_signal(signal) do
    capture_io(fn ->
      Alchemist.Server.read_input(signal)
    end)
  end
end
