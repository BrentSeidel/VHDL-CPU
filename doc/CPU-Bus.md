# CPU Bus
This provides notes on the CPU bus operation.
* Some of the bus signals are daisy-chained, thus each node passes signals to the next node.
* If a node is selected, it should not pass anything to the next node.
* Currently, the CPU is the only bus masters.
* Daisy chained signals include the following:
	* Data to CPU
	* Request acknowlege (to CPU)
* Non-Daisy chained signals include the following:
    * Address (from CPU)
    * Data from CPU
	* Read request (from CPU)
	* Write request (from CPU)

## Bus Transactions
Note that read request and write request should never be high at the same time.  This is an undefined
state.  They can both be low as this just means that the bus is idle.

### Read Data
1. Set address value and set Read Request high.
2. Wait for Request Acknowlege to be set by device.
3. Read value from Data to CPU and set Read Request low.

### Write Data
1. Set address value, Data from CPU, and Write Request high.
2. Wait for Request Acknowlege to be set high by device.
3. Set Write Request low.

There is a potential for the system to hang if an unpopulated address is accessed.  Possible
solutions are a "last chance" device at the end of the chain that responds with an acknowlege,
or having a timeout in the bus interface unit that flags an error if no response is received
within a specified number of clock cycles.
