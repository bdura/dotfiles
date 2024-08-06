# Poetry

Poetry is a strict dependency management system, allowing fully reproducible environments.

## Installation

The recommended way to install Poetry is through Pipx:

```shell
brew install pipx
pipx ensurepath

pipx install poetry
```

## Notes

The configuration present in these dotfiles sets the `virtualenvs.in-project` option to true.
It has the effect of _always_ creating a `.venv/` at the root of the project, which has the
advantage of tying the virtual environment to the actual project.
