//
//  Based on the program available here: https://content.arduino.cc/assets/SketchVidorFPGA.zip
//  defines.h, jtag.c, and jtag.h are from that archive.  app.h is generated from the .ttf file
//  using the vidorcvt program.  I have modified sketch.ino for this demo.
//
#include <wiring_private.h>
#include "jtag.h"
#include "defines.h"

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
const int REG_WRITE = 15;
const int REG_READ  = 16;
//
//  Number of registers to check
const int REG_NUM = 15;
//
//  ALU Registers
const int ALU_BASE   = 0;
const int ALU_OP1    = ALU_BASE;
const int ALU_OP2    = ALU_BASE + 1;
const int ALU_FUNC   = ALU_BASE + 2;
const int ALU_FLAGS  = ALU_BASE + 3;
const int ALU_RESULT = ALU_BASE + 4;
//
//  ALU Operations
const int ALU_OP_NULL = 0;
const int ALU_OP_ADD = 1;
const int ALU_OP_SUB = 2;
const int ALU_OP_NOT = 3;
const int ALU_OP_AND = 4;
const int ALU_OP_OR  = 5;
const int ALU_OP_XOR = 6;
const int ALU_OP_TST = 7;
const int ALU_OP_NEG = 8;
const int ALU_OP_ADC = 9;
const int ALU_OP_SBC = 10;
const int ALU_OP_SHL = 11;
const int ALU_OP_SHR = 12;
//
//  ALU Flags
const int ALU_FLAG_CARRY = 1;
const int ALU_FLAG_SIGN  = 2;
const int ALU_FLAG_ZERO  = 4;
const int ALU_FLAG_ERROR = 8;
//
//  Counter registers
const int COUNT_LSB = ALU_BASE + 5;
const int COUNT_MSB = COUNT_LSB + 1;
//
//  CPU control registers
const int CPU_BASE = COUNT_LSB + 2;
const int CPU_WDATA1  = CPU_BASE;
const int CPU_WDATA2  = CPU_BASE + 1;
const int CPU_WDATA3  = CPU_BASE + 2;
const int CPU_WDATA4  = CPU_BASE + 3;
const int CPU_RDATA1  = CPU_BASE + 4;
const int CPU_RDATA2  = CPU_BASE + 5;
const int CPU_RDATA3  = CPU_BASE + 6;
const int CPU_RDATA4  = CPU_BASE + 7;
const int CPU_RADDR12 = CPU_BASE + 8;
const int CPU_RADDR3  = CPU_BASE + 9;
const int CPU_WADDR12 = CPU_BASE + 10;
const int CPU_FUNCT   = CPU_BASE + 11;
const int CPU_FLAGS   = CPU_BASE + 12;
const int CPU_ENABLES = CPU_BASE + 13;
//
//  Global counters for test pass and fail
int tests  = 0;
int passes = 0;
int fails  = 0;
//
//  Define some functions.
void set_addr(int addr);
void write_data(int data);
int read_data();
void write_addr(int addr, int data);
int read_addr(int addr);
void test_alu(int op1, int op2, int func, int expected,
              const char *name, int flg);
