//
//  Based on the program available here: https://content.arduino.cc/assets/SketchVidorFPGA.zip
//  defines.h, jtag.c, and jtag.h are from that archive.  app.h is generated from the .ttf file
//  using the vidorcvt program.  I have modified sketch.ino for this demo.
//
#include <wiring_private.h>
#include "jtag.h"
#include "defines.h"
#include "constants.h"
#include "interface.h"
//
//  Global counters for test pass and fail
int tests  = 0;
int passes = 0;
int fails  = 0;
//
//  Define some functions.
void test_cpu_flags(int expected);
void print_flags(int flag);
void cpu_write_reg(int data, int addr);
int cpu_read_reg(int addr);
void dump_cpu_reg();
void set_flags(int flags);
void test_cpu(int op1, int op2, int func, int incdec, int expected,
  const char *name, int flg);
void test_incdec(int reg, int dir);
void ram_write(int addr, int data);
int ram_read(int addr);
void cpu_write_mem(int addr, int data);
int cpu_read_mem(int addr);
//-----------------------------------------------------------
void setup()
{
  int x;

  setup_fpga();

  Serial.begin(9600);
  //
  //  Set modes for data bus pins
  for (x = DATA_LSB; x <= DATA_MSB; x++)
  {
    pinMode(x, INPUT);
  }
  //
  //  Set modes for address bus pins
  for (x = ADDR_LSB; x <= ADDR_LSB; x++)
  {
    pinMode(x, OUTPUT);
  }
  //
  //  Set mode for control pins
  pinMode(REG_WRITE, OUTPUT);
  pinMode(REG_READ, OUTPUT);
  pinMode(SLOW_CLOCK, OUTPUT);
  digitalWrite(REG_WRITE, 0);
  digitalWrite(REG_READ, 0);
  digitalWrite(SLOW_CLOCK, 0);

  Serial.println("FPGA and MCU started.");
}
//
//  Main processing loop
void loop()
{
  int x;
  int y;

  //
  //  Show some counter values
  x = read_addr(COUNT_LSB);
  y = read_addr(COUNT_MSB);
  Serial.print("Counter value ");
  Serial.println(x + (y<<8));
  delay(10);
  x = read_addr(COUNT_LSB);
  y = read_addr(COUNT_MSB);
  Serial.print("Counter value ");
  Serial.println(x + (y<<8));
  //
  write_addr(CPU_FUNCT, 0);
  write_addr(CPU_ENABLES, 0);
  write_addr(CPU_WADDR, 0);
  write_addr(CPU_FLAGS, 0);
  //
  //  Test CPU registers
  for (x = 0; x < 16; x++)
  {
    cpu_write_reg(x+0xFF00FF, x);
  }
  dump_cpu_reg();
  //
  //  Start CPU tests
  Serial.println("Starting CPU tests.");
  test_cpu(1, 2, ALU_OP_ERR, CTRL_NONE, 0, "Error", ALU_FLAG_ERROR + ALU_FLAG_ZERO);
  set_flags(0);
  test_cpu(31, 20, ALU_OP_ADD, CTRL_NONE, 51, "31 ADD 20", ALU_FLAG_NONE);
  test_cpu(21, 40, ALU_OP_ADD, CTRL_NONE, 61, "21 ADD 40", ALU_FLAG_NONE);
  test_cpu(0xFFFF, 1, ALU_OP_ADD, CTRL_NONE, 0x10000, "FFFF ADD 1", ALU_FLAG_NONE);
  test_cpu(0x7FFF, 1, ALU_OP_ADD, CTRL_NONE, 0x8000, "7FFF ADD 1", ALU_FLAG_NONE);
  test_cpu(0xFF0000, 0xFF, ALU_OP_ADD, CTRL_NONE, 0xFF00FF, "FF0000 ADD FF", ALU_FLAG_NONE);
  //
  test_cpu(31, 20, ALU_OP_SUB, CTRL_NONE, 11, "31 SUB 20", ALU_FLAG_NONE);
  test_cpu(20, 31, ALU_OP_SUB, CTRL_NONE, -11, "20 SUB 31",
           ALU_FLAG_SIGN + ALU_FLAG_CARRY);
  //
  test_cpu(127, 0, ALU_OP_NOT, CTRL_NONE, -128, "127 NOT", ALU_FLAG_SIGN);
  test_cpu(1, 123, ALU_OP_NOT, CTRL_NONE, -2, "1 NOT", ALU_FLAG_SIGN);
  //
  test_cpu(15, 13, ALU_OP_AND, CTRL_NONE, 13, "15 AND 13", ALU_FLAG_NONE);
  test_cpu(16, 15, ALU_OP_AND, CTRL_NONE, 0, "16 AND 15", ALU_FLAG_ZERO);
  //
  test_cpu(16, 15, ALU_OP_OR, CTRL_NONE, 31, "16 OR 15", ALU_FLAG_NONE);
  test_cpu(15, 13, ALU_OP_OR, CTRL_NONE, 15, "15 OR 13", ALU_FLAG_NONE);
  //
  test_cpu(5, 15, ALU_OP_XOR, CTRL_NONE, 10, "5 XOR 15", ALU_FLAG_NONE);
  test_cpu(255, 254, ALU_OP_XOR, CTRL_NONE, 1, "255 XOR 254", ALU_FLAG_NONE);
  test_cpu(123, 123, ALU_OP_XOR, CTRL_NONE, 0, "123 XOR 123", ALU_FLAG_ZERO);
  //
  test_cpu(0, 0, ALU_OP_TST, CTRL_NONE, 0, "0 TST", ALU_FLAG_ZERO);
  test_cpu(1, 0, ALU_OP_TST, CTRL_NONE, 1, "1 TST", ALU_FLAG_NONE);
  test_cpu(2, 0, ALU_OP_TST, CTRL_NONE, 2, "2 TST", ALU_FLAG_NONE);
  test_cpu(4, 0, ALU_OP_TST, CTRL_NONE, 4, "4 TST", ALU_FLAG_NONE);
  test_cpu(8, 0, ALU_OP_TST, CTRL_NONE, 8, "8 TST", ALU_FLAG_NONE);
  test_cpu(16, 0, ALU_OP_TST, CTRL_NONE, 16, "16 TST", ALU_FLAG_NONE);
  test_cpu(32, 0, ALU_OP_TST, CTRL_NONE, 32, "32 TST", ALU_FLAG_NONE);
  test_cpu(64, 0, ALU_OP_TST, CTRL_NONE, 64, "64 TST", ALU_FLAG_NONE);
  test_cpu(128, 0, ALU_OP_TST, CTRL_NONE, 128, "128 TST", ALU_FLAG_NONE);
  test_cpu(0x100, 0, ALU_OP_TST, CTRL_NONE, 0x100, "0x100 TST", ALU_FLAG_NONE);
  test_cpu(0x200, 0, ALU_OP_TST, CTRL_NONE, 0x200, "0x200 TST", ALU_FLAG_NONE);
  test_cpu(0x400, 0, ALU_OP_TST, CTRL_NONE, 0x400, "0x400 TST", ALU_FLAG_NONE);
  test_cpu(0x800, 0, ALU_OP_TST, CTRL_NONE, 0x800, "0x800 TST", ALU_FLAG_NONE);
  test_cpu(0x1000, 0, ALU_OP_TST, CTRL_NONE, 0x1000, "0x1000 TST", ALU_FLAG_NONE);
  test_cpu(0x2000, 0, ALU_OP_TST, CTRL_NONE, 0x2000, "0x2000 TST", ALU_FLAG_NONE);
  test_cpu(0x4000, 0, ALU_OP_TST, CTRL_NONE, 0x4000, "0x4000 TST", ALU_FLAG_NONE);
  test_cpu(0x8000, 0, ALU_OP_TST, CTRL_NONE, 0x8000, "0x8000 TST", ALU_FLAG_NONE);
  test_cpu(0x10000, 0, ALU_OP_TST, CTRL_NONE, 0x10000, "0x10000 TST", ALU_FLAG_NONE);
  test_cpu(0x20000, 0, ALU_OP_TST, CTRL_NONE, 0x20000, "0x20000 TST", ALU_FLAG_NONE);
  test_cpu(0x40000, 0, ALU_OP_TST, CTRL_NONE, 0x40000, "0x40000 TST", ALU_FLAG_NONE);
  test_cpu(0x80000, 0, ALU_OP_TST, CTRL_NONE, 0x80000, "0x80000 TST", ALU_FLAG_NONE);
  test_cpu(0x100000, 0, ALU_OP_TST, CTRL_NONE, 0x100000, "0x100000 TST", ALU_FLAG_NONE);
  test_cpu(0x200000, 0, ALU_OP_TST, CTRL_NONE, 0x200000, "0x200000 TST", ALU_FLAG_NONE);
  test_cpu(0x400000, 0, ALU_OP_TST, CTRL_NONE, 0x400000, "0x400000 TST", ALU_FLAG_NONE);
  test_cpu(0x800000, 0, ALU_OP_TST, CTRL_NONE, 0x800000, "0x800000 TST", ALU_FLAG_NONE);
  test_cpu(0x1000000, 0, ALU_OP_TST, CTRL_NONE, 0x1000000, "0x1000000 TST", ALU_FLAG_NONE);
  test_cpu(0x2000000, 0, ALU_OP_TST, CTRL_NONE, 0x2000000, "0x2000000 TST", ALU_FLAG_NONE);
  test_cpu(0x4000000, 0, ALU_OP_TST, CTRL_NONE, 0x4000000, "0x4000000 TST", ALU_FLAG_NONE);
  test_cpu(0x8000000, 0, ALU_OP_TST, CTRL_NONE, 0x8000000, "0x8000000 TST", ALU_FLAG_NONE);
  test_cpu(0x10000000, 0, ALU_OP_TST, CTRL_NONE, 0x10000000, "0x10000000 TST", ALU_FLAG_NONE);
  test_cpu(0x20000000, 0, ALU_OP_TST, CTRL_NONE, 0x20000000, "0x20000000 TST", ALU_FLAG_NONE);
  test_cpu(0x40000000, 0, ALU_OP_TST, CTRL_NONE, 0x40000000, "0x40000000 TST", ALU_FLAG_NONE);
  test_cpu(0x80000000, 0, ALU_OP_TST, CTRL_NONE, 0x80000000, "0x80000000 TST", ALU_FLAG_SIGN);
  test_cpu(0xFFFFFFFF, 0, ALU_OP_TST, CTRL_NONE, 0xFFFFFFFF, "0xFFFFFFFF TST", ALU_FLAG_SIGN);
  test_cpu(255, 0, ALU_OP_TST, CTRL_NONE, 255, "255 TST", ALU_FLAG_NONE);
  test_cpu(127, 0, ALU_OP_TST, CTRL_NONE, 127, "127 TST", ALU_FLAG_NONE);
  test_cpu(0, 255, ALU_OP_TST, CTRL_NONE, 0, "0 TST", ALU_FLAG_ZERO);
  test_cpu(0xFFFF, 0, ALU_OP_TST, CTRL_NONE, 0xFFFF, "0xFFFF TST", ALU_FLAG_NONE);
  test_cpu(0x80000000, 0, ALU_OP_TST, CTRL_NONE, 0x80000000, "128 TST", ALU_FLAG_SIGN);
  test_cpu(0xFFFFFFFF, 0, ALU_OP_TST, CTRL_NONE, 0xFFFFFFFF, "0xFFFFFFFF TST", ALU_FLAG_SIGN);
  //
  test_cpu(255, 0, ALU_OP_NEG, CTRL_NONE, -255, "255 NEG", ALU_FLAG_SIGN);
  test_cpu(127, 255, ALU_OP_NEG, CTRL_NONE, -127, "127 NEG", ALU_FLAG_SIGN);
  test_cpu(-127, 255, ALU_OP_NEG, CTRL_NONE, 127, "-127 NEG", ALU_FLAG_NONE);
  //
  test_cpu(100, 10, ALU_OP_ADC, CTRL_NONE, 110, "100 ADC 10", ALU_FLAG_NONE);
  set_flags(ALU_FLAG_CARRY);
  test_cpu(100, 10, ALU_OP_ADC, CTRL_NONE, 111, "100 ADC 10", ALU_FLAG_NONE);
  //
  set_flags(0);
  test_cpu(100, 10, ALU_OP_SBC, CTRL_NONE, 90, "100 SBC 10", ALU_FLAG_NONE);
  set_flags(ALU_FLAG_CARRY);
  test_cpu(100, 10, ALU_OP_SBC, CTRL_NONE, 89, "100 SBC 10", ALU_FLAG_NONE);
  //
  test_cpu(1, 0, ALU_OP_SHL, CTRL_NONE, 1, "1 SHL 0", ALU_FLAG_NONE);
  test_cpu(1, 1, ALU_OP_SHL, CTRL_NONE, 2, "1 SHL 1", ALU_FLAG_NONE);
  test_cpu(1, 3, ALU_OP_SHL, CTRL_NONE, 8, "1 SHL 3", ALU_FLAG_NONE);
  test_cpu(1, 31, ALU_OP_SHL, CTRL_NONE, 0x80000000, "1 SHL 31", ALU_FLAG_SIGN);
  test_cpu(1, 32, ALU_OP_SHL, CTRL_NONE, 0, "1 SHL 32",
           ALU_FLAG_ZERO + ALU_FLAG_CARRY);
  //
  test_cpu(0x80000000, 0, ALU_OP_SHR, CTRL_NONE, 0x80000000, "0x80000000 SHR 0", ALU_FLAG_SIGN);
  test_cpu(0x80000000, 1, ALU_OP_SHR, CTRL_NONE, 0x40000000, "0x80000000 SHR 1", ALU_FLAG_NONE);
  test_cpu(0x80000000, 3, ALU_OP_SHR, CTRL_NONE, 0x10000000, "0x80000000 SHR 3", ALU_FLAG_NONE);
  test_cpu(0x80000000, 31, ALU_OP_SHR, CTRL_NONE, 1, "0x80000000 SHR 31", ALU_FLAG_NONE);
  test_cpu(0x80000000, 32, ALU_OP_SHR, CTRL_NONE, 0, "0x80000000 SHR 32", ALU_FLAG_ZERO);
//
//  Test increment and decrement
//
  test_cpu(31, 20, ALU_OP_ADD, CTRL_OP2_1, 32, "31 ADD 1", ALU_FLAG_NONE);
  test_cpu(21, 40, ALU_OP_ADD, CTRL_OP2_1, 22, "21 ADD 1", ALU_FLAG_NONE);
  test_cpu(31, 20, ALU_OP_SUB, CTRL_OP2_1, 30, "31 SUB 1", ALU_FLAG_NONE);
  test_cpu(20, 31, ALU_OP_SUB, CTRL_OP2_1, 19, "20 SUB 1", ALU_FLAG_NONE);
  test_incdec(3, 1);
  test_incdec(3, 1);
  test_incdec(15, 1);
  test_incdec(15, 1);
  test_incdec(3, -1);
  test_incdec(3, -1);
  test_incdec(14, -1);
  test_incdec(14, -1);
  test_incdec(14, 1);
  test_incdec(14, 1);

  Serial.println("End of CPU tests.");
  dump_cpu_reg();
  Serial.println();
  Serial.print(tests);
  Serial.print(" tests, ");
  Serial.print(passes);
  Serial.print(" passed, ");
  Serial.print(fails);
  Serial.println(" failed");
  Serial.println("Some simple RAM testing");
  for (x = 0; x < 16; x++)
  {
    ram_write(x, x+0x55AAFF00);
  }
  Serial.println("Check memory write from CPU...");
  cpu_write_mem(1, 0xDEADBEEF);
  cpu_write_mem(2, 0xBEEFDEAD);
  for (x = 0; x < 16; x++)
  {
    y = ram_read(x);
    Serial.print("Data in location ");
    Serial.print(x, HEX);
    Serial.print(" is ");
    Serial.println(y, HEX);
  }
  Serial.println("Checking memory read from CPU...");
  for (x = 0; x < 16; x++)
  {
    y = cpu_read_mem(x);
    Serial.print("Data in location ");
    Serial.print(x, HEX);
    Serial.print(" is ");
    Serial.println(y, HEX);
  }
  Serial.println("All done.");
  while (1);
}
//-------------------------------------------------------------------------
//  Define some test functions
//
void print_flags(int flag)
{
  Serial.println((flag & ALU_FLAG_CARRY) ? "Carry" : "No Carry");
  Serial.println((flag & ALU_FLAG_SIGN) ? "Sign" : "No Sign");
  Serial.println((flag & ALU_FLAG_ZERO) ? "Zero" : "No Zero");
  Serial.println((flag & ALU_FLAG_ERROR) ? "Error" : "No Error");
}
//
//  Base+  Type  Use
//    0    R/W   Write data bits 7-0
//    1    R/W   Write data bits 15-8
//    2    R/W   Write data bits 23-16
//    3    R/W   Write data bits 31-24
//    4     RO   Read data bits 7-0
//    5     RO   Read data bits 15-8
//    6     RO   Read data bits 23-16
//    7     RO   Read data bits 31-24
//    8    R/W   Raddr 1 (bits 7-4) Raddr 2 (bits 3-0)
//    9    R/W   Raddr 3 (bits 7-4)
//   10    R/W   Waddr   (bits 3-0)
//   11    R/W   ALU function
//   12    R/W   ALU flags
//   13    R/W   Enables
//                 6 - Bus read request
//                 5 - Bus write request
//                 4 - Op2 select 1
//                 3 - Enable flags
//                 2 - Enable read
//                 1 - Enable write
//                 0 - Start state machine
//
//  Write to a CPU register using write port
void cpu_write_reg(int data, int addr)
{
  write_addr(CPU_ENABLES, CTRL_NONE);
  write_addr(CPU_WADDR, addr & 0xF);
  write_addr(CPU_WDATA1, data & 0xFF);
  write_addr(CPU_WDATA2, (data >> 8) & 0xFF);
  write_addr(CPU_WDATA3, (data >> 16) & 0xFF);
  write_addr(CPU_WDATA4, (data >> 24) & 0xFF);
  write_addr(CPU_ENABLES, CTRL_EN_WRITE);
  write_addr(CPU_ENABLES, CTRL_NONE);
}
//
//  Read from a CPU register using read port 3
int cpu_read_reg(int addr)
{
  int temp;

  write_addr(CPU_ENABLES, CTRL_NONE);
  write_addr(CPU_RADDR3, (addr & 0xF) << 4);
  write_addr(CPU_ENABLES, CTRL_EN_READ);
  temp = read_addr(CPU_RDATA1) & 0xFF;
  temp += (read_addr(CPU_RDATA2) & 0xFF) << 8;
  temp += (read_addr(CPU_RDATA3) & 0xFF) << 16;
  temp += (read_addr(CPU_RDATA4) & 0xFF) << 24;
  write_addr(CPU_ENABLES, CTRL_NONE);
  return temp;
}

