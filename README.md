# TAOCP - MIX/MIXAL Interpreter

A complete Ruby implementation of **MIX**, the computer created by Donald Knuth for his series "The Art of Computer Programming" (TAOCP), along with its assembly language **MIXAL**.

## What is MIX?

[MIX](https://en.wikipedia.org/wiki/MIX_(abstract_machine)) is a hypothetical computer designed by Donald Knuth in the 1960s as a tool for teaching fundamental computer science concepts. It appears throughout TAOCP to illustrate algorithms in a machine-independent way.

**Key characteristics:**
- Bytes hold values 0-63 (not 0-255 like modern computers)
- Sign-magnitude representation
- Word-addressed memory (not byte-addressed)

MIX is intentionally old-fashioned, representing computers of the 1960s era. Knuth later created [MMIX](https://en.wikipedia.org/wiki/MMIX), a more modern 64-bit RISC architecture, but MIX remains the primary machine for TAOCP Volumes 1-3.

**Why would you use this gem?**
- Study algorithms from TAOCP in their original form
- Learn computer architecture fundamentals
- Understand how assembly language and virtual machines work
- Run and experiment with classic algorithms
- Educational purposes and computer science history

## Resources

- [The Art of Computer Programming](https://www-cs-faculty.stanford.edu/~knuth/taocp.html) - Knuth's official TAOCP site
- [MIX on Wikipedia](https://en.wikipedia.org/wiki/MIX_(abstract_machine)) - Comprehensive overview of MIX architecture
- [TAOCP Volume 1](https://www-cs-faculty.stanford.edu/~knuth/taocp.html) - Fundamental Algorithms (where MIX is introduced)
- [GNU MDK](https://www.gnu.org/software/mdk/manual/) - Alternative MIX implementation with MIXAL reference
- [Donald Knuth](https://en.wikipedia.org/wiki/Donald_Knuth) - About the creator of TeX, METAFONT, and TAOCP

## Features

- **Complete MIX Virtual Machine** - Full implementation of the MIX computer architecture including:
  - 4000 words of memory (5-byte words with sign)
  - All registers: A (accumulator), X (extension), I1-I6 (index), J (jump)
  - All instruction sets: arithmetic, comparison, jumps, shifts, I/O stubs
  - Proper overflow handling and comparison indicators

- **MIXAL Assembler** - Two-pass assembler with:
  - Complete MIXAL syntax support
  - Symbol table with forward references
  - Expression evaluation (arithmetic in address fields)
  - Literal constants (=value=)
  - All pseudo-operations: ORIG, EQU, CON, ALF, END
  - Comprehensive error reporting

- **Command-Line Interface** - Easy-to-use CLI for assembling and running programs

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'taocp'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install taocp

## Quick Start

### Command Line Usage

The `mix` command provides three modes of operation:

```bash
# Assemble a MIXAL program
$ mix assemble examples/factorial.mixal

# Run an assembled program
$ mix run factorial.mix

# Assemble and run in one step
$ mix exec examples/factorial.mixal
```

### Example Program

Here's the MIXAL program that calculates 6! (factorial of 6):

```mixal
* Calculate factorial of 6 (result = 720)
        ORIG 0
START   ENTA 6
        STA  N
        ENTA 1
        STA  RESULT
LOOP    LDA  RESULT
        MUL  N
        STX  RESULT     Product goes to rX
        LDA  N
        DECA 1
        STA  N
        CMPA =0=
        JG   LOOP
        HLT
N       CON  0
RESULT  CON  0
        END  START
```

Save as `factorial.mixal` and run:

```bash
$ mix exec factorial.mixal
Assembling factorial.mixal...
  Start address: 0
Running...
✓ Halted after 53 instructions

Final registers:
  A  = 0
  X  = 720
  ...
```

## Programming with MIX/MIXAL

### MIX Architecture

The MIX computer is a hypothetical computer used throughout TAOCP. Key features:

- **Memory**: 4000 words (addresses 0-3999)
- **Word Size**: 1 sign bit + 5 bytes (each byte is 0-63, not 0-255!)
- **Registers**:
  - A: Accumulator (5 bytes + sign)
  - X: Extension register (5 bytes + sign)
  - I1-I6: Index registers (2 bytes + sign)
  - J: Jump register (2 bytes, always positive)

### MIXAL Syntax

MIXAL (MIX Assembly Language) uses a line-based format:

```
[LABEL]  OPERATION  [ADDRESS][,INDEX][(FIELD)]  [COMMENT]
```

Examples:

```mixal
START   LDA   1000          Load from address 1000
        STA   2000,1        Store to 2000 + I1
        LDA   VALUE(1:3)    Load bytes 1-3 from VALUE
LOOP    JMP   START         Jump to START
VALUE   CON   42            Constant value 42
TEXT    ALF   HELLO         5-character string
SIZE    EQU   100           Define constant
```

### Instruction Set

**Arithmetic**:
- `LDA`, `LDX`, `LD1`-`LD6` - Load
- `STA`, `STX`, `ST1`-`ST6` - Store
- `ADD`, `SUB`, `MUL`, `DIV` - Arithmetic
- `INCA`, `DECA`, `ENTA`, `ENNA` - Address transfer

**Comparison and Jumps**:
- `CMPA`, `CMPX`, `CMP1`-`CMP6` - Compare
- `JMP`, `JL`, `JE`, `JG`, `JLE`, `JNE`, `JGE` - Unconditional/conditional jumps
- `JAN`, `JAZ`, `JAP`, `JANN`, `JANZ`, `JANP` - Jump on A register
- `J1N`-`J6N`, `JXN` (and Z, P, NN, NZ, NP variants) - Jump on index/X

**Shift and Special**:
- `SLA`, `SRA`, `SLAX`, `SRAX` - Shift left/right
- `SLC`, `SRC` - Circular shift
- `NUM`, `CHAR` - Numeric conversion
- `HLT` - Halt
- `NOP` - No operation

**Pseudo-Operations**:
- `ORIG` - Set location counter
- `EQU` - Define symbol
- `CON` - Define constant
- `ALF` - Define alphanumeric constant (5 chars)
- `END` - End of program (with optional start address)

## Ruby API

You can also use MIX/MIXAL directly from Ruby:

```ruby
require 'taocp'

# Assemble a program
assembler = Taocp::Mixal::Assembler.new
assembler.assemble(source_code)

# Create and run MIX machine
machine = Taocp::Mix::Machine.new

# Load assembled code
assembler.memory.each_with_index do |word, addr|
  machine.memory[addr] = word
end
machine.pc = assembler.start_address || 0

# Execute
machine.run

# Check results
puts "A register: #{machine.registers.a.to_i}"
puts "X register: #{machine.registers.x.to_i}"
```

### Working with MIX Words

```ruby
# Create a word from an integer
word = Taocp::Mix::Word.from_i(12345)

# Access components
word.sign    # => 1 (positive)
word.bytes   # => [0, 0, 48, 57, 57]

# Convert back to integer
word.to_i    # => 12345

# Field specifications
word = Taocp::Mix::Word.new(sign: 1, bytes: [1, 2, 3, 4, 5])
word.get_field(1, 3)  # Get bytes 1-3
```

### Working with Instructions

```ruby
# Create an instruction
inst = Taocp::Mix::Instruction.new(
  address: 1000,
  index: 1,
  field: 5,
  opcode: Taocp::Mix::Instruction::LDA
)

# Convert to/from word
word = inst.to_word
inst2 = Taocp::Mix::Instruction.from_word(word)
```

## Examples

The `examples/` directory at the moment has only one example:

- `factorial.mixal` - Calculate factorial
- More examples coming soon!

## Testing

The project includes comprehensive test coverage (345 tests):

```bash
$ rake test
```

Test suites include:
- Unit tests for all MIX components (Word, Instruction, Memory, Registers)
- Integration tests for all instruction types
- MIXAL lexer and parser tests
- Assembler tests
- **TAOCP example programs** - Real programs from Knuth's books

## Architecture

The implementation follows a clean separation:

```
lib/taocp/
├── mix/                    # MIX Virtual Machine
│   ├── word.rb            # 5-byte word with sign
│   ├── instruction.rb     # Instruction encoding/decoding
│   ├── memory.rb          # 4000-word memory
│   ├── registers.rb       # A, X, I1-I6, J registers
│   ├── machine.rb         # VM execution engine
│   └── character.rb       # MIX character encoding
└── mixal/                  # MIXAL Assembler
    ├── lexer.rb           # Tokenization
    ├── parser.rb          # AST generation
    ├── symbol_table.rb    # Symbol resolution
    └── assembler.rb       # Two-pass assembly
```

### Implementation Details

- **Byte Values**: MIX bytes hold values 0-63 (6-bit), not 0-255 (8-bit) like modern computers
- **Sign-Magnitude**: Numbers use sign-magnitude representation, not two's complement
- **Field Specifications**: Instructions can operate on partial words using (L:R) notation
- **Two-Pass Assembly**: First pass builds symbol table, second pass generates code
- **Literal Pool**: Literals (=value=) are automatically collected and placed at program end

## Differences from Knuth's MIX

This implementation is faithful to TAOCP with these notes:

- **I/O Devices**: I/O instructions (`IN`, `OUT`, `IOC`, `JBUS`, `JRED`) are stubs
- **Character Set**: Uses a simplified MIX character encoding (A=1, B=2, etc.)
- **Tape/Disk**: No tape or disk unit simulation
- **Timing**: Instruction execution is not cycle-accurate

## Development

After checking out the repo:

```bash
$ bin/setup              # Install dependencies
$ rake test              # Run tests
$ bin/console            # Interactive prompt
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/philcrissman/quack.

Contributions are especially welcome for:
- More example programs from TAOCP
- I/O device simulation
- Debugger/step-through mode
- Performance improvements

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

This implementation is based on Donald Knuth's MIX computer description in "The Art of Computer Programming" (TAOCP). MIX is a pedagogical tool designed to teach fundamental computer architecture concepts.
