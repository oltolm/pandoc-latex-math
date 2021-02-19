local system = require("pandoc.system")

function appendDepthToSVGFile(depth, svgPath)
    local f = io.open(svgPath, "a")
    if f == nil then
        return nil
    else
        f:write(string.format("<!-- depth=%spt -->\n", depth))
        f:close()
        return true
    end
end

function NewLatexRender()
    return {
        preamble = [[
            \usepackage{amsmath}
            \usepackage{amsfonts}
            \usepackage{amssymb}
            \usepackage[T1,T2A]{fontenc}
            \usepackage{colordvi}
            \usepackage[active,tightpage]{preview}
        ]],
        latexClass = "article",
        fontEncoding = "utf8",
        fontSize = 12,
        bgcolor = "#FFFFFF",
        latexPath = "latex",
        dvisvgmPath = "dvisvgm"
    }
end

function html2rgb(color)
    return ''
end

function wrapFormula(lr, latexFormula)
    local bgcolor = lr.bgcolor ~= "#FFFFFF" and string.format("\\background{%s}\n", html2rgb(lr.bgcolor)) or ''
    local tex = string.format([[\documentclass[%dpt]{%s}
        \usepackage[%s]{inputenc}
        %s
        \begin{document}
        %s
        \begin{preview}
        %s
        \end{preview}
        \end{document}
        ]], lr.fontSize, lr.latexClass, lr.fontEncoding, lr.preamble, bgcolor, latexFormula)
    -- io.write(string.format("tex: [[%s]]\n", tex))
    return tex
end

function getDepth(out)
    local depth = string.match(out, "depth=(%d*%.?%d*)")
    return tonumber(depth)
end

function renderLatex(lr, latexFormula)
    local latexDocument = wrapFormula(lr, latexFormula)
    local currDir = system.get_working_directory()
    if currDir == nil then
        return nil
    end
    local svgFileName = pandoc.sha1(latexDocument) .. ".svg"
    local svgPath = currDir .. "/" .. svgFileName
    local f = io.open(svgPath, "r")
    if f ~= nil then
        local depth = getDepth(f:read("a"))
        f:close()
        io.write(string.format("found SVG file=%s with depth=%spt\n", svgPath, depth))
        return depth, svgFileName
    end
    -- SVG file does not exist
    local depth = system.with_temporary_directory("latexmath", function(tmpDir)
        system.with_working_directory(tmpDir, function()
            io.write(string.format("changed directory to (%s)\n", tmpDir))
            local tmpFile = io.open("latexmath.tex", "w")
            tmpFile:write(latexDocument)
            tmpFile:close()
            local out = command(lr, svgPath)
            if out == nil then
                return nil
            end
            local depth = getDepth(out)
            if depth == nil then
                io.write(string.format("%s: depth not found\n", svgPath))
            else
                io.write(string.format("%s: depth=%spt\n", svgPath, depth))
                if appendDepthToSVGFile(depth, svgPath) == nil then
                    return nil
                end
            end
            return depth
        end)
    end)
    return depth, svgFileName
end

function command(lr, svgPath)
    pandoc.pipe(lr.latexPath, {"--interaction=nonstopmode", "latexmath.tex"}, '')
    -- out = pandoc.pipe(lr.dvisvgmPath, {"--no-fonts", "-o", svgPath, "latexmath.dvi"}, '')
    local f = io.popen(lr.dvisvgmPath .. " --no-fonts -o \"" .. svgPath .. "\" latexmath.dvi 2>&1")
    local out = f:read("a")
    f:close()
    -- io.write(string.format("out: [[%s]]\n", out))
    return out
end

function Math(elem)
    local latexFormula1
    local latexFormula = elem.text
    if elem.mathtype == "InlineMath" then
        latexFormula1 = string.format("\\(%s\\)", latexFormula)
    else
        -- DisplayMath
        latexFormula1 = string.format("\\[%s\\]", latexFormula)
    end
    local lr = NewLatexRender()
    local depth, svgFileName = renderLatex(lr, latexFormula1)
    local attrs = {
        alt = latexFormula
    }
    if depth ~= nil then
        attrs["style"] = string.format("vertical-align:-%spt", depth)
    end
    -- io.write(string.format("%s\n", dump(attrs)))
    return pandoc.Image('', svgFileName, '', attrs)
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
