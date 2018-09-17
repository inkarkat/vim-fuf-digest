" fuf/digest/vim.vim: Drill-down to Vim mappings and commands.
"
" DEPENDENCIES:
"   - fuf/digest.vim autoload script
"   - ingo/escape/command.vim autoload script
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	004	29-Nov-2017	Rename fuf#digest#vim#MappingAnyMode() to
"				fuf#digest#vim#MappingGenericMode(); accept and
"				pass on mode as first argument. This way, we
"				digest only the mappings of that mode, not all
"				modes.
"	003	03-Nov-2017	FIX: Also consider ! :map prefix.
"				ENH: Support a:options.isFilterPhysicalMappings.
"				Add fuf#digest#vim#MappingAnyMode().
"	002	25-Oct-2017	Add functions digesting Vim commands.
"	001	24-Oct-2017	file creation

function! s:JoinLastSetFromAndSplit( commandOutput )
    " Join the "Last set from ..." lines into the previous line, keeping just
    " the source script basename.
    return split(substitute(a:commandOutput, '\n\t[^\n]*[/\\]\([^\n/\\]*\)', '\1', 'g'), '\n')
endfunction

function! fuf#digest#vim#Mapping( mode, mapPrefix, actions, options )
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

    if l:isFilterPhysicalMappings
	call filter(l:mappings, 'v:val[0] !~# ''^\%(<Plug>\|<SNR>\)''')
    endif

    " Filter out any mapping that launches this drill-down itself. (Usually the
    " one with just a:mapPrefix as {lhs}.)
    call filter(l:mappings, 'v:val[1] !~# "\\<fuf#digest#vim#"')

    if ! empty(l:filter)
	call filter(l:mappings, l:filter)
    endif

    call fuf#digest#launch(1, a:mode . 'map>', l:mappings, a:actions, a:options)
endfunction

function! fuf#digest#vim#MappingGenericMode( mode, mapPrefix, ... )
    call fuf#digest#vim#Mapping(a:mode, a:mapPrefix, [''], (a:0 ? a:1 : {}))
endfunction

function! fuf#digest#vim#MappingNormalMode( mapPrefix, ... )
    call fuf#digest#vim#Mapping('n', a:mapPrefix, ['', function('fuf#digest#vim#ExecuteNormalMode')], (a:0 ? a:1 : {}))
endfunction
function! fuf#digest#vim#ExecuteNormalMode( lhs, rhs, menu )
    call feedkeys(a:lhs, 't')
endfunction

function! fuf#digest#vim#MappingVisualMode( mapPrefix, ... )
    call fuf#digest#vim#Mapping('v', a:mapPrefix, [function('fuf#digest#vim#ReturnToVisualMode'), function('fuf#digest#vim#ExecuteVisualMode')], (a:0 ? a:1 : {}))
endfunction
function! fuf#digest#vim#ExecuteVisualMode( lhs, rhs, menu )
    call feedkeys('gv', 'n')
    call feedkeys(ingo#escape#command#mapeval(a:lhs), 't')
endfunction
function! fuf#digest#vim#ReturnToVisualMode()
    call feedkeys('gv', 'n')
endfunction

function! fuf#digest#vim#MappingInsertMode( mapPrefix, ... )
    call fuf#digest#vim#Mapping('i', a:mapPrefix, [function('fuf#digest#vim#ReturnToInsertMode'), function('fuf#digest#vim#ExecuteInsertMode')], (a:0 ? a:1 : {}))
endfunction
function! fuf#digest#vim#ExecuteInsertMode( lhs, rhs, menu )
    call feedkeys("\<C-\>\<C-n>gi", 'n')
    call feedkeys(ingo#escape#command#mapeval(a:lhs), 't')
endfunction
function! fuf#digest#vim#ReturnToInsertMode()
    call feedkeys("\<C-\>\<C-n>gi", 'n')
endfunction



function! fuf#digest#vim#Command( isBufferOnly, commandPrefix, actions, options )
    let l:filter = get(a:options, 'filter', '')

    redir => l:commandOutput
	silent! execute 'verbose command' a:commandPrefix
    redir END
    redraw	" This is necessary because of the :redir done earlier.

    let l:commandOutput = substitute(l:commandOutput, '^\n*[^\n]\+\n', '', '')  " Throw away the header line.
    let l:commands = s:JoinLastSetFromAndSplit(l:commandOutput)

    if a:isBufferOnly
	let l:commands = filter(l:commands, 'v:val =~# ''^\%([^b] \)\?b ''')
    endif

    " Parse into [command, none, menu].
    call map(l:commands, 'split(substitute(v:val, ''^\([ !"b]\{4\}\)\(\S\+\)\s\+\%(.*\)\(.*\)$'', ''\2\1 \3'', ""), "", 1)')

    if ! empty(l:filter)
	call filter(l:commands, l:filter)
    endif

    call fuf#digest#launch(1, (a:isBufferOnly ? 'b' : '') . 'command>', l:commands, a:actions, a:options)
endfunction

function! fuf#digest#vim#GlobalCommand( commandPrefix )
    call fuf#digest#vim#Command(0, a:commandPrefix, ['', function('fuf#digest#vim#SeedCommandLineWithCommand'), function('fuf#digest#vim#DirectExecuteCommand')], {})
endfunction
function! fuf#digest#vim#BufferCommand( commandPrefix )
    call fuf#digest#vim#Command(1, a:commandPrefix, ['', function('fuf#digest#vim#SeedCommandLineWithCommand'), function('fuf#digest#vim#DirectExecuteCommand')], {})
endfunction
function! fuf#digest#vim#SeedCommandLineWithCommand( command, none, menu )
    call feedkeys("\<C-\>\<C-n>:" . a:command, 'n')
endfunction
function! fuf#digest#vim#DirectExecuteCommand( command, none, menu )
    try
	execute a:command
    catch /^Vim\%((\a\+)\)\=:/
	call ingo#msg#VimExceptionMsg()
    endtry
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
