# LaTeX math to SVG Lua Pandoc filter

## Description
The `latex-math.lua` filter for [Pandoc](https://pandoc.org) converts [LaTeX](http://www.andy-roberts.net/writing/latex) math formulas to SVG.

## Prerequisites
* LaTeX must be installed. [MiKTeX](https://miktex.org) on Windows. [TeX Live](http://www.tug.org/texlive/) on Windows and other OS.
* [`dvisvgm`](https://dvisvgm.de) 1.4 or later. `dvisvgm` is now part of MiKTeX.
* The [`preview`](https://ctan.org/tex-archive/macros/latex/contrib/preview) package for LaTeX must be installed. MiKTeX will install the package automatically when the filter is executed the first time.

## Usage
To use the `latex-math.lua` filter you need to save download it and place it into the working directory. Example:

```
@echo off
pandoc -t html5 -o test.html --lua-filter latex-math.lua --standalone test.md
```

The `latex-math.lua` filter will generate an SVG file for each math formula and place it into the working directory.
