# Wxh16144's Dotfiles

[![backup-cli-img]][backup-cli-url]

<!-- URL -->
[backup-cli-img]: https://img.shields.io/badge/using-backup--cli-blue?style=flat-square
[backup-cli-url]: https://github.com/Wxh16144/backup-cli
[vscode-setting]: ./backup/Library/Application%20Support/Code/User/settings.json
[vscode-snippets]: ./backup/Library/Application%20Support/Code/User/snippets
[zshrc]: ./backup/.zshrc
[alias]: ./backup/.oh-my-zsh/custom/custom_alias.zsh
[shortcut_fns]: ./backup/.oh-my-zsh/custom/shortcut_fns.zsh
[env_vars]: ./backup/.oh-my-zsh/custom/custom_env.zsh
[git-config]: ./backup/.gitconfig
[npm_binary_config]: ./backup/.oh-my-zsh/custom/npm_binary_config.zsh
[desensitize-script]: ./backup/.oh-my-zsh/custom/desensitize_env.zsh

- [.zshrc][zshrc]
- [alias][alias]  _([shortcut_fns][shortcut_fns]_, _[env_vars][env_vars])_
- [VSCode setting][vscode-setting], [snippets][vscode-snippets]
- [git config][git-config], [npm binary config][npm_binary_config]

[简体中文](./readme.md) | English

## Build Your Own Dotfiles

### Clone, [Fork](https://github.com/Wxh16144/dotfiles/fork) or [Use this template](https://github.com/new?template_name=dotfiles&template_owner=Wxh16144)

1. **Clone**

```bash
git clone --branch template --depth 1 git@github.com:Wxh16144/dotfiles.git
```

2. **Install dependencies and create backup**

```bash
npm install && npm run backup
```

<!-- https://github.com/orgs/community/discussions/16925 -->

> [!CAUTION]
> **Data Desensitization**: It is recommended to store sensitive data in a separate file. Assuming my path is `$ZSH_CUSTOM/private_env.zsh`, please adjust according to your actual situation.
>
> Example desensitization operation: `desensitize_env $ZSH_CUSTOM/private_env.zsh > ./backup/.oh-my-zsh/custom/private_env.desensitized.zsh`
> See also: [desensitize_env script][desensitize-script]

## Apply Configuration Directly

> [!WARNING]
> **Risk Warning**: In general, it is not recommended to apply this configuration in full directly, as it may overwrite your existing settings. It is recommended that you check the [backup](./backup/) directory and pick the configuration items that suit you.

<details>
  <summary>If you understand how it works, click to see detailed steps</summary>
  
### 1. Clone the repository

```bash
git clone git@github.com:Wxh16144/dotfiles.git && cd dotfiles
```

### 2. Install dependencies

```bash
npm install
```

### 3. Restore the configuration

> You know what you're doing, right?

```bash
npm run restore
```

</details>

## Read More

- [backup-cli][backup-cli-url]
- [GitHub does dotfiles](https://dotfiles.github.io/)