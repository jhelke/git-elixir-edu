defmodule Commands do
  @moduledoc """
  Documentation for `GitElixir`.
  """
  @git_elixir_folder ".git_elixir"
  @commits_folder "commits"
  @config_file_name "git_elixir.conf"

  def init do
    {exists, dir} = LocalIo.parent_git_elixir_exists(File.cwd!(), "/")

    if exists do
      {:error, "aborted git_elixir initialization, found existing git_elixir project at #{dir}"}
    else
      # create git_elixir_folder
      case init_git_elixir() do
        {:ok, diff} -> {:ok, "git_elixir project initialized with state #{diff}"}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp init_git_elixir do
    current_dir = File.cwd!()
    git_elixir_path = Path.join(current_dir, @git_elixir_folder)
    commits_path = Path.join(git_elixir_path, @commits_folder)
    IO.puts("paths in init_git_elixir:")
    IO.puts(current_dir)
    IO.puts(git_elixir_path)
    IO.puts(commits_path)
    IO.puts(Path.join(git_elixir_path, @config_file_name))

    with :ok <- File.mkdir(git_elixir_path),
         :ok <- File.mkdir(commits_path),
         :ok <-
           File.write(
             Path.join(git_elixir_path, @config_file_name),
             "project_root=#{current_dir}\nstorage_strategy=LocalStorage"
           ) do
      LocalIo.put_env_field(:project_root_path, current_dir)
      storage_strategy = LocalIo.get_storage_strategy()
      IO.puts("getting diff")

      case Hashing.hash_project(current_dir) do
        {true, diff} when not is_nil(diff) ->
          storage_strategy.save_hashes(diff)

        {false, nil} ->
          {:ok, "no changes in project, working directory clean"}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def delete_git_elixir do
    {:error, "delete not implemented"}
  end

  def branch do
    {:error, "branch not implemented"}
  end

  def diff do
    {exists, project_root_path} = LocalIo.parent_git_elixir_exists(File.cwd!())

    case exists do
      false ->
        {:error, "not inside a git_elixir project"}

      true ->
        {found_changes, current_hash} = Hashing.hash_project(project_root_path)
        storage_strategy = LocalIo.get_storage_strategy()
        {_result, latest_hash} = storage_strategy.load_latest_hashes()

        IO.puts("current_hash: " <> inspect(current_hash))
        IO.puts("latest_hash: " <> inspect(latest_hash))

        case found_changes do
          false -> {:ok, nil}
          true -> {:ok, current_hash}
          _ -> {:error, "reached illegal path"}
        end
    end
  end

  def commit do
    {exists, project_root_path} = LocalIo.parent_git_elixir_exists(File.cwd!())

    case exists do
      false ->
        {:error, "not inside a git_elixir project"}

      true ->
        {found_changes, current_hash} = Hashing.hash_project(project_root_path)
        storage_strategy = LocalIo.get_storage_strategy()
        {_result, latest_hash} = storage_strategy.load_latest_hashes()

        IO.puts("current_hash: " <> inspect(current_hash))
        IO.puts("latest_hash: " <> inspect(latest_hash))

        if current_hash != latest_hash do
          case storage_strategy.save_hashes(current_hash) do
            {:ok, commit_path} ->
              IO.puts("saved new commit to #{commit_path}")

            {_, msg} ->
              IO.puts("ERROR during commit")
              IO.puts("ERROR: " <> inspect(msg))
          end
        end
    end
  end
end
