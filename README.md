libcgc-x86
==========
x86 version for [libcgc](https://github.com/CyberGrandChallenge/libcgc) 

Installation
-----------
```sh
make
sudo make install
```

Comile CGC binaries for x86
---------------------------
- Install this library
- Compile [cgc-samples](https://github.com/CyberGrandChallenge/samples) using CGC toolchains
- Convert binaries into ELF format using [cgc2elf](https://github.com/CyberGrandChallenge/cgc2elf)

Known problems
--------------
- A special page flag page in CGC does not exist
- The better alternative: [cb-multios](https://github.com/trailofbits/cb-multios)
