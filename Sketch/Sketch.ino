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
const int REG_NUM = 10;
//
//  ALU Registers
const int ALU_OP1 = 3;
const int ALU_OP2 = 4;
const int ALU_FUNC = 5;
const int ALU_FLAGS = 6;
const int ALU_RESULT = 7;
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
//
//  ALU Flags
const int ALU_FLAG_CARRY = 1;
const int ALU_FLAG_SIGN  = 2;
const int ALU_FLAG_ZERO  = 4;
const int ALU_FLAG_ERROR = 8;
//
//  Define expected results
const int results[] =
{10, 11, 12, 13, 14, 15, -1, -1,  8,  9, 10, 11, 12, 13, 14, 15,
 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
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
void test_reg(int addr, int expected);
void test_alu(int op1, int op2, int func, int expected,
  const char *name, int flg);
void test_flag(int expected);
void print_flags(int flag);

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

  Serial.println("Testing registers.");
  Serial.println("Writing values.");
  for (x = 0; x < REG_NUM; x++)
  {
    write_addr(x, x + 10);
    Serial.print("Wrote ");
    Serial.print(x + 10);
    Serial.print(" to register ");
    Serial.println(x);
  }
  Serial.println("Reading values.");
  for (x = 0; x < REG_NUM; x++)
  {
    test_reg(x, results[x]);
  }
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
  Serial.println();
  Serial.print(tests);
  Serial.print(" tests, ");
  Serial.print(passes);
  Serial.print(" passed, ");
  Serial.print(fails);
  Serial.println(" failed");
  while (1);
}
//
//  Define some test functions
//
void test_reg(int addr, int expected)
{
  int y;

  y = read_addr(addr);
  if (expected == -1)
  {
    Serial.print("Register ");
    Serial.print(addr);
    Serial.print(" value is don't care, read ");
    Serial.println(y);
  }
  else
  {
    tests++;
    Serial.print("Read ");
    Serial.print(y);
    Serial.print(" from register ");
    Serial.print(addr);
    if (y == expected)
    {
      Serial.println(" - Pass");
      passes++;
    }
    else
    {
      Serial.print(" - ** FAIL **, expected ");
      Serial.println(expected);
      fails++;
    }
  }
}

void test_flag(int expected)
{
  int y;

//  set_addr(ALU_FLAGS);
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
