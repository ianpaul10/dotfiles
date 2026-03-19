# Global Agent Instructions

## Dotfiles & Customization Location

This machine's dotfiles live at: `/Users/ip_shopify/code/dotfiles`

**When adding any new pi-related customization — skills, extensions, scripts, tools, or commands — always place them inside `/Users/ip_shopify/code/dotfiles/pi/` and update `install.sh` if a new symlink is needed.**

The `pi/` directory structure:

```
pi/
├── AGENTS.md          ← this file (symlinked to ~/.pi/agent/AGENTS.md)
├── extensions/        ← symlinked to ~/.pi/agent/extensions/
│   └── *.ts           ← global extensions active in every pi session
└── skills/            ← symlinked to ~/.pi/agent/skills/
    └── <name>/
        └── SKILL.md   ← global skills available in every pi session
```

`install.sh` at the repo root manages all symlinks. Run it after adding new files to wire everything up.
