# CPU Bus
This provides notes on the CPU bus operation.
* The bus is daisy chained, thus each node passes signals to the next node.
* If a node is selected, it should not pass anything to the next node.
* Currently, the CPU is the only bus masters so the address bus is not daisy chained.
* Daisy chained signals include the following
    * Data from CPU
	* Data to CPU
	* Read request (from CPU)
	* Write request (from CPU)
	* Request acknowlege (to CPU)
