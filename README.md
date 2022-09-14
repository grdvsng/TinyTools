# TinyTools version 0.01

Useful utilities for processing large requests, working with OOP, web requests.

- Some universal examples

# INSTALLATION

To install this module type the following:

```console
perl Makefile.PL
make
./test
make install
```

# Examples

1. [Remove duplicates from big hash](t/TinyTools/Hash/Utils.t)
2. [Class Accessors](t/TinyTools/Class/Accessor.t)
3. [Data processing from the database](t/TinyTools/DB/Query/Stream.t)
4. [Avoid memory leaks in loops with cross-references](t/TinyTools/avoid-memory-leaks-in-loops-whith-cross-references.t)
5. [Preventing memory leaks in loops with objects containing subroutines](t/TinyTools/preventing-memory-leaks-in-loops-with-objects-containing-subroutines.t)
6. HTTP requests
    6.1 [HTTP Sync request](t/TinyTools/HTTP/Request.t)
    6.2 [HTTP Async request](t/TinyTools/HTTP/Async/Request.t)
7. [How inheritance works in Perl with an example](t/TinyTools/Inheritance.t) 