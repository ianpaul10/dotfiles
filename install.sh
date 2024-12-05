 #!/bin/bash

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Create necessary directories
echo -e "${GREEN}Creating necessary directories...${NC}"
mkdir -p ~/.config/nvim

# Sync zsh files
echo -e "${GREEN}Syncing zsh files...${NC}"
ln -sf "$PWD/zsh/.zshrc" ~/.zshrc
ln -sf "$PWD/zsh/.zprofile" ~/.zprofile
ln -sf "$PWD/zsh/.zshenv" ~/.zshenv

# Sync vim files
echo -e "${GREEN}Syncing vim files...${NC}"
ln -sf "$PWD/.vimrc" ~/.vimrc


# Sync neovim files
echo -e "${GREEN}Syncing neovim configuration...${NC}"
rm -rf ~/.config/nvim
ln -sf "$PWD/neovim" ~/.config/nvim

echo -e "${GREEN}Done! Configuration files have been linked.${NC}"
