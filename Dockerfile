# ⚡ Wxh16144 的 Zsh 体验容器
#   docker build -t wxh16144/dotfiles .
#   docker run --rm -it wxh16144/dotfiles

FROM ubuntu:24.04

ARG USERNAME=dev

# ===== 系统依赖 =====
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates zsh git curl sudo vim jq lua5.4 bsdextrautils \
    && rm -rf /var/lib/apt/lists/*

# ===== 创建用户 =====
RUN useradd -m -s /bin/zsh $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME

# ===== oh-my-zsh =====
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ===== zsh 插件 =====
# 与 backup/.zshrc 的 plugins=() 保持一致
RUN git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting \
    && git clone --depth=1 https://github.com/spaceship-prompt/spaceship-react.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/spaceship-react \
    && git clone --depth=1 https://github.com/skywind3000/z.lua \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/z.lua

# ===== spaceship 主题 =====
RUN git clone https://github.com/spaceship-prompt/spaceship-prompt.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship-prompt --depth=1 \
    && ln -s ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship-prompt/spaceship.zsh-theme \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship.zsh-theme

# ===== 复制 zsh 全家桶（oh-my-zsh custom + .zshrc 等） =====
COPY --chown=$USERNAME backup/.oh-my-zsh/custom/ .oh-my-zsh/custom/
COPY --chown=$USERNAME backup/.zshrc         .
# COPY --chown=$USERNAME backup/.zshenv        .
# COPY --chown=$USERNAME backup/.zprofile      .
# COPY --chown=$USERNAME backup/.profile        .
COPY --chown=$USERNAME backup/.spaceshiprc.zsh .

# ===== git 配置（别名与行为） =====
COPY --chown=$USERNAME backup/.gitconfig        .
COPY --chown=$USERNAME backup/.gitignore_global .
COPY --chown=$USERNAME backup/.stCommitMsg      .

# 覆盖宿主专属设置（容器内没有 gpg / code）
RUN git config --global commit.gpgsign false \
    && git config --global core.editor vim \
    && git config --global core.excludesfile "$HOME/.gitignore_global"

CMD ["/bin/zsh"]