void dump_cpu_reg()
{
  int x;
  int y;

  for (x = 0; x < 16; x++)
  {
    y = cpu_read_reg(x);
    Serial.print("CPU register ");
    Serial.print(x);
    Serial.print(" is ");
    Serial.println(y, HEX);
  }
}

void set_flags(int flags)
{
  write_addr(CPU_FLAGS, flags);
  write_addr(CPU_ENABLES, CTRL_EN_FLAGS);
  write_addr(CPU_ENABLES, CTRL_NONE);
}

void test_cpu_flags(int expected)
{
  int y;

  tests++;
  y = read_addr(CPU_FLAGS);
  if (y == expected)
  {
    Serial.println("Passed");
    passes++;
  }
  else
  {
    fails++;
    Serial.print("** FAILED ** Expected ");
    Serial.print(expected, HEX);
    Serial.print(" got ");
    Serial.println(y, HEX);
  }
}

void test_cpu(int op1, int op2, int func, int incdec, int expected,
  const char *name, int flg)
{
  int x;
  int y;

  tests++;
//
//  Write test data into CPU registers 0 and 1 and set the ALU
//  function.
//
  cpu_write_reg(op1, 0);
  cpu_write_reg(op2, 1);
  write_addr(CPU_ENABLES, CTRL_NONE);
  write_addr(CPU_RADDR12, ((0 & 0xF) << 4) | (1 & 0xF));
  write_addr(CPU_WADDR, 2 & 0xF);
  write_addr(CPU_FUNCT, func);
//
//  Send a pulse to start the state machine
//
  write_addr(CPU_ENABLES, incdec + CTRL_START);
  write_addr(CPU_ENABLES, CTRL_NONE);
//
//  Read the results from CPU register 2 and check the results.
//
  y = cpu_read_reg(2);
  if (y == expected)
  {
    Serial.print(name);
    Serial.print(" passed");
    passes++;
  }
  else
  {
    fails++;
    Serial.print(name);
    Serial.print(" FAILED - expected ");
    Serial.print(expected);
    Serial.print(", got ");
    Serial.print(y);
    Serial.print(" (");
    Serial.print(y, HEX);
    Serial.print(")");
  }
  Serial.print(", Flags ");
  test_cpu_flags(flg);
}
//
//  Test that incrementing or decrementing a register works properly.
//  Dir is used to indicate the direction > 0 increments, otherwise
//  decrement.
//
void test_incdec(int reg, int dir)
{
  int old_value;
  int new_value;

  tests++;
  write_addr(CPU_ENABLES, CTRL_NONE);
  old_value = cpu_read_reg(reg);
  Serial.print("Register ");
  Serial.print(reg, HEX);
  Serial.print(", old value: ");
  Serial.print(old_value, HEX);
  write_addr(CPU_RADDR12, ((reg & 0xF) << 4) | (reg & 0xF));
  write_addr(CPU_WADDR, reg & 0xF);
  if (dir > 0)
  {
    write_addr(CPU_FUNCT, ALU_OP_ADD);
  }
  else
  {
    write_addr(CPU_FUNCT, ALU_OP_SUB);
  }
  write_addr(CPU_ENABLES, CTRL_OP2_1 + CTRL_START);
  write_addr(CPU_ENABLES, CTRL_NONE);
  new_value = cpu_read_reg(reg);
  Serial.print(", new value ");
  Serial.print(new_value, HEX);
  if (dir > 0)
  {
    if (new_value == (old_value + 1))
    {
      Serial.println("  Pass");
      passes++;
    }
    else
    {
      Serial.println("  FAIL!");
      fails++;
    }
  }
  else
  {
    if (new_value == (old_value - 1))
    {
      Serial.println("  Pass");
      passes++;
    }
    else
    {
      Serial.println("  FAIL!");
      fails++;
    }
  }
}

