# The Register File
The register file consists of 16 32-bit registers.  There are
three read ports and one write port.  It is expected that reads
and writes will not occur simultaneously.

The VHDL is written so that the write will happen first, but
don't depend on this.  Consider this to be undefined behaviour.
