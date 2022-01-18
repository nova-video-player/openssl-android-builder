### openssl-Android-builder

A simple shell script to cross-compile openssl project for Android targets.

Builds the binaries and libs using dynamic linking.

Typical usage:
```
bash ./build.sh -a $ARCH
```

$ARCH can be either: arm arm64 x86 x86_64

mips and mips64 are untested

Requirements:
- NDK
- some dev tools
- free disk space in your tempfolder
