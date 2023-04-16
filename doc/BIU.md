# Bus Interface Unit (BIU)
The bus interface is responsible for moving data in and out of the
CPU.

## Operations
The BUI supports two main operations - read and write.

### Write
The address and data out are set along with the write command.  The BIU then
waits for an acknowledge.

### Read
The address is set along with the read command.  The BIU then waits for an
acknowledge before reading the data in.

### State Diagram
The state diagram of the bus interface unit is (subject to change)
![BIU State Diagram](./BIU-states.svg)
