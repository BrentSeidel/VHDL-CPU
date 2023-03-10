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
const int REG_WRITE  = 15;
const int REG_READ   = 16;
const int SLOW_CLOCK = 17;
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
const int ALU_OP_ERR = 255;  //  Unassigned code causes an error
//
//  ALU Flags
const int ALU_FLAG_CARRY =  1;
const int ALU_FLAG_SIGN  =  2;
const int ALU_FLAG_ZERO  =  4;
const int ALU_FLAG_ERROR =  8;
const int ALU_FLAG_BUSER = 16;
//
//  Control enables
const int CTRL_NONE     =  0;
const int CTRL_START    =  1;
const int CTRL_EN_WRITE =  2;
const int CTRL_EN_READ  =  4;
const int CTRL_EN_FLAGS =  8;
const int CTRL_OP2_1    = 16;
//
//  Counter registers
const int COUNT_LSB = 0;
const int COUNT_MSB = COUNT_LSB + 1;
//
//  CPU Control Registers
const int CPU_BASE    = COUNT_LSB + 2;
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
//  RAM Control Registers
const int RAM_BASE = CPU_BASE + 14;
const int RAM_WDATA1 = RAM_BASE;
const int RAM_WDATA2 = RAM_BASE + 1;
const int RAM_WDATA3 = RAM_BASE + 2;
const int RAM_WDATA4 = RAM_BASE + 3;
const int RAM_RDATA1 = RAM_BASE + 4;
const int RAM_RDATA2 = RAM_BASE + 5;
const int RAM_RDATA3 = RAM_BASE + 6;
const int RAM_RDATA4 = RAM_BASE + 7;
const int RAM_ADDR1  = RAM_BASE + 8;
const int RAM_ADDR2  = RAM_BASE + 9;
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
void test_cpu_flags(int expected);
void print_flags(int flag);
void cpu_write_reg(int data, int addr);
int cpu_read_reg(int addr);
void dump_cpu_reg();
void set_flags(int flags);
void test_cpu(int op1, int op2, int func, int expected,
              const char *name, int flg);
