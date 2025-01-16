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

简体中文 | [English](./readme.en.md) | [Bilibili#BV1Jg4y1H7gA](https://bilibili.com/video/BV1Jg4y1H7gA)

## 建立属于自己的 dotfiles

> [备份并分享你的MacOS 配置文件-知乎](https://zhuanlan.zhihu.com/p/650104902)

### Clone 或者 [Fork](https://github.com/Wxh16144/dotfiles/fork) 或者 [Use this template](https://github.com/new?template_name=dotfiles&template_owner=Wxh16144)

1. **Clone**

```bash
git clone --branch template --depth 1 git@github.com:Wxh16144/dotfiles.git
```

2. **安装依赖 & 建立备份**

```bash
npm install && npm run backup
```

<!-- https://github.com/orgs/community/discussions/16925 -->

> [!CAUTION]
> 数据脱敏，个人建议将敏感数据单独放一个文件，我的约定是 `$ZSH_CUSTOM/private_env.zsh`，可以结合自己实际情况参考～
> 我的脱敏操作：`desensitize_env $ZSH_CUSTOM/private_env.zsh > ./backup/.oh-my-zsh/custom/private_env.desensitized.zsh`

## 直接使用方式

> [!NOTE]
> 通常来说，你不需要全部采用我的配置，这很危险！它会覆盖/污染你原有的配置，建议你阅读 [backup](./backup/) 这个目录，摘选可能适合你的配置。

<details>
  <summary>我知道其中的工作原理，点击查看详细步骤</summary>
  
### 1. 克隆仓库

```bash
git clone git@github.com:Wxh16144/dotfiles.git && cd dotfiles
```

### 2. 安装依赖

```bash
npm install
```

### 3. 应用

```bash
npm run restore
```
  
</details>

## 阅读更多

- [backup-cli][backup-cli-ul]
- [GitHub does dotfiles](https://dotfiles.github.io/)
