# ⚡ Wxh16144 的 Zsh 体验容器
#   docker build -t wxh16144/dotfiles .
#   docker run --rm -it wxh16144/dotfiles

FROM ubuntu:24.04

ARG USERNAME=dev

# ===== 系统依赖 =====
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates zsh git curl sudo vim \
    && rm -rf /var/lib/apt/lists/*

# ===== 创建用户 =====
RUN useradd -m -s /bin/zsh $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME

# ===== oh-my-zsh =====
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ===== zsh 插件 =====
RUN git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions --depth=1 \
    && git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting --depth=1

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

CMD ["/bin/zsh"]
