macro-clean
===========

Kills unused macro definitions in latex projects.

# Inputs: 

* file containing one-line macro definitions
* multiple tex files which use the macros in the above file

Finds all unused macro definitions and sends to stdout the macro
file, omitting the unused lines.

# Sample Usage:

    ghc -i macroclean.hs macros_file.sty file1.tex file2.tex > new_macros_file.sty

or  

    ghc macroclean
    ./macroclean macros_file.sty file1.tex file2.tex > new_macros_file.sty
