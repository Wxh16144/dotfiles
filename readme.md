# Wxh16144's Dotfiles

- [.zshrc](./backup/.zshrc)

## Usage(not recommended)

> **Warning**
> As a rule you don't need to adopt all the configurations, it's dangerous!!! He will overwrite your original configuration, it is recommended that you read the `backup` directory and pick the pieces of configuration that might work for you on demand.

### [Install `mackup` (Required)](https://github.com/lra/mackup/blob/master/INSTALL.md)

### Clone Dotfiles

```bash
git clone git@github.com:Wxh16144/dotfiles.git && cd dotfiles
```

### Create soft links

```bash
ln -s $PWD/.mackup ~/.mackup \
ln -s $PWD/.mackup.cfg ~/.mackup.cfg
```

### Apply

```bash
mackup restore
```
