//
//  Constants used by sketch.  They are moved here just for organization
//  purposes and to shrink the size of the sketch file.
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
const int ALU_FLAG_NONE  =  0;
const int ALU_FLAG_CARRY =  1;
const int ALU_FLAG_SIGN  =  2;
const int ALU_FLAG_ZERO  =  4;
const int ALU_FLAG_ERROR =  8;
const int ALU_FLAG_BUSER = 16;
//
//  Control enables
const int CTRL_NONE      =  0;
const int CTRL_START     =  1;
const int CTRL_EN_WRITE  =  2;
const int CTRL_EN_READ   =  4;
const int CTRL_EN_FLAGS  =  8;
const int CTRL_OP2_1     = 16;
const int CTRL_MEM_WRITE = 32;
const int CTRL_MEM_READ  = 64;
//
//  ** NOTE: It appears that constants with a computed value can't be used
//           in .c files.
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
const int CPU_WADDR   = CPU_BASE + 10;
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
const int RAM_CDATA1 = RAM_BASE + 10;
const int RAM_CDATA2 = RAM_BASE + 11;
const int RAM_CDATA3 = RAM_BASE + 12;
const int RAM_CDATA4 = RAM_BASE + 13;
const int RAM_CADDR1 = RAM_BASE + 14;
const int RAM_CADDR2 = RAM_BASE + 15;
const int RAM_CADDR3 = RAM_BASE + 16;
const int RAM_CADDR4 = RAM_BASE + 17;
