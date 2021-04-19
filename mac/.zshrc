# GIT
alias master="git checkout master && git pull origin master"
alias green="git checkout green && git pull origin green"
alias pushup="git push -u origin HEAD"
alias rebase-green="git fetch origin green && git rebase origin/green && git push -f"
alias reset-origin="git reset origin/$(git_current_branch) --hard"

# latest branches at the top
alias branch="git branch --sort=-committerdate"

alias cd..="cd .." 
alias web="cd ~/work/canva/web"
alias resource="source ~/.zshrc"