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
[registry_proxy]: ./backup/.oh-my-zsh/custom/registry_proxy.zsh
[desensitize-script]: ./backup/.oh-my-zsh/custom/desensitize_env.zsh

- [.zshrc][zshrc]
- [alias][alias]  _([shortcut_fns][shortcut_fns]_, _[env_vars][env_vars])_
- [VSCode setting][vscode-setting], [snippets][vscode-snippets]
- [git config][git-config], [registry proxy][registry_proxy]

简体中文 | [English](./readme.en.md) | [Bilibili#BV1Jg4y1H7gA](https://bilibili.com/video/BV1Jg4y1H7gA)

## 构建专属于您的 Dotfiles

> [备份并分享你的 MacOS 配置文件 - 知乎](https://zhuanlan.zhihu.com/p/650104902)

### Clone、[Fork](https://github.com/Wxh16144/dotfiles/fork) 或 [Use this template](https://github.com/new?template_name=dotfiles&template_owner=Wxh16144)

1. **Clone**

```bash
git clone --branch template --depth 1 git@github.com:Wxh16144/dotfiles.git
```

1. **Install dependencies and create backup**

```bash
npm install && npm run backup
```

<!-- https://github.com/orgs/community/discussions/16925 -->

> [!CAUTION]
> **数据脱敏**：建议将敏感数据隔离存储于独立文件中。假设我的路径为 `$ZSH_CUSTOM/private_env.zsh`，请根据您的实际情况进行调整。
>
> 示例脱敏操作：`desensitize_env $ZSH_CUSTOM/private_env.zsh > ./backup/.oh-my-zsh/custom/private_env.desensitized.zsh`
> 详见：[desensitize_env 脱敏脚本][desensitize-script]

## Apply the configuration directly

> [!WARNING]
> **风险提示**：通常情况下，不建议直接全量应用本配置，因为这可能会覆盖您现有的设置。建议您查阅 [backup](./backup/) 目录，挑选适合您的配置项。

<details>
  <summary>若您了解其工作原理，请点击查看详细步骤</summary>
  
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

## Read more

- [backup-cli][backup-cli-url]
- [GitHub does dotfiles](https://dotfiles.github.io/)
