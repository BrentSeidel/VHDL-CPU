--
--  Define an ALU of generic size
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
--
--  Generic ALU entity
--
entity ALU is
  generic (size : natural);
  port (op1       : in std_logic_vector (size-1 downto 0);
        op2       : in std_logic_vector (size-1 downto 0);
        funct     : in work.typedefs.byte;
        result    : out std_logic_vector (size-1 downto 0);
        flags_in  : in work.typedefs.t_FLAGS;
        flags_out : out work.typedefs.t_FLAGS);
end entity ALU;

architecture rtl of ALU is
begin
  --
  --  In this process, variables t1 and t2 are used to be one bit bigger than
  --  op1 and op2.  This allows the MSB to be used as a carry/borrow bit for
  --  addition and subtraction.
  --
  process(op1, op2, funct, flags_in)
    constant ZERO : std_logic_vector (size-1 downto 0) := (others => '0');
    variable t1   : std_logic_vector (size downto 0);
    variable t2   : std_logic_vector (size downto 0);
    variable temp : std_logic_vector (size downto 0) := (others => '0');
	 variable flags_temp : work.typedefs.t_FLAGS;
  begin
    t1(size) := '0';
    t1(size-1 downto 0) := op1;
    t2(size) := '0';
    t2(size-1 downto 0) := op2;
    flags_temp := flags_in;
    case funct is
      when work.typedefs.ALU_OP_NULL =>  -- No operation
        temp := (others => '0');
      when work.typedefs.ALU_OP_ADD =>
        temp := t1 + t2;
      when work.typedefs.ALU_OP_ADC =>
        temp := t1 + t2 + flags_in.carry;
      when work.typedefs.ALU_OP_SUB =>
        temp := t1 - t2;
      when work.typedefs.ALU_OP_SBC =>
        temp := t1 - t2 - flags_in.carry;
      when work.typedefs.ALU_OP_NOT =>  --  NOT of op1.  Op2 is ignored
        temp := not t1;
        temp(size) := '0';
      when work.typedefs.ALU_OP_AND =>
        temp := t1 and t2;
      when work.typedefs.ALU_OP_OR =>
        temp := t1 or t2;
      when work.typedefs.ALU_OP_XOR =>
        temp := t1 xor t2;
      when work.typedefs.ALU_OP_TST =>  --  Test op1 and set flags.  Op2 is ignored
        temp := t1;
      when work.typedefs.ALU_OP_NEG =>  --  Negative of op1.  Op2 is ignored
        temp := ZERO - t1;
        temp(size) := '0';
		when work.typedefs.ALU_OP_SHL =>  --  Shift left
		  temp := std_logic_vector(shift_left(unsigned(t1), natural(to_integer(unsigned(t2)))));
		when work.typedefs.ALU_OP_SHR =>  --  Shift right
		  temp := std_logic_vector(shift_right(unsigned(t1), natural(to_integer(unsigned(t2)))));
      when others =>  --  This is an error condition with an unknown code
        flags_temp.alu_error := '1';
        temp := (others => '0');
    end case;
	 --
	 --  Update flags if not a NOP
	 --
	 if funct /= work.typedefs.ALU_OP_NULL then
      flags_temp.sign := temp(size-1);
      flags_temp.carry := temp(size);
      if unsigned(temp(size-1 downto 0)) = 0 then
        flags_temp.zero := '1';
      else
        flags_temp.zero := '0';
      end if;
      result <= temp(size-1 downto 0);
	 end if;
	 flags_out <= flags_temp;
  end process store;
end rtl;
