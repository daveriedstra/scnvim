function! scnvim#util#err(msg)
  echohl ErrorMsg | echom '[scnvim] ' . a:msg | echohl None
endfunction

function! scnvim#util#scnvim_exec(msg)
  let cmd = printf('SCNvim.exec("%s")', a:msg)
  call scnvim#sclang#send_silent(cmd)
endfunction

function! scnvim#util#echo_args()
  if v:char != '('
    return
  endif

  let l_num = line('.')
  let c_col = col('.') - 1
  let line = getline(l_num)

  let method = []
  " loop until we hit a valid object or reach first column
  let match = synIDattr(synID(l_num, c_col, 1), "name")
  while match != 'scObject' && c_col >= 0
    call add(method, line[c_col])
    let c_col -= 1
    let match = synIDattr(synID(l_num, c_col, 1), "name")
  endwhile

  " add last char (will be empty if we never entered loop above)
  call add(method, line[c_col])
  let method = join(reverse(method), '')

  " since lines are zero indexed (and synID for match above is not)
  " we subtract one before we continue
  let c_col -= 1

  if match == 'scObject'
    let result = []
    " scan until next non-word char
    while line[c_col] !~ '\W' && c_col >= 0
      call add(result, line[c_col])
      let c_col -= 1
    endwhile
    let result = join(reverse(result), '')
    if !empty(result)
      let result .= method
      let cmd = printf('Help.methodArgs(\"%s\")', result)
      call scnvim#util#scnvim_exec(cmd)
    endif
  endif
endfunction

function! scnvim#util#find_sclang_executable()
  let exe = get(g:, 'scnvim_sclang_executable', '')
  if !empty(exe)
    " user defined
    return expand(exe)
  elseif !empty(exepath('sclang'))
    " in $PATH
    return exepath('sclang')
  else
    " try some known locations
    let loc = '/Applications/SuperCollider.app/Contents/MacOS/sclang'
    if executable(loc)
      return loc
    endif
    let loc = '/Applications/SuperCollider/SuperCollider.app/Contents/MacOS/sclang'
    if executable(loc)
      return loc
    endif
  endif
  throw "could not find sclang exeutable"
endfunction


function! scnvim#util#get_user_settings()
  let post_win_orientation = get(g:, 'scnvim_postwin_orientation', 'v')
  let post_win_direction = get(g:, 'scnvim_postwin_direction', 'right')
  let post_win_auto_toggle = get(g:, 'scnvim_postwin_auto_toggle', 1)

  if post_win_direction == 'right'
    let post_win_direction = 'botright'
  elseif post_win_direction == 'left'
    let post_win_direction = 'topleft'
  else
    throw "valid directions are: 'left' or 'right'"
  endif

  if post_win_orientation == 'v'
    let post_win_orientation = 'vertical'
    let default_size = &columns / 2
  elseif post_win_orientation == 'h'
    let post_win_orientation = ''
    let default_size = &lines / 3
  else
    throw "valid orientations are: 's' or 'v'"
  endif

  let post_win_size = get(g:, 'scnvim_postwin_size', default_size)

  let postwin = {
  \ 'direction': post_win_direction,
  \ 'orientation': post_win_orientation,
  \ 'size': post_win_size,
  \ 'auto_toggle': post_win_auto_toggle,
  \ }

  let sclang_executable = scnvim#util#find_sclang_executable()
  let paths = {
  \ 'sclang_executable': sclang_executable,
  \ }

  return {
  \ 'paths': paths,
  \ 'post_window': postwin,
  \ }
endfunction
