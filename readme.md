# Wxh16144's Dotfiles

[![backup-cli-img]][backup-cli-ul]

<!-- URL -->
[backup-cli-img]: https://img.shields.io/badge/using-backup--cli-blue?style=flat-square
[backup-cli-ul]: https://github.com/Wxh16144/backup-cli

- [.zshrc](./backup/.zshrc)
- [alias](./backup/.oh-my-zsh/custom/custom_alias.zsh) _([shortcut_fns](./backup/.oh-my-zsh/custom/shortcut_fns.zsh))_

- [VSCode setting](./backup/Library/Application%20Support/Code/User/settings.json)
- [VSCode snippets](./backup/Library/Application%20Support/Code/User/snippets)

简体中文 | [English](./readme.en.md) | [Bilibili#BV1Jg4y1H7gA](https://bilibili.com/video/BV1Jg4y1H7gA)

## 建立自己的 dotfiles

> [备份并分享你的MacOS 配置文件-知乎](https://zhuanlan.zhihu.com/p/650104902)

### clone 或者 fork 或者 use this template

```bash
git clone --branch master --depth 1 git@github.com:Wxh16144/dotfiles.git
```

### 删除 `./backup` 目录

```bash
rm -rf ./backup
```

### 安装依赖 & 建立备份

```bash
npm install && npm run start
```

<!-- https://github.com/orgs/community/discussions/16925 -->

> [!CAUTION]
> 数据脱敏，个人建议将敏感数据单独放一个文件，我的约定是 `$ZSH_CUSTOM/private_env.zsh`，可以结合自己实际情况参考～
> 我的脱敏操作：`desensitize_env $ZSH_CUSTOM/private_env.zsh > ./backup/.oh-my-zsh/custom/private_env.desensitized.zsh`

## 直接使用方式

> [!NOTE]
> 通常来说，你不需要全部采用我的配置，这很危险！它会覆盖/污染你原有的配置，建议你阅读 [backup](./backup/) 这个目录，摘选可能适合你的配置。

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

## 更多

- [backup-cli][backup-cli-ul]
- [GitHub does dotfiles](https://dotfiles.github.io/)
