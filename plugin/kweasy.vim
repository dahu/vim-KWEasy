" Vim global plugin for quickly and easily jumping to positions on screen
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.2
" Description:	Jump to the object you're looking at!
" Last Change:	2014-03-27
" License:	Vim License (see :help license)
" Location:	plugin/kweasy.vim
" Website:	https://github.com/dahu/kweasy
"
" See kweasy.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help kweasy

let g:kweasy_version = '0.2'

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" load guard
" uncomment after plugin development.
" XXX The conditions are only as examples of how to use them. Change them as
" needed. XXX
"if exists("g:loaded_kweasy")
"      \ || v:version < 700
"      \ || v:version == 703 && !has('patch338')
"      \ || &compatible
"  let &cpo = s:save_cpo
"  finish
"endif
"let g:loaded_kweasy = 1

 " Test for Nexus (used for the Series() number generator)
if !exists('g:nexus_version')
  echohl Warn
  echom "vim-KWEasy depends on https://github.com/dahu/Nexus"
  echohl none
  finish
endif

" Plugin Options : {{{1

if !exists('g:kweasy_nolist')
  let g:kweasy_nolist = 0
endif

" Private Functions: {{{1

let s:index = map(range(48,48+9) +  range(97,97+25) + range(65,65+25) +
      \ range(33,47) + range(58,64) + range(123,126),
      \ 'nr2char(v:val)')
let s:len = len(s:index)

" Public Interface: {{{1

function! KWEasyJump(char)
  let char = escape(nr2char(a:char), '^$.*~]\\')
  call histadd('input', char)
  return KWEasySearch(char)
endfunction

function! FindMask(str)
  return ' '
endfunction

function! KWEasySearch(pattern)
  let pattern = a:pattern
  " let mask = ' '
  " if pattern == ' ' || pattern == "\t"
  "   let mask = '_'
  " endif
  " let save_syntax = g:syntax_on
  if g:kweasy_nolist
    let save_list = &list
    set nolist
  endif
  let top_of_window = line('w0')
  let lines = getline('w0', 'w$')
  " call map(lines, 'substitute(v:val, "\\%(\\t\\|\\%(" . pattern . "\\)\\)\\@!.", mask, "g")')
  " call map(lines, 'substitute(v:val, "\\%(" . pattern . "\\)\\@!.", mask, "g")')
  " call map(lines, 'substitute(v:val, "[^\\t ]", "x", "g")')
  let counter = Series()
  let newlines = []
  "TODO: find a better mask (scan string)
  let mask = 'ñ'
  let fill = ' '
  if pattern == ' '
    let fill = 'x'
  endif
  for l in lines
    let ms = match(l, pattern)
    let me = matchend(l, pattern)
    while ms != -1
      let l = substitute(l, pattern, mask . repeat(fill, (me-ms-1)), '')
      let ms = match(l, pattern, me)
      let me = matchend(l, pattern, ms)
    endwhile

    let l = substitute(l, '[^' . mask . ']', ' ', 'g')

    let ms = match(l, mask)
    while ms != -1
      let l = substitute(l, mask, s:index[counter.next() % s:len], '')
      let ms = match(l, mask, ms + 1)
    endwhile
    call add(newlines, l)
  endfor
  noautocmd enew
  " syntax off
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  call append(0, newlines)
  $
  delete
  redraw
  1
  let jump = nr2char(getchar())
  bwipe
  " if save_syntax
  "   syntax enable
  " endif
  let pos = stridx(join(newlines, ' '), jump)
  exe "normal! " . top_of_window . 'zt0'
  let curpos = getpos('.')
  call search('\m\%#\_.\{' . (pos+1) . '}', 'ceW')
  if g:kweasy_nolist
    let &list = save_list
  endif
endfunction

" Maps: {{{1
" nnoremap <Plug>KweasyJump :call KWEasy(getchar())<cr>
nnoremap <Plug>KweasyJump :call KWEasyJump(getchar())<cr>

if !hasmapto('<Plug>KweasyJump')
  nmap <unique><silent> <leader>k <Plug>KweasyJump
endif

nnoremap <Plug>KweasySearch :call KWEasySearch(input('/'))<cr>

if !hasmapto('<Plug>KweasySearch')
  nmap <unique><silent> <leader>s <Plug>KweasySearch
endif

nmap <plug>KweasyAgain <plug>KweasySearch<up><cr>

if !hasmapto('<Plug>KweasyAgain')
  nmap <unique><silent> <leader>n <Plug>KweasyAgain
endif

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
