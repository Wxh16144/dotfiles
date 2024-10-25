# Wxh16144's Dotfiles

[![backup-cli-img]][backup-cli-ul]

<!-- URL -->
[backup-cli-img]: https://img.shields.io/badge/using-backup--cli-blue?style=flat-square
[backup-cli-ul]: https://github.com/Wxh16144/backup-cli
[vscode-setting]: ./backup/Library/Application%20Support/Code/User/settings.json
[vscode-snippets]: ./backup/Library/Application%20Support/Code/User/snippets
[zshrc]: ./backup/.zshrc
[alias]: ./backup/.oh-my-zsh/custom/custom_alias.zsh
[shortcut_fns]: ./backup/.oh-my-zsh/custom/shortcut_fns.zsh
[env_vars]: ./backup/.oh-my-zsh/custom/custom_env.zsh
[git-config]: ./backup/.gitconfig
[npm_binary_config]: ./backup/.oh-my-zsh/custom/npm_binary_config.zsh

- [.zshrc][zshrc]
- [alias][alias]  _([shortcut_fns][shortcut_fns]_, _[env_vars][env_vars])_
- [VSCode setting][vscode-setting], [snippets][vscode-snippets]
- [git config][git-config], [npm binary config][npm_binary_config]

[简体中文](./readme.md) | English

## Usage(not recommended)

> [!WARNING]
> As a rule you don't need to adopt all the configurations, it's dangerous!!! He will overwrite your original configuration, it is recommended that you read the [backup](./backup/) directory and pick the pieces of configuration that might work for you on demand.

### 1. Clone Dotfiles

```bash
git clone git@github.com:Wxh16144/dotfiles.git && cd dotfiles
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Apply

```bash
npm run restore
```

## Read More

- [backup-cli][backup-cli-ul]
- [GitHub does dotfiles](https://dotfiles.github.io/)