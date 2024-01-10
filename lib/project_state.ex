defmodule Folder do
  defstruct path: nil, mtime: nil, contents: nil, subfolders: []
end

defmodule ProjectState do
  def collect_folder_state(folder_path) do
    File.ls!(folder_path)
    |> Enum.reduce([], fn file_name, acc ->
      full_path = Path.join(folder_path, file_name)

      case File.stat(full_path) do
        {:ok, %File.Stat{type: :regular, mtime: mtime}} ->
          contents = File.read!(full_path)
          [%Folder{path: full_path, mtime: mtime, contents: contents} | acc]

        {:ok, %File.Stat{type: :directory, mtime: dir_mtime}} ->
          folder_state = %Folder{
            path: full_path,
            mtime: dir_mtime,
            contents: nil,
            subfolders: collect_folder_state(full_path)
          }

          [folder_state | acc]

        _ ->
          acc
      end
    end)
  end

  def save_state_to_disk(file_path, state) do
    IO.puts("attempting to save state to #{file_path}")

    case File.write(file_path, :erlang.term_to_binary(state)) do
      :ok ->
        :ok

      {:error, msg} ->
        IO.puts("failed to save state at #{msg}")
        :error
    end
  end

  def read_state_from_disk(file_path) do
    case File.read(file_path) do
      {:ok, content} -> {:ok, :erlang.binary_to_term(content)}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_latest_commit_path do
    {}
  end
end
