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

" Plugin Options : {{{1

if !exists('g:kweasy_nolist')
  let g:kweasy_nolist = 0
endif

" Private Functions: {{{1

let s:index = map(range(48,48+9) +  range(97,97+25) + range(65,65+25) +
      \ range(33,47) + range(58,64) + range(123,126),
      \ 'nr2char(v:val)')
let s:len = len(s:index)

function! s:with_jump_marks(lines, pattern)
  let lines = a:lines
  let pattern = a:pattern
  let counter = Series()
  let newlines = []
  let mask = "\n"
  let fill = pattern == ' ' ? "\r" : ' '

  for l in lines
    " mark the start of matches with the 'mask' and erasing with 'fill'
    let ms = match(l, pattern)
    let me = matchend(l, pattern)
    while ms != -1
      let l = substitute(l, pattern, mask . repeat(fill, (me-ms-1)), '')
      let ms = match(l, pattern, me)
      let me = matchend(l, pattern, ms)
    endwhile

    " clear anything that isn't the 'mask'
    let l = substitute(l, '[^' . mask . ']', ' ', 'g')

    " replace 'mask's with jump-mark
    let ms = match(l, mask)
    while ms != -1
      let l = substitute(l, mask, s:index[counter.next() % s:len], '')
      let ms = match(l, mask, ms + 1)
    endwhile
    call add(newlines, l)
  endfor
  return newlines
endfunction

function! s:jump_marks_overlay(lines)
  hide noautocmd enew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  call append(0, a:lines)
  $
  delete
  redraw
  1
  let jump = nr2char(getchar())
  buffer #
  bwipe #
  return jump
endfunction

function! s:show_jump_marks_for(pattern)
  let lines = s:with_jump_marks(getline('w0', 'w$'), a:pattern)
  let top_of_window = line('w0')
  let jump = s:jump_marks_overlay(lines)

  exe "normal! " . top_of_window . 'zt0'

  if jump == "\<esc>"
    normal! ``
    return
  endif

  let pos = stridx(join(lines, ' '), jump)

  if pos == -1
    normal! ``
    return
  endif

  call search('\m\%#\_.\{' . (pos+1) . '}', 'ceW')
endfunction

function! s:check_dependencies()
  " Nexus is used for the Series() number generator
  if !exists('g:nexus_version')
    echohl Warn
    echom "vim-KWEasy depends on https://github.com/dahu/Nexus"
    echohl none
    return 0
  endif
  return 1
endfunction

" Public Interface: {{{1

function! KWEasyJump(char)
  if !s:check_dependencies()
    return
  endif
  let char = escape(nr2char(a:char), '^$.*~]\\')
  call histadd('input', char)
  return KWEasySearch(char)
endfunction

function! KWEasySearch(pattern)
  if !s:check_dependencies()
    return
  endif
  let pattern = a:pattern

  if pattern == "\<esc>" || pattern == ''
    return
  endif

  if g:kweasy_nolist
    let save_list = &list
    set nolist
  endif

  call s:show_jump_marks_for(pattern)

  if g:kweasy_nolist
    let &list = save_list
  endif
endfunction

" Maps: {{{1
" nnoremap <Plug>KweasyJump :call KWEasy(getchar())<cr>
nnoremap <silent> <Plug>KweasyJump :call KWEasyJump(getchar())<cr>

if !hasmapto('<Plug>KweasyJump')
  nmap <unique><silent> <leader>k <Plug>KweasyJump
endif

nnoremap <silent> <Plug>KweasySearch :call KWEasySearch(input('/'))<cr>

if !hasmapto('<Plug>KweasySearch')
  nmap <unique><silent> <leader>s <Plug>KweasySearch
endif

nmap <silent> <plug>KweasyAgain <plug>KweasySearch<up><cr>

if !hasmapto('<Plug>KweasyAgain')
  nmap <unique><silent> <leader>n <Plug>KweasyAgain
endif

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
