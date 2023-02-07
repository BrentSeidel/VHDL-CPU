# CPU Documentation

A block diagram of the current state of the CPU is below.  As should be
obvious, it is far from finished.

![CPU Diagram](./CPU32.svg)

The main components are:
* [Register file](Register.md) - created and seems to work
* [ALU](ALU.md) - created and seems to work
* Sequencer - Preliminary version created
* Processor Status Word - Preliminary version created with processor flags
* Instruction decoder - TBD
* [Bus Interface](BIU.md) - Work started

This will probably never be a particularly high performance or sophisticated
CPU.  I will declare victory once I get a basic set of instructions to
work properly.

The Vidor 4000 also has a 8 MB SDRAM chip that will require a memory
controller to access.  This would be outside of the CPU, but would be
needed for it to really be useful.

## Instruction Set
Note that there are several constraints made to simplify things.  Some of these
may be relaxed in the future as the design develops.
* The smallest addressable item is a 32-bit word.
* This is a load-store architecture.
* Instructions are all 32 bits long (sometimes followed by 32 bit data).
* There are no floating point operations. (this would be an interesting future exercise)
