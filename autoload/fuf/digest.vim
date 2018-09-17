" fuf/digest.vim: Drill-down into almost arbitrary data with FuzzyFinder.
"
" DEPENDENCIES:
"   - fuf/callbackitem.vim autoload script
"   - ingo/actions.vim autoload script
"   - ingo/compat.vim autoload script
"   - ingo/strdisplaywidth/pad.vim autoload script
"
" Copyright: (C) 2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

let s:OPEN_TYPE_CURRENT = 1
let s:OPEN_TYPE_SPLIT   = 2
let s:OPEN_TYPE_VSPLIT  = 3
let s:OPEN_TYPE_TAB     = 4

let s:listener = {}
function! s:listener.onComplete( item, method )
    let l:idx = index(s:items, a:item)
    if l:idx == -1 | throw 'ASSERT: Could not find item: ' . a:item | endif

    let l:Action = get(s:actions, a:method, '')
    if ! empty(l:Action)
	call call('ingo#actions#EvaluateWithValOrFunc', [l:Action] + s:originalItems[l:idx])
    endif
endfunction
function! s:listener.onAbort()
    let l:Action = get(s:actions, 0, '')
    if ! empty(l:Action)
	call ingo#actions#EvaluateOrFunc(l:Action)
    endif
endfunction

function! s:ToFufItem( joiner, joinMaxWidth, item )
    " key [, value [, menu [, invisible [, ...]]]]
    if type(a:item) != type([]) || len(a:item) == 1
	return a:item
    endif

    if a:joinMaxWidth == 0
	let l:searchableItem = a:item[0:1]
    else
	let l:searchableItem = [ingo#strdisplaywidth#pad#Right(a:item[0], a:joinMaxWidth)] + a:item[1:1]
    endif
    let l:word = join(l:searchableItem, a:joiner)

    return (len(a:item) > 2 ? [l:word, a:item[2]] : l:word)
endfunction
function! fuf#digest#launch( partialMatching, prompt, items, actions, options )
    let l:joiner = get(a:options, 'joiner', "\t")
    let l:joinMaxWidth = get(a:options, 'joinMaxWidth', -1)
    if l:joinMaxWidth == -1
	" DWIM: Determine maximum display width of first elements of a:items,
	" and size to fit the widest one.
	let l:joinMaxWidth = max(map(copy(a:items), 'type(v:val) == type([]) ? ingo#compat#strdisplaywidth(get(v:val, 0, "")) : 0'))
    endif

    let s:originalItems = a:items
    let s:actions = a:actions
    let s:fufItems = map(copy(a:items), 's:ToFufItem(l:joiner, l:joinMaxWidth, v:val)')
    let s:items = map(copy(s:fufItems), 'type(v:val) == type([]) ? v:val[0] : v:val')
    call fuf#callbackitem#launch('', a:partialMatching, a:prompt, s:listener, s:fufItems, 0)
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
