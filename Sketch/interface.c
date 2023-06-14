///////////////////////////////////////////////////////
//
//  Define some functions to access the CPU-FPGA bus.
#include <arduino.h>
#include "interface.h"
//#include "constants.h"
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
