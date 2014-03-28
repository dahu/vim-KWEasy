" Vim global plugin for quickly and easily jumping to positions on screen
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.1
" Description:	Jump to the character you're looking at!
" Last Change:	2014-03-27
" License:	Vim License (see :help license)
" Location:	plugin/kweasy.vim
" Website:	https://github.com/dahu/kweasy
"
" See kweasy.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help kweasy

let g:kweasy_version = '0.1'

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

" Private Functions: {{{1

let s:index = map(range(48,48+9) +  range(97,97+25) + range(65,65+25) +
      \ range(33,47) + range(58,64) + range(123,126),
      \ 'nr2char(v:val)')
let s:len = len(s:index)

" Public Interface: {{{1

function! KWEasy(char)
  let char = escape(nr2char(a:char), '^$.*~][\\')
  let save_list = &list
  let save_syntax = g:syntax_on
  set nolist
  let top_of_window = line('w0')
  let lines = getline('w0', 'w$')
  call map(lines, 'substitute(v:val, "[^\\t" . char . "]", " ", "g")')
  let counter = Series()
  let newlines = []
  for l in lines
    let ms = match(l, char)
    while ms != -1
      let l = substitute(l, char, s:index[counter.next() % s:len], '')
      let ms = match(l, char, ms + 1)
    endwhile
    call add(newlines, l)
  endfor
  enew
  syntax off
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
  if save_syntax
    syntax enable
  endif
  let pos = stridx(join(newlines, ' '), jump)
  exe "normal! " . top_of_window . 'zt0'
  let curpos = getpos('.')
  call search('\%#\_.\{' . (pos+1) . '}', 'ceW')
  let &list = save_list
endfunction

" Maps: {{{1
nnoremap <Plug>KweasyJump :call KWEasy(getchar())<cr>

if !hasmapto('<Plug>KweasyJump')
  nmap <unique><silent> <leader>k <Plug>KweasyJump
endif

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
