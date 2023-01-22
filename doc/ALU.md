# ALU
The ALU is a 32-bit arithmatic-logic unit with two operand inputs
and one result output.  Also included are a flags input and output.

## Flags
Four flag bits are currently defined:
* carry  --  Carry/borrow was genererated during operation
* sign   --  Sign bit is set indicating negative value
* zero   --  Result is zero
* error  --  An illegal ALU instruction was attempted since this bit was last cleared

## Operations
The following operations are defined:
*  0 ALU_OP_NULL  --  No operation
*  1 ALU_OP_ADD   --  Add two numbers
*  2 ALU_OP_SUB   --  Subtract two numbers
*  3 ALU_OP_NOT   --  NOT of op 1.  Op 2 is ignored
*  4 ALU_OP_AND   --  Perform a logical AND of the two operands
*  5 ALU_OP_OR    --  Perform a logical OR of the two operands
*  6 ALU_OP_XOR   --  Perform a logical XOR of the two operands
*  7 ALU_OP_TST   --  Test op 1 and set flags.  Op 2 is ignored
*  8 ALU_OP_NEG   --  Negative of op 1.  Op 2 is ignored
*  9 ALU_OP_ADC   --  Add with carry
* 10 ALU_OP_SBC   --  Subtract with carry/borrow
* 11 ALU_OP_SHL   --  Shift left
* 12 ALU_OP_SHR   --  Shift right

Note that these operations may be renumbered and operations may be added or deleted.
