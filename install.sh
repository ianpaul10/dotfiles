 #!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Creating necessary directories...${NC}"
mkdir -p ~/.config/nvim

echo -e "${GREEN}Syncing zsh files...${NC}"
ln -sf "$PWD/zsh/.zshrc" ~/.zshrc
ln -sf "$PWD/zsh/.zprofile" ~/.zprofile
ln -sf "$PWD/zsh/.zshenv" ~/.zshenv
ln -sf "$PWD/zsh/wot_in_tarnation.zsh-theme" ~/.oh-my-zsh/custom/themes

echo -e "${GREEN}Syncing vim files...${NC}"
ln -sf "$PWD/.vimrc" ~/.vimrc

echo -e "${GREEN}Syncing neovim configuration...${NC}"
rm -rf ~/.config/nvim
ln -sf "$PWD/neovim" ~/.config/nvim
ln -sf "$PWD/.editorconfig" ~/.editorconfig

echo -e "${GREEN}Syncing wezterm configuration...${NC}"
rm -rf ~/.wezterm.lua
ln -sf "$PWD/wezterm/.wezterm.lua" ~/.wezterm.lua

echo -e "${GREEN}Syncing tmux configuration...${NC}"
rm -rf ~/.tmux.conf
ln -sf "$PWD/.tmux.conf" ~/.tmux.conf

echo -e "${GREEN}Syncing zellij configuration...${NC}"
mkdir -p ~/.config/zellij
rm -f ~/.config/zellij/config.kdl
ln -sf "$PWD/zellij/config.kdl" ~/.config/zellij/config.kdl

RIG_CONFIG_DIR=~/world/trees/root/src/areas/tools/rig/config
if [ -d "$RIG_CONFIG_DIR" ]; then
  rm -f "$RIG_CONFIG_DIR/local.kdl"
  ln -sf "$PWD/zellij/local.kdl" "$RIG_CONFIG_DIR/local.kdl"
  echo -e "  ${GREEN}Linked zellij/local.kdl → $RIG_CONFIG_DIR/local.kdl${NC}"
fi

echo -e "${GREEN}Syncing Claude configuration...${NC}"
mkdir -p ~/.claude/commands ~/.claude/hooks ~/.claude/skills
rm -rf ~/.claude/CLAUDE.md
rm -f ~/.claude/settings.json
rm -f ~/.claude/settings.local.json
ln -sf "$PWD/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$PWD/.claude/settings.json" ~/.claude/settings.json
ln -sf "$PWD/.claude/settings.local.json" ~/.claude/settings.local.json
ln -sf "$PWD/.claude/statusline.sh" ~/.claude/statusline.sh

ln -sf ~/src/github.com/shopify-playground/j/hive/skill.md ~/.claude/commands/hive.md
echo -e "  ${GREEN}Linked ~/src/github.com/shopify-playground/j/hive/skill.md${NC}"

for dir in commands hooks skills; do
    for file in "$PWD"/.claude/"$dir"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            ln -sf "$file" ~/.claude/"$dir"/"$filename"
            echo -e "  ${GREEN}Linked $dir/$filename${NC}"
        fi
    done
done

echo -e "${GREEN}Syncing ghostty configuration...${NC}"
rm -rf ~/.config/ghostty/config
ln -sf "$PWD/ghostty/config" ~/.config/ghostty/config

echo -e "${GREEN}Syncing pi skills, extensions, and agent instructions...${NC}"
mkdir -p ~/.pi/agent
rm -rf ~/.pi/agent/skills
ln -sf "$PWD/pi/skills" ~/.pi/agent/skills
echo -e "  ${GREEN}Linked pi/skills → ~/.pi/agent/skills${NC}"
rm -rf ~/.pi/agent/extensions
ln -sf "$PWD/pi/extensions" ~/.pi/agent/extensions
echo -e "  ${GREEN}Linked pi/extensions → ~/.pi/agent/extensions${NC}"
rm -f ~/.pi/agent/AGENTS.md
ln -sf "$PWD/pi/AGENTS.md" ~/.pi/agent/AGENTS.md
echo -e "  ${GREEN}Linked pi/AGENTS.md → ~/.pi/agent/AGENTS.md${NC}"

echo -e "${GREEN}Done! Configuration files have been linked.${NC}"
