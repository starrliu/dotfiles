# VS Code 扩展
code --install-extension github.copilot-chat
code --install-extension joouis.agent-maestro
code --install-extension Anthropic.claude-code
 
# 安装 nvm
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
 
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
 
# 安装 Node.js LTS
nvm install --lts
nvm alias default lts/*
 
# 版本检查
node -v
npm -v
npx -v
 
# 安装并更新 Claude Code
npm install -g @anthropic-ai/claude-code
claude update
claude --version
