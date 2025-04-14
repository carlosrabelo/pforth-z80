# pForth

## First milestone

Minimal Z80 bootstrap compiler and interactive outer interpreter loop running on z88dk-ticks.

## Z80 Foundation

- [x] CPU memory layout configuration
- [x] Inner interpreter loop (NEXT, DOCOL, SEMI)

## Z80 Minimal TTY & Input Processing

- [x] KEY
- [x] EMIT
- [x] WORD
- [x] NUMBER
- [x] FIND
- [x] EXECUTE

## Z80 Compiler & Outer Loop

- [x] STATE
- [x] LIT
- [x] INTERPRET
- [x] QUIT
- [x] COLD
- [x] [
- [x] ]
- [x] CREATE
- [x] ,
- [x] IMMEDIATE
- [x] :
- [x] ;

## Test Automation

- [x] Z80 assembly test harness
- [ ] Python test runner script
- [ ] Makefile test target integration

## Second milestone

Standard pFORTH dictionary expansion and validation.

## Z80 Dictionary Expansion

### Stack Manipulation

- [ ] DUP
- [ ] DROP
- [ ] SWAP
- [ ] OVER
- [ ] ROT
- [ ] ?DUP
- [ ] >R
- [ ] R>
- [ ] R@

### Memory & Register Access

- [ ] @
- [ ] !
- [ ] C@
- [ ] C!
- [ ] +!

### Logic & Math

- [ ] +
- [ ] -
- [ ] AND
- [ ] OR
- [ ] XOR
- [ ] 0=
- [ ] 0<
- [ ] U<
- [ ] =
- [ ] <
- [ ] >
- [ ] *
- [ ] /MOD
- [ ] /
- [ ] MOD

### Compiler & Variables

- [ ] HERE
- [ ] PAD
- [ ] ALLOT
- [ ] C,
- [ ] CONSTANT
- [ ] VARIABLE
- [ ] [COMPILE]
- [ ] COMPILE
- [ ] LITERAL

### Control Flow

- [ ] IF
- [ ] ELSE
- [ ] THEN
- [ ] BEGIN
- [ ] UNTIL
- [ ] WHILE
- [ ] REPEAT
- [ ] DO
- [ ] LOOP
- [ ] +LOOP
- [ ] I
- [ ] LEAVE

### Formatting & TTY

- [ ] CR
- [ ] SPACE
- [ ] SPACES
- [ ] TYPE
- [ ] EXPECT

---

## Third milestone

Forth demonstration applications.

## Demos

- [ ] Sieve of Eratosthenes benchmark
- [ ] Block-based line editor
- [ ] Mini text adventure game
- [ ] WORDS and DUMP system tools
