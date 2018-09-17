FUF_DIGEST   
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

This plugin ...

### SOURCE
(Original Vim tip, Stack Overflow answer, ...)

### SEE ALSO
(Plugins offering complementary functionality, or plugins using this library.)

### RELATED WORKS
(Alternatives from other authors, other approaches, references not used here.)

USAGE
------------------------------------------------------------------------------

    :Commands [{cmd}]       Drill-down into [that start with {cmd}].
    :BufferCommands [{cmd}] Drill-down into buffer-local commands [that start with
                            {cmd}].

    :Maps, :Nmaps, :Omaps, :Vmaps, :Xmaps, :Smaps, :Imaps, :Cmaps
                            List mappings bound to physical key(s); skip <Plug> and
                            <SNR> mappings in the output.
INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at https://github.com/inkarkat/vim-fuf_digest
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim fuf_digest*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.035 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

You may want to exclude some mappings or commands by default (e.g. simple
aliases or compatibiliy mappings when some key combinations are not
available). You can define a List of regular expressions; if the left-hand
side of the mapping / the command name matches any of those, it is filtered
out:

    let g:fuf_digest_vim_FilteredCommandsPatterns = ['IgnoreMe']
    let g:fuf_digest_vim_FilteredMappingsPatterns = ['^\\xy']

plugmap
CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-fuf_digest/issues or email (address below).

HISTORY
------------------------------------------------------------------------------

##### GOAL
First published version.

##### 0.01    03-Nov-2017
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2017-2018 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat <ingo@karkat.de>
