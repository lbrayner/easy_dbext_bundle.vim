" Save As Special

" Save any buffer

function! SaveAs()
    try
        let lazyr = &lazyredraw
        set lazyredraw
        let buf_nr = bufnr('%')
        let temp_file = tempname()
        silent exec 'write ' . fnameescape(temp_file)
        browse edit
        let elected_bufnr = bufnr('%')
        if elected_bufnr == buf_nr
            " user cancelled or some other error
            return
        endif
        let elected_name = expand('%s')
        normal! dG
        let new_buf_nr = bufnr('%')
        silent exec "read " . fnameescape(temp_file)
        1d_
        " So that we get a confirm dialog if the file exists
        if filereadable(expand('%'))
            setlocal readonly
        endif
        silent exec "confirm write " . fnameescape(elected_name)
    finally
        let &lazyredraw = lazyr
        call delete(temp_file)
    endtry
endfunction

command! -nargs=0 SaveAs call SaveAs()

function! s:LoopBuffers(predicate,command)
	let last_buffer = bufnr('$')
	let buffer_count = 0
	let n = 1
	while n <= last_buffer
        if eval(a:predicate)
            silent exe a:command . ' ' . n
            let buffer_count = buffer_count+1
        endif
		let n = n+1
	endwhile
    return buffer_count
endfunction

function! s:BufWipeNotReadableForce(wipe_pattern)
    call s:LoopBuffers('buflisted(n) && !filereadable(bufname(n)) && bufname(n) =~# '
                        \ . "'" . a:wipe_pattern . "'",'bwipe!')
endfunction

function! s:BufWipeFileTypeForce(filetype)
    call s:LoopBuffers('getbufvar(n,"&ft") == '
                        \ . '"' . a:filetype . '"','bwipe!')
endfunction

" VimEnter

augroup VimEnterAutoGroup
    au!
    au VimEnter * call s:BufWipeNotReadableForce('Result')
    au VimEnter * call s:BufWipeFileTypeForce("help")
augroup END

" Swap | File changes outside
" https://github.com/neovim/neovim/issues/2127
augroup AutoSwap
        autocmd!
        autocmd SwapExists *  call s:AS_HandleSwapfile(expand('<afile>:p'), v:swapname)
augroup END

function! s:AS_HandleSwapfile (filename, swapname)
        " if swapfile is older than file itself, just get rid of it
        if getftime(v:swapname) < getftime(a:filename)
                call delete(v:swapname)
                let v:swapchoice = 'e'
        endif
endfunction
autocmd CursorHold,BufWritePost,BufReadPost,BufLeave *
  \ if isdirectory(expand("<amatch>:h")) | let &swapfile = &modified | endif

" Copy text to the system clipboard

function! FullPath()
    if has("win32") || has("win64")
        return expand("%:p")
    endif
    return expand("%:p:~")
endfunction

function! Path()
    return expand("%")
endfunction

function! Name()
    return expand("%:t")
endfunction

" Copy Path to the Clipboard

command! -nargs=0 FullPath call util#clip(FullPath())
command! -nargs=0 Path call util#clip(Path())
command! -nargs=0 Name call util#clip(Name())

if util#has_cygwin()
    function! FullPathCygwin()
        return system(util#cygwin_dir() . '/cygpath -ua ' . shellescape(expand('%')))[:-2]
    endfunction
    command! -nargs=0 FullPathCygwin call util#clip(FullPathCygwin())
endif

" vim-eunuch

function! RenameAs()
    try
        let lazyr = &lazyredraw
        set lazyredraw
        let buf_nr = bufnr('%')
        browse edit
        let elected_name = expand('%s')
        let elected_bufnr = bufnr('%')
        if elected_bufnr == buf_nr
            " user cancelled or some other error
            return
        endif
        " So that we get a confirm dialog if the file exists
        if filereadable(expand('%'))
            setlocal readonly
        endif
        silent confirm write
        buffer #
        exec "bwipeout " . elected_bufnr
        exec "Move! " . fnameescape(elected_name)
    finally
        let &lazyredraw = lazyr
    endtry
endfunction

command! -nargs=0 RenameAs call RenameAs()
