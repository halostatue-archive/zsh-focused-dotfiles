" By Henrik Nyh <http://henrik.nyh.se> under the MIT license.
"
" :SaveAs works mostly like the built-in :saveas, but improves on some things.
"
" (You can actually keep typing ':saveas'; when you hit the spacebar, it will
" be transformed into a ':SaveAs '.)
"
" # BANG AFTER FILENAME
"
" ':SaveAs foo/bar.txt' without any exclamation marks works like ':saveas'.
" If the 'foo' directory doesn't exist, it will complain.
" If a 'foo/bar.txt' file already exists, it will complain.
"
" ':SaveAs foo/bar.txt!' with a trailing bang creates directories if they don't
" exist, and overwrites any existing file.
"
" The bang goes AFTER the filename so you can add it with a simple ':<up>!'.
"
" # SPLIT-BUFFER FRIENDLY
"
" I often create new files based on old files by splitting a buffer into two
" windows, then doing ':saveas new_name' in one of them. With regular
" ':saveas', both windows will then show the new file. With ':SaveAs',
" it only updates one of the windows.

command! -nargs=1 -complete=file SaveAs :call <SID>SaveAs(<f-args>)

function! s:SaveAs(filename)
  if a:filename =~ "!$"
    let l:filename = substitute(a:filename, "!$", "", "")
    let l:bang = 1
  else
    let l:filename = a:filename
    let l:bang = 0
  endif

  let l:dir = fnamemodify(l:filename, ":p:h")
  if !isdirectory(l:dir)
    if l:bang
      call mkdir(l:dir, "p")
    else
      call <SID>EchoError("The directory does not exist (use trailing ! to create).")
      return 0
    endif
  end

  if !l:bang && filereadable(l:filename)
    call <SID>EchoError("File exists (use trailing ! to override).")
    return 0
  end

  " Instead of :saveas, we do :write and :edit.
  " If you split a buffer and :saveas one of the two, both windows change.
  " If you :write and :edit, only the window you are in will change.

  " If there's any error with :write, don't :edit.
  try
    if l:bang
      " 'silent!' so we can write even if there's a swapfile.
      " http://vimdoc.sourceforge.net/htmldoc/message.html#E768
      exe "silent! write! " . l:filename
    else
      exe "write " . l:filename
    endif
  catch
    call <SID>EchoError(v:exception)
    return 0
  endtry

  exe "edit " . l:filename
endfunction

function! s:EchoError(message)
  echohl ErrorMsg
  echomsg a:message
  echohl None
endfunction


" http://vim.wikia.com/wiki/Replace_a_builtin_command_using_cabbrev

function! s:CommandCabbr(abbreviation, expansion)
  execute 'cabbr ' . a:abbreviation . ' <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "' . a:expansion . '" : "' . a:abbreviation . '"<CR>'
endfunction

command! -nargs=+ CommandCabbr call <SID>CommandCabbr(<f-args>)

" :saveas calls :SaveAs
CommandCabbr saveas SaveAs
