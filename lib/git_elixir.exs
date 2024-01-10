defmodule GitElixir do
  @moduledoc """
  Documentation for `GitElixir`.
  """
  def call do
    IO.puts("Starting git_elixir")
    args = System.argv()

    case args do
      [path, command | _rest] ->
        IO.puts("path: #{path}\ncommand: #{command}")

        case command do
          "init" ->
            IO.puts("initializing project")
            {result, msg} = Commands.init()
            IO.puts("result: #{result}   msg: #{msg}")

          "diff" ->
            IO.puts("getting diff for project")
            {result, msg} = Commands.diff()

            with :ok <- result,
                 diff_msg when is_binary(msg) <- msg do
              IO.puts("the current hash is #{diff_msg}")
            else
              :ok ->
                IO.puts("no diff found")

              _ ->
                IO.puts("diff failed. #{msg}")
            end

          "commit" ->
            IO.puts("committing changes")
            Commands.commit()

          "t" ->
            IO.puts("testing")
            IO.puts(inspect([LocalIo.get_project_root(), Access.elem(1)]))

            out = ProjectState.collect_folder_state(File.cwd!())
            IO.puts(inspect(out))
        end

      [path] ->
        IO.puts(path)
        IO.puts("command not provided")

      [] ->
        IO.puts("no arguments provided")
    end
  end
end

GitElixir.call()