void test_flag(int expected);
void print_flags(int flag);
void cpu_write_reg(int data, int addr);
int cpu_read_reg(int addr);
void dump_cpu_reg();
void cpu_operation(int reg1, int reg2, int reg3, int alu_op);

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

  Serial.println("FPGA and MCU started.");
}
//
//  Main processing loop
void loop()
{
  int x;
  int y;

  Serial.println("Testing ALU.");
  write_addr(ALU_FLAGS, 0);
  x = read_addr(ALU_FLAGS);
  test_alu(31, 20, ALU_OP_ADD, 51, "31 ADD 20", 0);
  test_alu(21, 40, ALU_OP_ADD, 61, "21 ADD 40", 0);
  //
  test_alu(31, 20, ALU_OP_SUB, 11, "31 SUB 20", 0);
  test_alu(20, 31, ALU_OP_SUB, 245, "20 SUB 31", ALU_FLAG_SIGN +
                                                 ALU_FLAG_CARRY);
  //
  test_alu(127, 0, ALU_OP_NOT, 128, "127 NOT", ALU_FLAG_SIGN);
  test_alu(1, 123, ALU_OP_NOT, 254, "1 NOT", ALU_FLAG_SIGN);
  //
  test_alu(15, 13, ALU_OP_AND, 13, "15 AND 13", 0);
  test_alu(16, 15, ALU_OP_AND, 0, "16 AND 15", ALU_FLAG_ZERO);
  //
  test_alu(16, 15, ALU_OP_OR, 31, "16 OR 15", 0);
  test_alu(15, 13, ALU_OP_OR, 15, "15 OR 13", 0);
  //
  test_alu(5, 15, ALU_OP_XOR, 10, "5 XOR 15", 0);
  test_alu(255, 254, ALU_OP_XOR, 1, "255 XOR 254", 0);
  test_alu(123, 123, ALU_OP_XOR, 0, "123 XOR 123", ALU_FLAG_ZERO);
  //
  test_alu(255, 0, ALU_OP_TST, 255, "255 TST", ALU_FLAG_SIGN);
  test_alu(128, 0, ALU_OP_TST, 128, "128 TST", ALU_FLAG_SIGN);
  test_alu(127, 0, ALU_OP_TST, 127, "127 TST", 0);
  test_alu(0, 255, ALU_OP_TST, 0, "0 TST", ALU_FLAG_ZERO);
  //
  test_alu(255, 0, ALU_OP_NEG, 1, "255 NEG", 0);
  test_alu(127, 255, ALU_OP_NEG, 129, "127 NEG", ALU_FLAG_SIGN);
  //
  test_alu(100, 10, ALU_OP_ADC, 110, "100 ADC 10", 0);
  write_addr(ALU_FLAGS, ALU_FLAG_CARRY);
  test_alu(100, 10, ALU_OP_ADC, 111, "100 ADC 10", 0);
  //
  write_addr(ALU_FLAGS, 0);
  test_alu(100, 10, ALU_OP_SBC, 90, "100 SBC 10", 0);
  write_addr(ALU_FLAGS, ALU_FLAG_CARRY);
  test_alu(100, 10, ALU_OP_SBC, 89, "100 SBC 10", 0);
  //
  test_alu(1, 0, ALU_OP_SHL, 1, "1 SHL 0", 0);
  test_alu(1, 1, ALU_OP_SHL, 2, "1 SHL 1", 0);
  test_alu(1, 3, ALU_OP_SHL, 8, "1 SHL 3", 0);
  test_alu(1, 7, ALU_OP_SHL, 128, "1 SHL 7", ALU_FLAG_SIGN);
  test_alu(1, 8, ALU_OP_SHL, 0, "1 SHL 8", ALU_FLAG_ZERO +
                                           ALU_FLAG_CARRY);
  //
  test_alu(128, 0, ALU_OP_SHR, 128, "128 SHR 0", ALU_FLAG_SIGN);
  test_alu(128, 1, ALU_OP_SHR, 64, "128 SHR 1", 0);
  test_alu(128, 3, ALU_OP_SHR, 16, "128 SHR 3", 0);
  test_alu(128, 7, ALU_OP_SHR, 1, "128 SHR 7", 0);
  test_alu(128, 8, ALU_OP_SHR, 0, "128 SHR 8", ALU_FLAG_ZERO);
  //
  Serial.println();
  Serial.print(tests);
  Serial.print(" tests, ");
  Serial.print(passes);
  Serial.print(" passed, ");
  Serial.print(fails);
  Serial.println(" failed");
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
  write_addr(CPU_WADDR12, 0);
  //
  //  Test CPU registers
  for (x = 0; x < 16; x++)
  {
    cpu_write_reg(x+0x100, x);
  }
  dump_cpu_reg();
  //
  //  Start CPU tests
  Serial.println("Starting CPU tests.");
  cpu_operation(0, 1, 2, ALU_OP_ADD);
  cpu_operation(0, 5, 3, ALU_OP_SUB);
  cpu_operation(0, 1, 4, ALU_OP_NOT);
  cpu_operation(15, 15, 15, ALU_OP_XOR);
  cpu_operation(0, 1, 0, ALU_OP_ADD);
  dump_cpu_reg();
  Serial.println("End of CPU tests.");
  while (1);
}
//
//  Define some test functions
//
void test_flag(int expected)
{
  int y;

  tests++;
  y = read_addr(ALU_FLAGS);
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

void print_flags(int flag)
{
  Serial.println((flag & ALU_FLAG_CARRY) ? "Carry" : "No Carry");
  Serial.println((flag & ALU_FLAG_SIGN) ? "Sign" : "No Sign");
  Serial.println((flag & ALU_FLAG_ZERO) ? "Zero" : "No Zero");
  Serial.println((flag & ALU_FLAG_ERROR) ? "Error" : "No Error");
}

void test_alu(int op1, int op2, int func, int expected,
  const char *name, int flg)
{
  int y;

  tests++;
  write_addr(ALU_OP1, op1);
  write_addr(ALU_OP2, op2);
  write_addr(ALU_FUNC, func);
  y = read_addr(ALU_RESULT);
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
  }
  Serial.print(", Flags ");
  test_flag(flg);
}
//--  Base+  Type  Use
//--    0    R/W   Write data bits 7-0
//--    1    R/W   Write data bits 15-8
//--    2    R/W   Write data bits 23-16
//--    3    R/W   Write data bits 31-24
//--    4     RO   Read data bits 7-0
//--    5     RO   Read data bits 15-8
//--    6     RO   Read data bits 23-16
//--    7     RO   Read data bits 31-24
//--    8    R/W   Raddr 1 (bits 7-4) Raddr 2 (bits 3-0)
//--    9    R/W   Raddr 3 (bits 7-4)
//--   10    R/W   Waddr   (bits 3-0)
//--   11    R/W   ALU function
//--   12    R/W   ALU flags
//--   13    R/W   Enables
//--                 7 - Renable 3
//--                 6 - Renable 2
//--                 5 - Renable 1
//--                 1 - Wenable 2
//--                 0 - Wenable 1
//const int CPU_WDATA1  = CPU_BASE;
//const int CPU_WDATA2  = CPU_BASE + 1;
//const int CPU_WDATA3  = CPU_BASE + 2;
//const int CPU_WDATA4  = CPU_BASE + 3;
//const int CPU_RDATA1  = CPU_BASE + 4;
//const int CPU_RDATA2  = CPU_BASE + 5;
//const int CPU_RDATA3  = CPU_BASE + 6;
//const int CPU_RDATA4  = CPU_BASE + 7;
//const int CPU_RADDR12 = CPU_BASE + 8;
//const int CPU_RADDR3  = CPU_BASE + 9;
//const int CPU_WADDR12 = CPU_BASE + 10;
//const int CPU_FUNCT   = CPU_BASE + 11;
//const int CPU_FLAGS   = CPU_BASE + 12;
//const int CPU_ENABLES = CPU_BASE + 13;
//
//  Write to a CPU register using write port 2
void cpu_write_reg(int data, int addr)
{
  int temp;
  write_addr(CPU_ENABLES, 0);
  write_addr(CPU_WADDR12, addr & 0xF);
  Serial.print("Writing ");
  Serial.print(data, HEX);
  Serial.print(" to register ");
  Serial.println(addr);
  write_addr(CPU_WDATA1, data & 0xFF);
  write_addr(CPU_WDATA2, (data >> 8) & 0xFF);
  write_addr(CPU_WDATA3, (data >> 16) & 0xFF);
  write_addr(CPU_WDATA4, (data >> 24) & 0xFF);
  write_addr(CPU_ENABLES, 1 << 1);
  write_addr(CPU_ENABLES, 0);
}
//
//  Read from a CPU register using read port 3
int cpu_read_reg(int addr)
{
  int temp;

  write_addr(CPU_ENABLES, 0);
  write_addr(CPU_RADDR3, (addr & 0xF) << 4);
  write_addr(CPU_ENABLES, 1 << 7);
  temp = read_addr(CPU_RDATA1) & 0xFF;
  temp += (read_addr(CPU_RDATA2) & 0xFF) << 8;
  temp += (read_addr(CPU_RDATA3) & 0xFF) << 16;
  temp += (read_addr(CPU_RDATA4) & 0xFF) << 24;
  write_addr(CPU_ENABLES, 0);
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

void cpu_operation(int reg1, int reg2, int reg3, int alu_op)
{
  write_addr(CPU_ENABLES, 0);
  write_addr(CPU_WDATA1, 0);
  write_addr(CPU_WDATA2, 0);
  write_addr(CPU_WDATA3, 0);
  write_addr(CPU_WDATA4, 0);
  write_addr(CPU_RADDR12, ((reg1 & 0xF) << 4) | (reg2 & 0xF));
  write_addr(CPU_WADDR12, reg3 & 0xF);
  write_addr(CPU_FUNCT, alu_op);
  write_addr(CPU_ENABLES, (1 << 6) | (1 << 5));
  write_addr(CPU_ENABLES, 1);
  write_addr(CPU_ENABLES, 0);
}

///////////////////////////////////////////////////////
//
//  Define some functions to access the CPU-FPGA bus.
void set_addr(int addr)
{
  int x;
  int y = addr;

  for (x = ADDR_LSB; x <= ADDR_MSB; x++)
  {
    pinMode(x, OUTPUT);
    digitalWrite(x, y & 1);
    y = y >> 1;
  }
}

void write_data(int data)
{
  int x;
  int y;

  y = data;
  digitalWrite(REG_WRITE, false);
  digitalWrite(REG_READ, false);
  for (x = DATA_LSB; x <= DATA_MSB; x++)
  {
    pinMode(x, OUTPUT);
    digitalWrite(x, y & 1);
    y = y >> 1;
  }
  digitalWrite(REG_WRITE, true);
  digitalWrite(REG_WRITE, false);
  for (x = DATA_LSB; x <= DATA_MSB; x++)
  {
    digitalWrite(x, false);
    pinMode(x, INPUT);
  }
}

int read_data()
{
  int x;
  int y = 0;
  int d;

  digitalWrite(REG_WRITE, false);
  digitalWrite(REG_READ, false);
  for (x = DATA_LSB; x <= DATA_MSB; x++)
  {
    pinMode(x, INPUT);
  }
  digitalWrite(REG_READ, true);
  for (x = DATA_MSB; x >= DATA_LSB; x--)
  {
    d = digitalRead(x);
    y = (y << 1) + d;
  }
  digitalWrite(REG_READ, false);
  return y;
}

void write_addr(int addr, int data)
{
  set_addr(addr);
  write_data(data);
}

int read_addr(int addr)
{
  set_addr(addr);
  return read_data();
}
