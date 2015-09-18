omake-fork
==========

My fork of omake for Cygwin32 + MinGW64 OCaml

* The cross compiler's `ar` command is used, instead of `/usr/bin/ar`
* Bootstrapping uses native compilation, instead of byte, since bootstrapped byte `omake` is known crashing in MinGW64 OCaml.

For OPAM,

* Installation with `PREFIX=/home/userid/.opam/system` fails since the installation is done by MinGW OMake. Needed to convert it to `PREFIX=c:/cygdrive/c/home/userid/.opam/system`




