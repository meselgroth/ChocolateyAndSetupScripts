#VS Code extenstions: Visual Studio Keymap, ESLint, React Pure To Class, Reactjs code snippets (weird abbr. google results showed another one to try)

npm install -g eslint #might be mac only

npm install jasmine-node -g

#new node proj, modules requires 12.7+
npm init
npm install jasmine
npm i esm
node node_modules/jasmine/bin/jasmine init
#package.json "type": "module",
#package.json "scripts": { "test": "node -r esm node_modules/jasmine/bin/jasmine" }

eslint --init
#eslintrc.json "env": { ..., "jasmine" : true }
