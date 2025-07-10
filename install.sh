 #!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Create necessary directories
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

echo -e "${GREEN}Syncing wezterm configuration...${NC}"
rm -rf ~/.wezterm.lua
ln -sf "$PWD/wezterm/.wezterm.lua" ~/.wezterm.lua

echo -e "${GREEN}Syncing tmux configuration...${NC}"
rm -rf ~/.tmux.conf
ln -sf "$PWD/.tmux.conf" ~/.tmux.conf

echo -e "${GREEN}Done! Configuration files have been linked.${NC}"
