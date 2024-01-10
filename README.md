# GitElixir

## Description
This is a simple version control system (VCS) written in Elixir.
It's API is similar to the git API to offer some familiarity. Internally it saves all files to the .git_elixir folder at the project root. This folder contains the git_elixir.conf file and the commits folder.
GitElixir is an educational private project and not intended for production usage.

## Functionality

Currently it offers the following functions:

### init
Initializes a GitElixir project in the current folder.

### diff
Computes a hash for the current GitElixir project and displays it, together with the latest committed hash.

### commit
Commits the state of the current GitElixir project to disk. If the computed hash is identical to the latest committed hash it skips the operation.

## Installation

Assure elixir is installed.
Execute the git_elixir.exs file with options
Usage: ``` mix run <~/.../git_elixir.exs> <PATH_TO_PROJECT> <COMMAND> ```



