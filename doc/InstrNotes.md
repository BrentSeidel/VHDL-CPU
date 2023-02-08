# Instruction Set Notes
Right now, this is a working document used to work out ideas.  Expect much
changes and I think about various things.

Note that there are several constraints made to simplify things.  Some of these
may be relaxed in the future as the design develops.
* The smallest addressable item is a 32-bit word.
* This is a load-store architecture.
* Instructions are all 32 bits long (sometimes followed by 32 bit data).
* There are no floating point operations. (this would be an interesting future exercise)

## Addressing Modes
Difficulty to implement and usefulness may be opposing idea.  I'm probably most familiar
with the PDP-11 instruction set and addressing modes, so these will probably be based on
that.  Note that the addressing modes only apply to load-store instructions.  All other
instructions just use registers.
* Register (just use the value in the register)
* Register Indirect (register contains the address)
* Register Indirect with Increment (useful for stacks and immediate values)
* Register Indirect with Decrement (useful for stacks)
* Register plus Offset Indirect (nice, but would require an extra bit and can be done in other ways).

## Instruction Formats
Several instruction formats will be used.  Since there are 16 registers, all register addresses
are 4 bits.  Addressing mode will probably be 2 bits.
* ALU - Op (20 bits), R1 (source), R2 (source), R3 (dest).
* Load - Op (22 bits), Addr Mode, R1 (source), R2 (dest).  Addr mode applies to source.
* Store - Op (22 bits), Addr Mode, R1 (source), R2 (dest).  Addr mode applies to dest.


## Op Codes
