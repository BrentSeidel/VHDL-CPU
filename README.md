
# VHDL-CPU
I've long had interest in designing and building a computer.
At times this could be done by buying some components and plugging
them together.  It's not quite the same though.  However using a
common CPU provides access to a vast library of ready made software.
Thus, designing a custom CPU is a rather niche activity.

With FPGAs and hardware definition languages like VHDL or Verilog,
one can skip many of the solder/un-solder steps and rewiring.

I have recently purchased a couple of Arduino MKR Vidor 4000s.  These
contain a FPGA and an ARM M0+ processor.  Now, I decided to learn VHDL
and it seems like a CPU would make a good learning project.

So, this project contains the developement of a CPU along with my
learning VHDL.  Expect there to be various dead ends and bad ideas.
These will hopefully be replaced by better ideas as time goes on.

There are two main components in this repository:
1. An Arduino sketch to load and test the designing
2. The VHDL code for the CPU.

## Documentation
I'm starting to write some simple documentation.  Most of it should be linked from this
section:
* [Bus between CPU and FPGA](doc/Bus.md)
* [CPU Description](doc/CPU32.md)
* [CPU Bus Description](doc/CPU-Bus.md)

## Lessons Learned
This is a list of things that I've learned.  These are the more major items that have had
me stumped for a few days, not minor items.
* If you want to use a function from a package, make sure that the function is listed in
the package spec.  This should have been obvious to an Ada programer, but...
* Sometimes you need to use edge triggering rather than level.  Note that this only works
for std_logic and std_ulogic.
* This one didn't stump me yet, but I was looking into data busses on FPGAs and it seems
that bidirectional busses are not a good idea.
* Timing issues.  If you have an edge triggered signal to store data in a latch, don't use
the same signal to select the data.
* If things aren't working, find a way to examine the internal state.  Both in the software
and in the FPGA.  This is many times important.

## Roadmap
This is more or less what I see that needs to be done to get to a working CPU.  This list will
probably be rather dynamic with things being added and deleted as work progresses.
* Ongoing various bright ideas on how to better organize things
* Currently working on preparations to add the bus interface to the CPU
* Get the CPU to be able to talk to the RAM module
* Preparations for instruction decoder
* Add instruction decoder
* Start implementing instructions