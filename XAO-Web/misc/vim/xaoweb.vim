" Vim syntax file
" Language:     XAO::Web Templates
" Maintainer:   Andrew Maltsev <am@xao.com>
" URL:          http://xao.com/
" Last Change:  2002 Feb 8

" Quit when a syntax file was already loaded
"
if exists("b:current_syntax")
  finish
endif

" Based on HTML
"
source <sfile>:p:h/html.vim
"source /usr/share/vim/vim60z/syntax/html.vim
unlet b:current_syntax

syn case match

syn match   xaowebKeyword   "<%[A-Z][A-Za-z0-9_.]\+"
syn match   xaowebClose     "%>"
syn match   xaowebFlags     "\(<%[A-Z][A-Za-z0-9_.]\+\)\@<=/[a-z]\+"
syn match   xaowebFlags     "/[a-z]\+/" contained
syn region  xaowebFlags     matchgroup=xaowebVariable start="<%[A-Z][A-Z0-9_.]*\(\(/[a-z]\+\)\=%>\)\@=" end="%>"

"syn region  xaowebContent   start="<%" end="%>" skip=+".\{-}"\|{.\{-}}+ contains=xaowebAttr,xaowebVarAttr
syn match   xaowebAttr      "[a-z][a-z0-9_.]\+\(=['"{]\)\@="
syn match   xaowebVarAttr   "[A-Z][A-Z0-9_.]\+\(=['"{]\)\@="

hi link xaowebClose     xaowebDKeyword
hi link xaowebKeyword   xaowebDKeyword
hi link xaowebVariable  xaowebDVariable
hi link xaowebFlags     xaowebDFlags

hi xaowebDKeyword       ctermfg=DarkBlue    guifg=DarkBlue      gui=bold
hi xaowebDVariable      ctermfg=DarkGreen   guifg=DarkGreen     gui=bold
hi xaowebDFlags         ctermfg=DarkCyan    guifg=DarkCyan      gui=bold

hi xaowebVarAttr        ctermfg=DarkGreen   guifg=DarkGreen     gui=NONE
hi xaowebAttr           ctermfg=DarkBlue    guifg=DarkCyan      gui=NONE

let b:current_syntax = "xaoweb"