void test_incdec(int reg, int dir);
void ram_write(int addr, int data);
int ram_read(int addr);

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
  write_addr(CPU_WADDR12, 0);
  write_addr(CPU_FLAGS, 0);
  //
  //  Test CPU registers
  for (x = 0; x < 16; x++)
  {
    cpu_write_reg(x+0xFF00, x);
  }
  dump_cpu_reg();
  //
  //  Start CPU tests
  Serial.println("Starting CPU tests.");
  test_cpu(1, 2, ALU_OP_ERR, CTRL_NONE, 0, "Error", ALU_FLAG_ERROR + ALU_FLAG_ZERO);
  set_flags(0);
  test_cpu(31, 20, ALU_OP_ADD, CTRL_NONE, 51, "31 ADD 20", 0);
  test_cpu(21, 40, ALU_OP_ADD, CTRL_NONE, 61, "21 ADD 40", 0);
  test_cpu(0xFFFF, 1, ALU_OP_ADD, CTRL_NONE, 0x10000, "FFFF ADD 1", 0);
  test_cpu(0x7FFF, 1, ALU_OP_ADD, CTRL_NONE, 0x8000, "7FFF ADD 1", 0);
  //
  test_cpu(31, 20, ALU_OP_SUB, CTRL_NONE, 11, "31 SUB 20", 0);
  test_cpu(20, 31, ALU_OP_SUB, CTRL_NONE, -11, "20 SUB 31",
           ALU_FLAG_SIGN + ALU_FLAG_CARRY);
  //
  test_cpu(127, 0, ALU_OP_NOT, CTRL_NONE, -128, "127 NOT", ALU_FLAG_SIGN);
  test_cpu(1, 123, ALU_OP_NOT, CTRL_NONE, -2, "1 NOT", ALU_FLAG_SIGN);
  //
  test_cpu(15, 13, ALU_OP_AND, CTRL_NONE, 13, "15 AND 13", 0);
  test_cpu(16, 15, ALU_OP_AND, CTRL_NONE, 0, "16 AND 15", ALU_FLAG_ZERO);
  //
  test_cpu(16, 15, ALU_OP_OR, CTRL_NONE, 31, "16 OR 15", 0);
  test_cpu(15, 13, ALU_OP_OR, CTRL_NONE, 15, "15 OR 13", 0);
  //
  test_cpu(5, 15, ALU_OP_XOR, CTRL_NONE, 10, "5 XOR 15", 0);
  test_cpu(255, 254, ALU_OP_XOR, CTRL_NONE, 1, "255 XOR 254", 0);
  test_cpu(123, 123, ALU_OP_XOR, CTRL_NONE, 0, "123 XOR 123", ALU_FLAG_ZERO);
  //
  test_cpu(0, 0, ALU_OP_TST, CTRL_NONE, 0, "0 TST", ALU_FLAG_ZERO);
  test_cpu(1, 0, ALU_OP_TST, CTRL_NONE, 1, "1 TST", 0);
  test_cpu(2, 0, ALU_OP_TST, CTRL_NONE, 2, "2 TST", 0);
  test_cpu(4, 0, ALU_OP_TST, CTRL_NONE, 4, "4 TST", 0);
  test_cpu(8, 0, ALU_OP_TST, CTRL_NONE, 8, "8 TST", 0);
  test_cpu(16, 0, ALU_OP_TST, CTRL_NONE, 16, "16 TST", 0);
  test_cpu(32, 0, ALU_OP_TST, CTRL_NONE, 32, "32 TST", 0);
  test_cpu(64, 0, ALU_OP_TST, CTRL_NONE, 64, "64 TST", 0);
  test_cpu(128, 0, ALU_OP_TST, CTRL_NONE, 128, "128 TST", 0);
  test_cpu(0x100, 0, ALU_OP_TST, CTRL_NONE, 0x100, "0x100 TST", 0);
  test_cpu(0x200, 0, ALU_OP_TST, CTRL_NONE, 0x200, "0x200 TST", 0);
  test_cpu(0x400, 0, ALU_OP_TST, CTRL_NONE, 0x400, "0x400 TST", 0);
  test_cpu(0x800, 0, ALU_OP_TST, CTRL_NONE, 0x800, "0x800 TST", 0);
  test_cpu(0x1000, 0, ALU_OP_TST, CTRL_NONE, 0x1000, "0x1000 TST", 0);
  test_cpu(0x2000, 0, ALU_OP_TST, CTRL_NONE, 0x2000, "0x2000 TST", 0);
  test_cpu(0x4000, 0, ALU_OP_TST, CTRL_NONE, 0x4000, "0x4000 TST", 0);
  test_cpu(0x8000, 0, ALU_OP_TST, CTRL_NONE, 0x8000, "0x8000 TST", 0);
  test_cpu(0x10000, 0, ALU_OP_TST, CTRL_NONE, 0x10000, "0x10000 TST", 0);
  test_cpu(0x20000, 0, ALU_OP_TST, CTRL_NONE, 0x20000, "0x20000 TST", 0);
  test_cpu(0x40000, 0, ALU_OP_TST, CTRL_NONE, 0x40000, "0x40000 TST", 0);
  test_cpu(0x80000, 0, ALU_OP_TST, CTRL_NONE, 0x80000, "0x80000 TST", 0);
  test_cpu(0x100000, 0, ALU_OP_TST, CTRL_NONE, 0x100000, "0x100000 TST", 0);
  test_cpu(0x200000, 0, ALU_OP_TST, CTRL_NONE, 0x200000, "0x200000 TST", 0);
  test_cpu(0x400000, 0, ALU_OP_TST, CTRL_NONE, 0x400000, "0x400000 TST", 0);
  test_cpu(0x800000, 0, ALU_OP_TST, CTRL_NONE, 0x800000, "0x800000 TST", 0);
  test_cpu(0x1000000, 0, ALU_OP_TST, CTRL_NONE, 0x1000000, "0x1000000 TST", 0);
  test_cpu(0x2000000, 0, ALU_OP_TST, CTRL_NONE, 0x2000000, "0x2000000 TST", 0);
  test_cpu(0x4000000, 0, ALU_OP_TST, CTRL_NONE, 0x4000000, "0x4000000 TST", 0);
  test_cpu(0x8000000, 0, ALU_OP_TST, CTRL_NONE, 0x8000000, "0x8000000 TST", 0);
  test_cpu(0x10000000, 0, ALU_OP_TST, CTRL_NONE, 0x10000000, "0x10000000 TST", 0);
  test_cpu(0x20000000, 0, ALU_OP_TST, CTRL_NONE, 0x20000000, "0x20000000 TST", 0);
  test_cpu(0x40000000, 0, ALU_OP_TST, CTRL_NONE, 0x40000000, "0x40000000 TST", 0);
  test_cpu(0x80000000, 0, ALU_OP_TST, CTRL_NONE, 0x80000000, "0x80000000 TST", ALU_FLAG_SIGN);
  test_cpu(0xFFFFFFFF, 0, ALU_OP_TST, CTRL_NONE, 0xFFFFFFFF, "0xFFFFFFFF TST", ALU_FLAG_SIGN);
  test_cpu(255, 0, ALU_OP_TST, CTRL_NONE, 255, "255 TST", 0);
  test_cpu(127, 0, ALU_OP_TST, CTRL_NONE, 127, "127 TST", 0);
  test_cpu(0, 255, ALU_OP_TST, CTRL_NONE, 0, "0 TST", ALU_FLAG_ZERO);
  test_cpu(0xFFFF, 0, ALU_OP_TST, CTRL_NONE, 0xFFFF, "0xFFFF TST", 0);
  test_cpu(0x80000000, 0, ALU_OP_TST, CTRL_NONE, 0x80000000, "128 TST", ALU_FLAG_SIGN);
  test_cpu(0xFFFFFFFF, 0, ALU_OP_TST, CTRL_NONE, 0xFFFFFFFF, "0xFFFFFFFF TST", ALU_FLAG_SIGN);
  //
  test_cpu(255, 0, ALU_OP_NEG, CTRL_NONE, -255, "255 NEG", ALU_FLAG_SIGN);
  test_cpu(127, 255, ALU_OP_NEG, CTRL_NONE, -127, "127 NEG", ALU_FLAG_SIGN);
  test_cpu(-127, 255, ALU_OP_NEG, CTRL_NONE, 127, "-127 NEG", 0);
  //
  test_cpu(100, 10, ALU_OP_ADC, CTRL_NONE, 110, "100 ADC 10", 0);
  set_flags(ALU_FLAG_CARRY);
  test_cpu(100, 10, ALU_OP_ADC, CTRL_NONE, 111, "100 ADC 10", 0);
  //
  set_flags(0);
  test_cpu(100, 10, ALU_OP_SBC, CTRL_NONE, 90, "100 SBC 10", 0);
  set_flags(ALU_FLAG_CARRY);
  test_cpu(100, 10, ALU_OP_SBC, CTRL_NONE, 89, "100 SBC 10", 0);
  //
  test_cpu(1, 0, ALU_OP_SHL, CTRL_NONE, 1, "1 SHL 0", 0);
  test_cpu(1, 1, ALU_OP_SHL, CTRL_NONE, 2, "1 SHL 1", 0);
  test_cpu(1, 3, ALU_OP_SHL, CTRL_NONE, 8, "1 SHL 3", 0);
  test_cpu(1, 31, ALU_OP_SHL, CTRL_NONE, 0x80000000, "1 SHL 31", ALU_FLAG_SIGN);
  test_cpu(1, 32, ALU_OP_SHL, CTRL_NONE, 0, "1 SHL 32",
           ALU_FLAG_ZERO + ALU_FLAG_CARRY);
  //
  test_cpu(0x80000000, 0, ALU_OP_SHR, CTRL_NONE, 0x80000000, "0x80000000 SHR 0", ALU_FLAG_SIGN);
  test_cpu(0x80000000, 1, ALU_OP_SHR, CTRL_NONE, 0x40000000, "0x80000000 SHR 1", 0);
  test_cpu(0x80000000, 3, ALU_OP_SHR, CTRL_NONE, 0x10000000, "0x80000000 SHR 3", 0);
  test_cpu(0x80000000, 31, ALU_OP_SHR, CTRL_NONE, 1, "0x80000000 SHR 31", 0);
  test_cpu(0x80000000, 32, ALU_OP_SHR, CTRL_NONE, 0, "0x80000000 SHR 32", ALU_FLAG_ZERO);
