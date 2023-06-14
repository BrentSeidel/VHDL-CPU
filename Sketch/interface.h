//
//  Functions for communicating on the FPGA interface bus
//
//
//
//  Data bus
const int DATA_LSB = 0;
const int DATA_MSB = 7;
//
//  Address bus
const int ADDR_LSB = 8;
const int ADDR_MSB = 14;
//
//  Control pins
const int REG_WRITE  = 15;
const int REG_READ   = 16;
const int SLOW_CLOCK = 17;

#ifdef __cplusplus
extern "C" {
#endif
void set_addr(int addr);
void write_data(int data);
int read_data();
void write_addr(int addr, int data);
int read_addr(int addr);