void cpu_write_mem(int addr, int data)
{
  write_addr(CPU_ENABLES, CTRL_NONE);
  cpu_write_reg(data, 0);  //  Register 0 holds data
  cpu_write_reg(addr, 1);  //  Register 1 holds address
  write_addr(CPU_RADDR12, ((0 & 0xF) << 4) | (1 & 0xF));
  write_addr(CPU_ENABLES, CTRL_MEM_WRITE);
  write_addr(CPU_ENABLES, CTRL_NONE);
}

int cpu_read_mem(int addr)
{
  int y = 0;
  write_addr(CPU_ENABLES, CTRL_NONE);
  y = read_addr(CPU_WADDR);
  Serial.print("Mem Read starting state ");
  Serial.print(y >> 4, HEX);
  cpu_write_reg(addr, 1);  //  Register 1 holds address
  write_addr(CPU_RADDR12, (1 & 0xF));
  write_addr(CPU_ENABLES, CTRL_MEM_READ);
  write_addr(CPU_ENABLES, CTRL_NONE);
  y = read_addr(CPU_WADDR);
  Serial.print(", ending state ");
  Serial.println(y >> 4, HEX);
  return cpu_read_reg(0);
}

///////////////////////////////////////////////////////
//
//  Define some functions to access the FPGA RAM block
//
//  Base+  Type  Use
//    0    R/W   Write data bits 7-0
//    1    R/W   Write data bits 15-8
//    2    R/W   Write data bits 23-16
//    3    R/W   Write data bits 31-24
//    4     RO   Read data bits 7-0
//    5     RO   Read data bits 15-8
//    6     RO   Read data bits 23-16
//    7     RO   Read data bits 31-24
//    8    R/W   Addr LSB (7-0)
//    9    R/W   Addr MSB (9-8)
//                 4 - Enable read
//                 3 - Enable write
//                 2 - Clock
//                 1 - Addr bit 9
//                 0 - Addr bit 8
void ram_write(int addr, int data)
{
  int temp;
  write_addr(RAM_ADDR2, 0);
  write_addr(RAM_WDATA1, data & 0xFF);
  write_addr(RAM_WDATA2, (data >> 8) & 0xFF);
  write_addr(RAM_WDATA3, (data >> 16) & 0xFF);
  write_addr(RAM_WDATA4, (data >> 24) & 0xFF);
  write_addr(RAM_ADDR1, addr & 0xFF);
  write_addr(RAM_ADDR2, ((addr >> 8) & 0x03) | 0 | 8);
  write_addr(RAM_ADDR2, ((addr >> 8) & 0x03) | 4 | 8);
  write_addr(RAM_ADDR2, ((addr >> 8) & 0x03) | 0 | 8);
  write_addr(RAM_ADDR2, 0);
  temp = read_addr(RAM_WDATA1) & 0xFF;
  temp += (read_addr(RAM_WDATA2) & 0xFF) << 8;
  temp += (read_addr(RAM_WDATA3) & 0xFF) << 16;
  temp += (read_addr(RAM_WDATA4) & 0xFF) << 24;
  Serial.print("Wrote ");
  Serial.print(temp, HEX);
  Serial.print(" to address ");
  Serial.println(addr, HEX);
}

int ram_read(int addr)
{
  int temp;

  write_addr(RAM_ADDR2, 0);
  write_addr(RAM_ADDR1, addr & 0xFF);
  write_addr(RAM_ADDR2, ((addr >> 8) & 0x03) | 0 | 16);
  write_addr(RAM_ADDR2, ((addr >> 8) & 0x03) | 4 | 16);
  write_addr(RAM_ADDR2, ((addr >> 8) & 0x03) | 0 | 16);
  temp = read_addr(RAM_RDATA1) & 0xFF;
  temp += (read_addr(RAM_RDATA2) & 0xFF) << 8;
  temp += (read_addr(RAM_RDATA3) & 0xFF) << 16;
  temp += (read_addr(RAM_RDATA4) & 0xFF) << 24;
  write_addr(RAM_ADDR2, 0);
  return temp;
}
}
