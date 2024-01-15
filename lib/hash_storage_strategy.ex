defmodule HashStorageStrategy do
  @callback load_latest_hashes() :: {:ok, map()} | {:error, String.t()}
  @callback save_hashes(map()) :: {:ok, nil} | {:error, String.t()}
end

defmodule LocalStorage do
  @behaviour HashStorageStrategy

  def load_latest_hashes do
    case determine_latest_hashes() do
      {:ok, latest_commit_file} ->
        IO.puts("latest_commit_file is: #{latest_commit_file}")
        {:ok, latest_commit_file}

      {_, msg} ->
        {:error, msg}
    end
  end

  defp determine_latest_hashes do
    commits_path = LocalIo.get_commits_path()

    commits = commits_path
    |> File.ls!()
    |> Enum.map(fn commit_file ->
      full_path = Path.join(commits_path, commit_file)
      {commit_file, File.stat!(full_path).mtime}
    end)

    if Enum.empty?(commits) do
      {:error, "no existing commit found"}
    else
      commits
      |> Enum.max_by(fn {_commit_file, mtime} -> mtime end)
      |> case do
        {latest_commit_file, _mtime} ->
          {:ok, latest_commit_file}

        _ ->
          {:error, "failed to determine latest commit"}
      end
    end
  end

  def save_hashes(diff) do
    project_root_path = LocalIo.get_project_root()
    IO.puts("project_root_path: " <> project_root_path)

    project_state = ProjectState.collect_folder_state(project_root_path)
    IO.puts(inspect(diff))
    project_state_binary = :erlang.term_to_binary(%{hash: diff, project_state: project_state})
    new_hashes_path = Path.join(LocalIo.get_commits_path(), diff)

    ProjectState.save_state_to_disk(
      new_hashes_path,
      project_state_binary
    )

    {:ok, new_hashes_path}
  end
end
