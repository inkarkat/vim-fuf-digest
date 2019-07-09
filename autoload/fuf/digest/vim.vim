" fuf/digest/vim.vim: Drill-down to Vim mappings and commands.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"
" Copyright: (C) 2017-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

function! s:JoinLastSetFromAndSplit( commandOutput ) abort
    " Join the "Last set from ..." lines into the previous line, keeping just
    " the source script basename.
    return split(substitute(a:commandOutput, '\n\t[^\n]*[/\\]\([^\n/\\]*\)', '\1', 'g'), '\n')
endfunction

function! fuf#digest#vim#Mapping( mode, mapPrefix, actions, options ) abort
    let l:filter = get(a:options, 'filter', '')
    let l:isFilterPhysicalMappings = get(a:options, 'isFilterPhysicalMappings', 0)

    redir => l:mapOutput
	execute printf('silent! verbose %smap %s', a:mode, a:mapPrefix)
    redir END
    redraw	" This is necessary because of the :redir done earlier.

    let l:mappings = s:JoinLastSetFromAndSplit(l:mapOutput)
    " Parse into [lhs, rhs, menu]; the latter consists of the mapping sigils +
    " mapping mode(s) + basename.
    call map(l:mappings, 'split(substitute(v:val, ''^\([ [:alpha:]!]\{1,3\} \{0,2\}\)\(\S\+\)\s\+\([*&@ ]\s\)\?\(.*\)\(.*\)$'', ''\2\4\3\1 \5'', ""), "", 1)')

    " When there is no mapping, there'll only be a single [['No mappings
    " found']] List element. As the latter assumes (at least) [lhs, rhs, ...],
    " throw out this element to that we'll start FuzzyFinder with no data, just
    " like with the Vim command variant.
    call filter(l:mappings, 'len(v:val) > 1')

    if l:isFilterPhysicalMappings
	call filter(l:mappings, 'v:val[0] !~# ''^\%(<Plug>\|<SNR>\)''')
    endif

    " Filter out any mapping that launches this drill-down itself. (Usually the
    " one with just a:mapPrefix as {lhs}.)
    call filter(l:mappings, 'v:val[1] !~# "\\<fuf#digest#vim#"')

    " Filter out lhs that match any configured ignore pattern.
    if ! empty(g:fuf_digest_vim_FilteredMappingsPatterns)
	call filter(l:mappings, '! ingo#matches#Any(v:val[0], g:fuf_digest_vim_FilteredMappingsPatterns)')
    endif

    " Apply custom filter last.
    if ! empty(l:filter)
	call filter(l:mappings, l:filter)
    endif

    call fuf#digest#launch(1, a:mode . 'map>', l:mappings, a:actions, a:options)
endfunction

function! fuf#digest#vim#MappingGenericMode( mode, mapPrefix, ... ) abort
    call fuf#digest#vim#Mapping(a:mode, a:mapPrefix, [''], (a:0 ? a:1 : {}))
endfunction

function! fuf#digest#vim#MappingNormalMode( mapPrefix, ... ) abort
    call fuf#digest#vim#Mapping('n', a:mapPrefix, ['', function('fuf#digest#vim#ExecuteNormalMode')], (a:0 ? a:1 : {}))
endfunction
function! fuf#digest#vim#ExecuteNormalMode( lhs, rhs, menu ) abort
    call feedkeys(a:lhs, 't')
endfunction

function! fuf#digest#vim#MappingVisualMode( mapPrefix, ... ) abort
    call fuf#digest#vim#Mapping('v', a:mapPrefix, [function('fuf#digest#vim#ReturnToVisualMode'), function('fuf#digest#vim#ExecuteVisualMode')], (a:0 ? a:1 : {}))
endfunction
function! fuf#digest#vim#ExecuteVisualMode( lhs, rhs, menu ) abort
    call feedkeys('gv', 'n')
    call feedkeys(ingo#escape#command#mapeval(a:lhs), 't')
endfunction
function! fuf#digest#vim#ReturnToVisualMode() abort
    call feedkeys('gv', 'n')
endfunction

function! fuf#digest#vim#MappingInsertMode( mapPrefix, ... ) abort
    call fuf#digest#vim#Mapping('i', a:mapPrefix, [function('fuf#digest#vim#ReturnToInsertMode'), function('fuf#digest#vim#ExecuteInsertMode')], (a:0 ? a:1 : {}))
endfunction
function! fuf#digest#vim#ExecuteInsertMode( lhs, rhs, menu ) abort
    call feedkeys("\<C-\>\<C-n>gi", 'n')
    call feedkeys(ingo#escape#command#mapeval(a:lhs), 't')
endfunction
function! fuf#digest#vim#ReturnToInsertMode() abort
    call feedkeys("\<C-\>\<C-n>gi", 'n')
endfunction



function! fuf#digest#vim#Command( isBufferOnly, commandPrefix, actions, options ) abort
    let l:filter = get(a:options, 'filter', '')

    redir => l:commandOutput
	silent! execute 'verbose command' a:commandPrefix
    redir END
    redraw	" This is necessary because of the :redir done earlier.

    let l:commandOutput = substitute(l:commandOutput, '^\n*[^\n]\+\n', '', '')  " Throw away the header line.
    let l:commands = s:JoinLastSetFromAndSplit(l:commandOutput)

    if a:isBufferOnly
	let l:commands = filter(l:commands, 'v:val =~# ''^[ !"|]*b[ !"|]* ''')
    endif

    " Parse into [command, none, menu].
    call map(l:commands, 'split(substitute(v:val, ''^\([ !"b|]\{4\}\)\(\S\+\)\s\+\%(.*\)\(.*\)$'', ''\2\1 \3'', ""), "", 1)')

    " Filter out command that match any configured ignore pattern.
    if ! empty(g:fuf_digest_vim_FilteredCommandsPatterns)
	call filter(l:mappings, '! ingo#matches#Any(v:val[0], g:fuf_digest_vim_FilteredCommandsPatterns)')
    endif

    " Apply custom filter last.
    if ! empty(l:filter)
	call filter(l:commands, l:filter)
    endif

    call fuf#digest#launch(1, (a:isBufferOnly ? 'b' : '') . 'command>', l:commands, a:actions, a:options)
endfunction

function! fuf#digest#vim#GlobalCommand( commandPrefix ) abort
    call fuf#digest#vim#Command(0, a:commandPrefix, ['', function('fuf#digest#vim#SeedCommandLineWithCommand'), function('fuf#digest#vim#DirectExecuteCommand')], {})
endfunction
function! fuf#digest#vim#BufferCommand( commandPrefix ) abort
    call fuf#digest#vim#Command(1, a:commandPrefix, ['', function('fuf#digest#vim#SeedCommandLineWithCommand'), function('fuf#digest#vim#DirectExecuteCommand')], {})
endfunction
function! fuf#digest#vim#SeedCommandLineWithCommand( command, none, menu ) abort
    call feedkeys("\<C-\>\<C-n>:" . a:command, 'n')
endfunction
function! fuf#digest#vim#DirectExecuteCommand( command, none, menu ) abort
    try
	execute a:command
    catch /^Vim\%((\a\+)\)\=:/
	call ingo#msg#VimExceptionMsg()
    endtry
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
