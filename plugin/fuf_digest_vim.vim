" fuf_digest_vim.vim: Drill-down to Vim mappings and commands.
"
" DEPENDENCIES:
"   - fuf/digest/vim.vim autoload script
"
" Copyright: (C) 2017-2018 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_fuf_digest_vim') || (v:version < 700)
    finish
endif
let g:loaded_fuf_digest_vim = 1
let s:save_cpo = &cpo
set cpo&vim

"- configuration ---------------------------------------------------------------

if ! exists('g:fuf_digest_vim_FilteredCommandsPatterns')
    let g:fuf_digest_vim_FilteredCommandsPatterns = []
endif
if ! exists('g:fuf_digest_vim_FilteredMappingsPatterns')
    let g:fuf_digest_vim_FilteredMappingsPatterns = []
endif


"- commands --------------------------------------------------------------------

command! -bar -nargs=?       Commands call fuf#digest#vim#GlobalCommand(<q-args>)
command! -bar -nargs=? BufferCommands call fuf#digest#vim#BufferCommand(<q-args>)


for s:mode in split(' novxsic', '\zs')
    execute printf('command! -nargs=* -complete=mapping %s call fuf#digest#vim#Mapping%s<q-args>, {"isFilterPhysicalMappings": 1})',
    \   substitute(s:mode . 'maps', '\a', '\u&', ''),
    \   get({
    \       'n': 'NormalMode(',
    \       'v': 'VisualMode(',
    \       'i': 'InsertMode(',
    \       }, s:mode, 'GenericMode(' . string(s:mode) . ', '
    \   )
    \)
endfor
unlet s:mode

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