//
//  Test increment and decrement
//
  test_cpu(31, 20, ALU_OP_ADD, CTRL_OP2_1, 32, "31 ADD 1", 0);
  test_cpu(21, 40, ALU_OP_ADD, CTRL_OP2_1, 22, "21 ADD 1", 0);
  test_cpu(31, 20, ALU_OP_SUB, CTRL_OP2_1, 30, "31 SUB 1", 0);
  test_cpu(20, 31, ALU_OP_SUB, CTRL_OP2_1, 19, "20 SUB 1", 0);
  test_incdec(3, 1);
  test_incdec(15, 1);
  test_incdec(3, -1);
  test_incdec(14, -1);
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
    ram_write(x, x+0xF00);
  }
  for (x = 0; x < 16; x++)
  {
    y = ram_read(x);
    Serial.print("Data in location ");
    Serial.print(x, HEX);
    Serial.print(" is ");
    Serial.print(y, HEX);
    if (y == (x + 0xF00))
    {
      Serial.println("  Pass");
    }
    else
    {
      Serial.println("  FAIL!");
    }
  }
  while (1);
}
//
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
  write_addr(CPU_WADDR12, addr & 0xF);
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
  write_addr(CPU_WADDR12, 2 & 0xF);
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

void test_incdec(int reg, int dir)
{
  int old_value;
  int new_value;

  tests++;
  write_addr(CPU_ENABLES, CTRL_NONE);
  old_value = cpu_read_reg(reg);
  Serial.print("Old value: ");
  Serial.print(old_value, HEX);
  write_addr(CPU_RADDR12, ((reg & 0xF) << 4) | (reg & 0xF));
  write_addr(CPU_WADDR12, reg & 0xF);
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
