" added by C Binz
"TODO:  Implement syntax concealment - DONE
"	Check whether word under cursor is a link or not

" outer if wrapper checks to make sure function is not being redefined
if !exists("*LinkForward")
		function! LinkForward()
			let test = expand("<cWORD>")
			if (match(test,"[[") == 0)	" word starts with double brackets
				normal yi[
				let fnr = @"

				let fnr = substitute(fnr,"\[","","")	" strip leading bracket if it exists
				let fnr = substitute(fnr,"\]","","")	" strip trailing bracket if it exists
				let fn = substitute(fnr,"\|.*","","")
				echo fnr

				" check for OS, construct commands accordingly
				if has("win32") || has("win64")
					let cmd = "silent !start explorer.exe "
				elseif has("mac")
					let cmd = "silent !open "
				endif

				" different rules for different filetypes - URLs and PDFs
				if (strlen(fn) == 0)
				" do nothing
				elseif (match(fn,"http") == 0)
					let fn = substitute(fn,"#","\\\\#","")	" escape hash
					let fn = substitute(fn,"%","\\\\%","")	" escape percent
					execute cmd.fn
				elseif (match(fn,".pdf") != -1)
					execute cmd.fn
				elseif (match(fn,"#") != -1)
					" this is a file with an "anchor",
					" i.e. a mark to follow
					" split into the file name and the
					" mark
					let mn = substitute(fn,".*#","","")	" mark only
					let fn = substitute(fn,"#.*","","")	" file name only

					" execute "e ".fn
          call <SID>FindOrCreateBuffer(fn, "" , 1)
					execute "'".mn

				elseif (match(fn,":") != -1)
					" this is a file with a line number
					" split into the file name and the
					" line number
					let ln = substitute(fn,".*:","","")	" mark only
					let fn = substitute(fn,":.*","","")	" file name only

					" execute "e ".fn
          call <SID>FindOrCreateBuffer(fn, "" , 1)
					execute ln

				else " if unmatched, try editing as a text file
					" execute "e ".fn
          call <SID>FindOrCreateBuffer(fn, "" , 1)
				endif

				" clear the variables here
				unlet fn
				unlet fnr

				" and clear the unnamed register (from yi[)
				let @"=''
			endif
		endfunction
endif

" function to facilitate link creation
if !exists("*CreateLink")
	function! CreateLink(in)
		"do it with prompts
		let link = input("Enter link: ")
		if (strlen(link) != 0)
			let text = input("Enter display text: ")
			execute ":normal a[[".link."|".text."]] "
		endif

		if a:in == "1"
			startinsert
		endif
		"
		"create brackets for linking, along with a guide
		"normal a [[<file or URL>{#<mark>}|<link text>]]

		" move over one bracket, select inside
		"normal hvi[

	endfunction
endif

" Borrowed from https://github.com/vim-scripts/a.vim
" Function : FindOrCreateBuffer (PRIVATE)
" Purpose  : searches the buffer list (:ls) for the specified filename. If
"            found, checks the window list for the buffer. If the buffer is in
"            an already open window, it switches to the window. If the buffer
"            was not in a window, it switches to that buffer. If the buffer did
"            not exist, it creates it.
" Args     : filename (IN) -- the name of the file
"            doSplit (IN) -- indicates whether the window should be split
"                            ("v", "h", "n", "v!", "h!", "n!", "t", "t!")
"            findSimilar (IN) -- indicate weather existing buffers should be
"                                prefered
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
" History  : + bufname() was not working very well with the possibly strange
"            paths that can abound with the search path so updated this
"            slightly.  -- Bindu
"            + updated window switching code to make it more efficient -- Bindu
"            Allow ! to be applied to buffer/split/editing commands for more
"            vim/vi like consistency
"            + implemented fix from Matt Perry
function! <SID>FindOrCreateBuffer(fileName, doSplit, findSimilar)
  " Check to see if the buffer is already open before re-opening it.
  let FILENAME = escape(a:fileName, ' ')
  let bufNr = -1
  let lastBuffer = bufnr("$")
  let i = 1
  if (a:findSimilar)
     while i <= lastBuffer
       if <SID>EqualFilePaths(expand("#".i.":p"), a:fileName)
         let bufNr = i
         break
       endif
       let i = i + 1
     endwhile

     if (bufNr == -1)
        let bufName = bufname(a:fileName)
        let bufFilename = fnamemodify(a:fileName,":t")

        if (bufName == "")
           let bufName = bufname(bufFilename)
        endif

        if (bufName != "")
           let tail = fnamemodify(bufName, ":t")
           if (tail != bufFilename)
              let bufName = ""
           endif
        endif
        if (bufName != "")
           let bufNr = bufnr(bufName)
           let FILENAME = bufName
        endif
     endif
  endif

  let splitType = a:doSplit[0]
  let bang = a:doSplit[1]
  if (bufNr == -1)
     " Buffer did not exist....create it
     let v:errmsg=""
     if (splitType == "h")
        silent! execute ":split".bang." " . FILENAME
     elseif (splitType == "v")
        silent! execute ":vsplit".bang." " . FILENAME
     elseif (splitType == "t")
        silent! execute ":tab split".bang." " . FILENAME
     else
        silent! execute ":e".bang." " . FILENAME
     endif
     if (v:errmsg != "")
        echo v:errmsg
     endif
  else

     " Find the correct tab corresponding to the existing buffer
     let tabNr = -1
     " iterate tab pages
     for i in range(tabpagenr('$'))
        " get the list of buffers in the tab
        let tabList =  tabpagebuflist(i + 1)
        let idx = 0
        " iterate each buffer in the list
        while idx < len(tabList)
           " if it matches the buffer we are looking for...
           if (tabList[idx] == bufNr)
              " ... save the number
              let tabNr = i + 1
              break
           endif
           let idx = idx + 1
        endwhile
        if (tabNr != -1)
           break
        endif
     endfor
     " switch the the tab containing the buffer
     if (tabNr != -1)
        execute "tabn ".tabNr
     endif

     " Buffer was already open......check to see if it is in a window
     let bufWindow = bufwinnr(bufNr)
     if (bufWindow == -1)
        " Buffer was not in a window so open one
        let v:errmsg=""
        if (splitType == "h")
           silent! execute ":sbuffer".bang." " . FILENAME
        elseif (splitType == "v")
           silent! execute ":vert sbuffer " . FILENAME
        elseif (splitType == "t")
           silent! execute ":tab sbuffer " . FILENAME
        else
           silent! execute ":buffer".bang." " . FILENAME
        endif
        if (v:errmsg != "")
           echo v:errmsg
        endif
     else
        " Buffer is already in a window so switch to the window
        execute bufWindow."wincmd w"
        if (bufWindow != winnr())
           " something wierd happened...open the buffer
           let v:errmsg=""
           if (splitType == "h")
              silent! execute ":split".bang." " . FILENAME
           elseif (splitType == "v")
              silent! execute ":vsplit".bang." " . FILENAME
           elseif (splitType == "t")
              silent! execute ":tab split".bang." " . FILENAME
           else
              silent! execute ":e".bang." " . FILENAME
           endif
           if (v:errmsg != "")
              echo v:errmsg
           endif
        endif
     endif
  endif
endfunction

" Borrowed from https://github.com/vim-scripts/a.vim
" Function : EqualFilePaths (PRIVATE)
" Purpose  : Compares two paths. Do simple string comparison anywhere but on
"            Windows. On Windows take into account that file paths could differ
"            in usage of separators and the fact that case does not matter.
"            "c:\WINDOWS" is the same path as "c:/windows". has("win32unix") Vim
"            version does not count as one having Windows path rules.
" Args     : path1 (IN) -- first path
"            path2 (IN) -- second path
" Returns  : 1 if path1 is equal to path2, 0 otherwise.
" Author   : Ilya Bobir <ilya@po4ta.com>
function! <SID>EqualFilePaths(path1, path2)
  if has("win16") || has("win32") || has("win64") || has("win95")
    return substitute(a:path1, "\/", "\\", "g") ==? substitute(a:path2, "\/", "\\", "g")
  else
    return a:path1 == a:path2
  endif
endfunction
" mappings
nnoremap <c-]> :call LinkForward()<cr>
nnoremap <localleader>l :call CreateLink(0)<cr>
inoremap <localleader>l ~<esc>x:call CreateLink(1)<cr>

" commented out... just use Ctrl+o
"if !exists("*LinkBackward")
"	function! LinkBackward()
"		execute "e ".g:fromFile
"	endfunction
"endif
"nnoremap <bs> :call LinkBackward()<cr>
