defmodule Hashing do
  import MerkleTree
  import File, only: [ls: 1, stat!: 1]

  defp hash_metadata(file_path) do
    # hash the given file by stats
    stats = stat!(file_path)
    data = "#{inspect(file_path)}#{inspect(stats.size)}#{inspect(stats.mtime)}"
    :crypto.hash(:sha256, data) |> Base.encode16()
  end

  defp hash_file_content(file_path) do
    {:error, "hashing of file content not implemented"}
  end

  def hash_folder(file_path) do
    IO.puts("hashing folder #{inspect(file_path)}")
    # get folders and files in dir
    {:ok, entries} = ls(file_path)
    dirs_to_process = []
    child_roots = []

    # hash folders and files in this folder
    hashed_entries =
      Enum.reduce(entries, [], fn entry, acc ->
        full_path = Path.join(file_path, entry)

        if String.contains?(
             full_path,
             Path.join(LocalIo.get_project_root(), ".git_elixir")
           ) do
          acc
        else
          case stat!(full_path) do
            %{type: :directory} ->
              # hash subfolders recursively
              folder_merkle_tree = hash_folder(full_path)
              [folder_merkle_tree.root.value | child_roots]
              #           IO.puts "received merkle_tree from folder #{full_path}"
              #           IO.puts inspect(folder_merkle_tree)
              [folder_merkle_tree.root.value | acc]

            %{type: :regular} ->
              hashed_metada = hash_metadata(full_path)
              [hashed_metada | acc]
          end
        end
      end)

    merkle_tree =
      MerkleTree.new(hashed_entries, default_data_block: "MerkleTree default_data_block")

    %{root: merkle_tree.root, child_roots: child_roots}
  end

  def hash_project(file_path) do
    # get files and directories in project root
    project_root_path = LocalIo.get_project_root()

    # compute new hash for each file/directory without hash and for those which mtime is later than last hashed time
    hashes = hash_folder(project_root_path)

    if is_binary(hashes.root.value) do
      {true, hashes.root.value}
    else
      {false, nil}
    end
  end
end

defmodule LocalIo do
  @moduledoc """
  Documentation for `GitElixir`.
  """
  def parent_git_elixir_exists(current_dir, root_dir \\ "/") do
    project_root_path = Application.get_env(:app_context, :project_root_path)

    if is_binary(project_root_path) do
      {true, project_root_path}
    end

    if current_dir == root_dir do
      {false, nil}
    else
      git_elixir_path = Path.join(current_dir, ".git_elixir")

      if File.dir?(git_elixir_path) do
        {true, current_dir}
      else
        parent_git_elixir_exists(Path.dirname(current_dir), root_dir)
      end
    end
  end

  def get_project_root do
    case parent_git_elixir_exists(File.cwd!()) do
      {true, project_root} -> project_root
      {false, _} -> :error
      {_, _} -> :error
    end
  end

  def get_commits_path do
    Path.join([get_project_root(), ".git_elixir", "commits"])
  end

  def get_env_field(field) do
    Application.get_env(:git_elixir_context, field)
  end

  def put_env_field(field, value) do
    Application.put_env(:git_elixir_context, field, value)
  end

  def get_config_file_path do
    {result, path} = parent_git_elixir_exists(File.cwd!())

    case result do
      true ->
        config_file_path = Path.join([path, ".git_elixir", "git_elixir.conf"])

        {:ok, config_file_path}

      _ ->
        {:error, "failed to get config_path"}
    end
  end

  def get_storage_strategy do
    config = read_config()

    with {:ok, storage_strategy} <- Access.fetch(config, :storage_strategy) do
      Module.concat([storage_strategy])
    else
      _ -> :error
    end
  end

  def read_config do
    File.stream!(get_in(get_config_file_path(), [Access.elem(1)]))
    |> Enum.reduce(%{}, fn line, acc ->
      [key, value] = String.split(line, "=", parts: 2)
      Map.put(acc, String.to_atom(key), String.trim(value))
    end)
  end

  def write_config(key, value) do
    config = read_config()
    updated_config = Map.put(config, key, value)

    File.write(
      @config_file,
      Enum.map_join(updated_config, "\n", fn {k, v} -> "#{k}=#{v}" end)
    )
  end
end
