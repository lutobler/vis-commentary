--
-- vis-commentary
--

local vis = _G.vis

local comment_string = {
    actionscript='//', ada='--', ansi_c='/*|*/', antlr='//', apdl='!', apl='#',
    applescript='--', asp='\'', autoit=';', awk='#', b_lang='//', bash='#',
    batch=':', bibtex='%', boo='#', chuck='//', cmake='#', coffeescript='#',
    context='%', cpp='//', crystal='#', csharp='//', css='/*|*/', cuda='//',
    dart='//', desktop='#', django='{#|#}', dmd='//', dockerfile='#', dot='//',
    eiffel='--', elixir='#', erlang='%', faust='//', fennel=';;', fish='#',
    forth='|\\', fortran='!', fsharp='//', gap='#', gettext='#', gherkin='#',
    glsl='//', gnuplot='#', go='//', groovy='//', gtkrc='#', haskell='--',
    html='<!--|-->', icon='#', idl='//', inform='!', ini='#', Io='#',
    java='//', javascript='//', json='/*|*/', jsp='//', latex='%', ledger='#',
    less='//', lilypond='%', lisp=';', logtalk='%', lua='--', makefile='#',
    markdown='<!--|-->', matlab='#', moonscript='--', myrddin='//',
    nemerle='//', nsis='#', objective_c='//', pascal='//', perl='#', php='//',
    pico8='//', pike='//', pkgbuild='#', prolog='%', props='#', protobuf='//',
    ps='%', pure='//', python='#', rails='#', rc='#', rebol=';', rest='.. ',
    rexx='--', rhtml='<!--|-->', rstats='#', ruby='#', rust='//', sass='//',
    scala='//', scheme=';', smalltalk='"|"', sml='(*)', snobol4='#', sql='#',
    tcl='#', tex='%', text='', toml='#', vala='//', vb='\'', vbscript='\'',
    verilog='//', vhdl='--', wsf='<!--|-->', xml='<!--|-->', yaml='#', zig='//',
    nim='#', julia='#', rpmspec='#', caml='(*|*)'
}

-- escape all magic characters with a '%'
local function esc(str)
    if not str then return "" end
    return (str:gsub('[[.+*?$^()%%%]-]', '%%%0'))
end

-- escape '%'
local function pesc(str)
    if not str then return "" end
    return str:gsub('%%', '%%%%')
end

local Gsub = string.gsub

local function comment_line(lines, lnum, prefix, suffix)
    if suffix ~= "" then suffix = " " .. suffix end
    lines[lnum] = Gsub(lines[lnum],
                              "(%s*)(.*)",
                              "%1" .. pesc(prefix) .. " %2")
                  .. suffix
end

local function uncomment_line(lines, lnum, prefix, suffix)
    local patt = "^(%s*)" .. esc(prefix) .. "%s?(.*)" .. esc(suffix) .. "$"
    lines[lnum] = Gsub(lines[lnum], patt, "%1%2")
end

local function is_comment(line, prefix)
    return (line:match("^%s*(.+)"):sub(0, #prefix) == prefix)
end

local function toggle_line_comment(lines, lnum, prefix, suffix)
    if not lines or not lines[lnum] then return end
    if not lines[lnum]:match("^%s*(.+)") then return end -- ignore empty lines
    if is_comment(lines[lnum], prefix) then
        uncomment_line(lines, lnum, prefix, suffix)
    else
        comment_line(lines, lnum, prefix, suffix)
    end
end

-- if one line inside the block is not a comment, comment the block.
-- only uncomment, if every single line is comment.
local function block_comment(lines, a, b, prefix, suffix)
    local uncomment = true
    for i=a,b do
        if lines[i]:match("^%s*(.+)") and not is_comment(lines[i], prefix) then
            uncomment = false
        end
    end

    if uncomment then
        for i=a,b do
            if lines[i]:match("^%s*(.+)") then
                uncomment_line(lines, i, prefix, suffix)
            end
        end
    else
        for i=a,b do
            if lines[i]:match("^%s*(.+)") then
                comment_line(lines, i, prefix, suffix)
            end
        end
    end
end

vis:operator_new("gc", function(file, range, pos)
    local comment = comment_string[vis.win.syntax]
    local prefix, suffix = comment:match('^([^|]+)|?([^|]*)$')
    if not prefix then return end

    local c = 0
    local i = 1
    local a = -1
    local b = -1
    for line in file:lines_iterator() do
        local line_start = c
        local line_finish = c + #line + 1
        if line_start < range.finish and line_finish > range.start then
            if a == -1 then
                a = i
                b = i
            else
                b = i
            end
        end
        c = line_finish
        if c > range.finish then break end
        i = i + 1
    end
    block_comment(file.lines, a, b, prefix, suffix)

    return range.start
end, "Toggle comment on selected lines")

vis:map(vis.modes.NORMAL, "gcc", function()
    local win = vis.win
    local lines = win.file.lines
    local comment = comment_string[win.syntax]
    if not comment then return end
    local prefix, suffix = comment:match('^([^|]+)|?([^|]*)$')
    if not prefix then return end

    for sel in win:selections_iterator() do
        local lnum = sel.line
        local col = sel.col

        toggle_line_comment(lines, lnum, prefix, suffix)
        sel:to(lnum, col)  -- restore cursor position
    end

    win:draw()
end, "Toggle comment on a the current line")

