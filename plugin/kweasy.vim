" Vim global plugin for quickly and easily jumping to positions on screen
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.3
" Description:	Jump to the object you're looking at!
" Last Change:	2014-08-11
" License:	Vim License (see :help license)
" Location:	plugin/kweasy.vim
" Website:	https://github.com/dahu/kweasy
"
" See kweasy.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help kweasy

let g:kweasy_version = '0.3'

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

if !exists('g:kweasy_hints')
  let g:kweasy_hints = 'asdfg;lkjh'
endif

" Private Functions: {{{1

" a-z A-Z 0-9 punct
let s:index = map(range(97,97+25) + range(65,65+25) +range(48,48+9) +
      \ range(33,47) + range(58,64) + range(123,126),
      \ 'nr2char(v:val)')

" move g:kweasy_hints to the beginning (filtering them out of s:index)
let s:index = split(kweasy_hints, '\zs')
      \     + split(substitute(tr(join(s:index, ''),
      \                           kweasy_hints,
      \                           repeat(' ', len(kweasy_hints))),
      \                        ' ', '', 'g'),
      \             '\zs')

let s:len = len(s:index)

function! s:trim(str)
  return substitute(a:str, '\s\+$', '', '')
endfunction

function! s:with_jump_marks(lines, pattern)
  let lines = a:lines
  let pattern = a:pattern
  let counter = Series()
  let newlines = []
  let mask = "\n"
  let fill = pattern == ' ' ? "\r" : ' '
  let lnum = line('w0') - 1

  for l in lines
    let lnum += 1
    " add a single empty line to newlines for each fold group
    if foldclosed(lnum) > 0
      if foldclosed(lnum) == lnum
        call add(newlines, '')
      endif
      continue
    endif

    " mark the start of matches with the 'mask' and erasing with 'fill'
    let ms = match(l, pattern)
    while ms != -1
      " use strchars() instead of len() to account for multibyte (wide) chars
      let fill_len = len(substitute(matchstr(l, pattern), '.',
          \ '\=repeat("x", strchars(submatch(0)))', 'g')) - 1

      let l = substitute(l, pattern, mask . repeat(fill, fill_len), '')
      let ms = match(l, pattern)
    endwhile

    " clear stuff that isn't the 'mask' (or tabs to keep alignment)
    let l = substitute(l, '[^\t' . mask . ']',
          \ '\=repeat(" ", strchars(submatch(0)))', 'g')

    " replace 'mask's with jump-mark
    let ms = match(l, mask)
    while ms != -1
      let c = counter.next()
      if c >= s:len
        break
      endif
      let l = substitute(l, '\m' . mask, escape(s:index[c], '&~'), '')
      let ms = match(l, mask)
    endwhile

    " we'd only have residual mask chars if there were too many to replace
    " with jump hints; erase these unreachable extras
    let l = substitute(l, mask, ' ', 'g')

    call add(newlines, s:trim(l))
  endfor
  return newlines
endfunction

function! s:jump_marks_overlay(lines, cur_pos)
  let altbuf = bufnr('#')
  let cur_pos = a:cur_pos
  normal! 0
  let first_col = wincol()
  let ts = &l:tabstop

  hide noautocmd enew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  let &l:numberwidth = first_col - 1
  let &l:tabstop = ts
  call append(0, a:lines)
  $
  delete _
  redraw
  1

  let jump = escape(nr2char(getchar()), '^$.*~]\\')
  if jump == '' || jump == "\<esc>" || jump == "\<cr>"
    let jump_pos = cur_pos
  elseif search(jump . '\C', 'cW') == 0
    let jump_pos = cur_pos
  else
    let jump_pos = getpos('.')
    " fix offset if there are tabs before jump target
    let jump_pos[2] = virtcol('.')
  endif

  buffer #
  bwipe #
  if buflisted(altbuf)
    exe 'buffer ' . altbuf
    silent! buffer #
  endif
  return jump_pos
endfunction

function! s:show_jump_marks_for(pattern)
  let lines = s:with_jump_marks(getline('w0', 'w$'), a:pattern)
  let top_of_window = line('w0')
  let cur_pos = getpos('.')
  let jump_pos = s:jump_marks_overlay(lines, cur_pos)

  " re-centre screen to pre-overlay view
  exe "normal! " . top_of_window . 'zt'
  call setpos('.', cur_pos)

  " jump to relative line,col
  exe 'normal! H' . jump_pos[1] . '_'
  exe 'normal! '  . jump_pos[2] . '|'
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
"}}}
" Public Interface: {{{1

function! KWEasyJump(char)
  if !s:check_dependencies()
    return
  endif
  let char = '\C' . escape(nr2char(a:char), '^$.*~]\\')
  if char == "\\C\<esc>" || char == "\\C\<cr>" || char == '\C'
    return
  endif
  call histadd('input', char)
  return KWEasySearch(char)
endfunction

function! KWEasySearch(pattern)
  if !s:check_dependencies()
    return
  endif
  let pattern = a:pattern

  if pattern == "\<esc>" || pattern == "\<cr>" || pattern == ''
    return
  endif

  if g:kweasy_nolist
    let save_list = &list
    set nolist
  endif

  let save_scrolloff = &so
  set so=0

  call s:show_jump_marks_for(pattern)

  let &so = save_scrolloff

  if g:kweasy_nolist
    let &list = save_list
  endif
endfunction

function! KWEasySearchCmd()
  let g:kweasy_cmdline = getcmdline()
  return "\e:call KWEasySearch(g:kweasy_cmdline)\r"
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
