# Wxh16144's Dotfiles

- [.zshrc](./backup/.zshrc)
- [alias](./backup/.oh-my-zsh/custom/custom_alias.zsh)

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

## 直接使用方式(不推荐的)

> **Warning**
> 正常来说，你不需要全部采用我的配置，这很危险！！！它会覆盖你原有的配置，建议你阅读 [backup](./backup/) 这个目录，摘选可能适合你的配置。

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
