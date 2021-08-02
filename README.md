macro-clean
===========

Kills unused macro definitions in latex projects.
Appropriately handles macros which use other macros.

# Inputs: 

* file containing one-line macro definitions
* multiple tex files which use the macros in the above file

Finds all unused macro definitions and sends to stdout the macro
file, omitting the unused lines.

# Compile:

From the root directory, run

    $ ghc macroclean

# Sample Usage:

From the "example" subdirectory, run

    $ ghc ../macroclean sample_macros.sty sample1.tex sample2.tex > output.sty

Compare the output

    $ diff sample_macros.sty output.sty
    7d6
    < \newcommand{\unusedMacro}{This is sad.}
    12,13d10
    < \newcommand{\unusedNestBottom}{Something or Other \upperNestBot}
    < \newcommand{\unusedNestTop}{Something, \unusedNestBottom}
    27c24
    < \newcommand{\macroSecondFile}{\int_0^1 x^2\, dx}
    \ No newline at end of file
    ---
    > \newcommand{\macroSecondFile}{\int_0^1 x^2\, dx}

The expected output is in `example/expected_output.sty`

   $ diff -s expected_output.sty output.sty
   Files expected_output.sty and output.sty are identical

