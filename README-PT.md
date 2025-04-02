# pForth

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Compilador e interpretador interativo FIG-FORTH escrito em assembly Z80. Roda no simulador z88dk-ticks.

## Destaques

- Compilador e interpretador interativo pFORTH via linha de comando
- Interpretador interno com código indiretamente encadeado (NEXT, DOCOL, EXIT) e TOS em cache no DE
- Dicionário núcleo: primitivas de pilha, memória, matemática, compilador e controle de fluxo
- I/O via portas Z80 (`IN A,(1)` / `OUT (1),A`) com `z88dk-ticks -iochar=1`
- Harness de testes em assembly executado no z88dk-ticks
- Dicionário altamente modular e conjunto de primitivas facilmente extensível

## Pré-requisitos

- **sjasmplus** — assembler Z80 (preferido); o `z80asm` do Debian é um fallback aceito
- **z88dk-ticks** — simulador Z80 em linha de comando (`z88dk-ticks -iochar=1`)
- **Python 3.10+** — necessário para o executor de testes em assembly

## Instalação

### Compilar a partir do código-fonte

```bash
git clone https://github.com/carlosrabelo/pforth.git
cd pforth
make build
```

## Uso

### Compilar e executar

```bash
make run
```

### Apenas compilar

```bash
make build
```

Isso monta os módulos Z80 em um binário:

```bash
# Rodar o binário Z80 no simulador z88dk-ticks
z88dk-ticks -iochar=1 -l 0 -pc 0 bin/pforth.bin
```

## Estrutura do Projeto

```
src/                # Fontes em assembly Z80
tests/              # Suítes de testes em assembly e o executor Python
demos/              # Programas Forth de demonstração
bin/                # Binário montado (ignorado no git)
Makefile            # Orquestrador de build
.make/              # Scripts auxiliares de build
```

## Desenvolvimento

```bash
make help              # Mostra os alvos disponíveis
make build             # Monta os fontes Z80
make test              # Compila, confere os fontes e rótulos; executa testes em assembly se o z88dk-ticks estiver instalado
make run               # Compila e executa no z88dk-ticks
make clean             # Remove os artefatos de build
```

## Licença

Este projeto está licenciado sob a Licença MIT — veja [LICENSE](LICENSE) para detalhes.
