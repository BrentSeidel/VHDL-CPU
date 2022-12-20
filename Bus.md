# CPU-FPGA Bus
For me, the first step is getting some sort of bus working between
the CPU and the FPGA.  This will allow code on the CPU to access
bits of stuff in the FPGA for testing and development.

There appear to be two primary sets of pins between the two.  On the
FPGA side, they are referred to as:
bMKR_A : inout std_logic_vector (6 downto 0)
bMKR_D : inout std_logic_vector (14 downto 0)

On the CPU side, bMKR_D() corresponds to pins 14 downto 0 and bMDK_A()
corresponds to pins 21 downto 15.  There is not an obviously documented
way to set multiple pins at once.  I'm sure that by digging through the
schematics and data sheets, I could figure out which port each pin belongs
to and how to read/write them all at once.

So, ugly and inefficiant as it is, the software on the CPU reads/writes
one pin at a time.  It works, but there are better ways to do it.

## Bus definition
On the CPU Side:
| CPU Pin | Bus Signal |
| -------- | ------- |
| 0 | Data 0 LSB |
| 1 | Data 1 |
| 2 | Data 2 |
| 3 | Data 3 |
| 4 | Data 4 |
| 5 | Data 5 |
| 6 | Data 6 |
| 7 | Data 7 MSB |
| 8 | Address 0 LSB |
| 9 | Address 1 |
| 10 | Address 2 |
| 11 | Address 3 |
| 12 | Address 4 |
| 13 | Address 5 |
| 14 | Address 6 MSB |
| 15 | Write Data |
| 16 | Read Data |

On the FPGA Side:
```
data_bus <= bMKR_D(7 downto 0);
addr_bus <= bMKR_D(14 downto 8);
write_reg <= bMKR_A(0);
read_reg <= bMKR_A(1);
'''
