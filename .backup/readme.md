# 自定义应用程序

> 应用程序列表不支持的应用程序，可以在此处添加。[文档](https://github.com/Wxh16144/backup-cli?tab=readme-ov-file#%E8%87%AA%E5%AE%9A%E4%B9%89%E5%BA%94%E7%94%A8%E7%A8%8B%E5%BA%8F)

```ini
[application]
name = Git

; 要同步的目录或文件， 从 $HOME 开始拼接
[configuration_files]
.gitconfig_work

; XDG 配置文件, 从 $XDG_CONFIG_HOME 开始拼接;
; see: https://specifications.freedesktop.org/basedir-spec/latest
[xdg_configuration_files]
git/config
```
