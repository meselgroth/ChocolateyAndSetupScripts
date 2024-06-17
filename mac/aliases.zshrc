
. /Users/michael.e/.nix-profile/etc/profile.d/nix.sh
export NIX_PATH=nixpkgs=$HOME/.nix-defexpr/channels/nixpkgs/:$NIX_PATH

alias soco="~/work/canva/tools/soco/soco"

# Fast Frontend Apps Directory (logged out). No typescript type checking. can append -p env to proxy
alias ffa="USER_LOCALE=en-GB yarn webpack-dev-server -e src/pages/apps_directory/apps_directory.entry.ts"

# Fast Frontend Editor. No typescript type checking. can append -p env to proxy
alias ffe="USER_LOCALE=en-GB yarn webpack-dev-server -e src/pages/editor/editor.entry.ts"

# Fast Frontend Home. No typescript type checking. can append -p env to proxy
alias ffh="USER_LOCALE=en-GB yarn webpack-dev-server -e src/pages/home/home.entry.ts"

# Fast Frontend Developer portal. No typescript type checking. can append -p env to proxy
alias ffd="USER_LOCALE=en-GB yarn webpack-dev-server -e src/pages/developer_portal/developer_portal.entry.ts"



# Lints the developer portal page and finds any linting issues. Caches results so runs super quick after the first run (unless a branch change) 
alias ldp="yarn lint:deps:fix && yarn lint:ts:types src/pages/developer_portal"

# Lints the ui/apps package and finds any linting issues. Caches results so runs super quick after the first run (unless a branch change) 
alias lua="yarn lint:deps:fix && yarn lint:ts:types src/ui/apps"

# Lints the apps_directory page and finds any linting issues. Caches results so runs super quick after the first run (unless a branch change) 
alias lad="yarn lint:deps:fix && yarn lint:ts:types src/pages/apps_directory"


# Runs jest tests in watch mdoe. So a file change will retrigger the tests. Normally pretty smart at looking at git changes to determine what tests it should run. Can use "p" to specify a file, "f" to only run failed. etc. 
alias rtw="yarn test:watch"
alias rtwdp="yarn test:watch pages/developer_portal"

# used to run the story for a package i.e. story pages/developer_portal
alias story="yarn storybook:single"
alias storydp="yarn storybook:single pages/developer_portal"

alias test-features="yarn test:integration:local developer_portal chrome"

# FORMAT & LINT
# only whats been changed by git
alias format="yarn lint:format:changed:fix"
alias formatlint="yarn lint:format:changed:fix && yarn lint:deps:changed:fix && yarn lint:ts:changed:fix"
alias linttypes="yarn lint:ts:types:changed"
alias linttypesall="yarn lint:ts:types src/pages/developer_portal && yarn lint:ts:types src/ui/apps"

# All
alias formatlintall="yarn lint:format:changed:fix && yarn lint:deps:fix src/pages/developer_portal && yarn lint:deps:fix src/ui/apps && yarn lint:ts:types src/pages/developer_portal && yarn lint:ts:types src/ui/apps"


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
alias protogen="bin/regen_protos.sh -i"  #protogen-regenerate/bin/start.sh
alias protorequests="tools/protogen-regenerate/bin/start_web.sh"


alias test-backend="tools/run/bin/run test //app-server:integration-tests"
alias tbk=test-backend
alias build-backend="tools/sde/build.sh backends --rpcs && tools/sde/build.sh frontends --hot"
alias bbk=build-backend

alias build-app-backend="tools/sde/build.sh backends --include app_rpc app_worker" #you will not be able to run all rpcs after this

alias ignore-bootstrap="git update-index --assume-unchanged src/pages/developer_portal/bootstrap/bootstraps.ts"
alias include-bootstrap="git update-index --no-assume-unchanged src/pages/developer_portal/bootstrap/bootstraps.ts"

# Bazel Breaks
alias fix-bazel="bazel clean --expunge"
alias fix-commandlinetools="sudo rm -rf /Library/Developer/CommandLineTools && xcode-select --install"
alias fix-yarn="rm -rf node_modules && yarn install --force"

alias alias tf="<REPO_ROOT>/bin/tf.sh"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/michael.e/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/michael.e/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/michael.e/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/michael.e/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# bun completions
[ -s "/Users/michael.e/.bun/_bun" ] && source "/Users/michael.e/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# License Vault URL for activation of Jetbrains products at Canva
export JETBRAINS_LICENSE_SERVER=https://canva.fls.jetbrains.com/
