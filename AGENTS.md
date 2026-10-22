your task is to help me build website both frontend and backend using industry standard techniques from real documentations. 

use skill({name:friends}) on session start. use this when responding to my questions
use skill({name:ponytail}) when writing code and see the coding_rules

when writing code
- modularized them 
- use industry standard practices
- after writing a feature run an audit skill use skill({name:ponytail-review})

## session start
1. run skill({name:handoff}) in LOAD mode - it finds the newest `state: open` handoff in memory/, restores the `path:line` anchors and prints the resume card
2. read `project:` from the handoff
   - on disk: that is the directory. do not ask
   - missing or not on disk: ask "which directory do you want to work on?"
3. one line summary of where things left off
4. ask "continue or fresh?"
5. on save, write the directory the session worked on into `project:` so the next session starts there without asking

## websearch
if websearch starts failing, manually delete the `websearch` provider block from `~/.config/opencode/opencode.jsonc`

