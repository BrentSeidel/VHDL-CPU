--
--  This package contains common type definitions and related constants
--  and functions.
--
library ieee;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
use ieee.Numeric_Std.all;

package typedefs is
--
--  Define some types
--
  subtype byte is integer range 0 to 255;
  type t_FLAGS is record
    carry : std_logic;  --  Carry/borrow was genererated during operation
	 sign  : std_logic;  --  Sign bit is set indicating negative value
	 zero  : std_logic;  --  Result is zero
	 error : std_logic;  --  An illegal ALU instruction was attempted since this bit was last cleared
  end record t_FLAGS;
  --
  --  Some conversion functions
  --
  function vec_to_byte(vec : in std_logic_vector) return byte;
  function byte_to_vec(data : in byte) return std_logic_vector;
  --
  function flags_to_vec(flag : in t_FLAGS) return std_logic_vector;
  function vec_to_flags(vec : in std_logic_vector) return t_FLAGS;
  --
  --  Some constants
  --
  constant ALU_OP_NULL : integer := 0;
  constant ALU_OP_ADD  : integer := 1;
  constant ALU_OP_SUB  : integer := 2;
  constant ALU_OP_NOT  : integer := 3;
  constant ALU_OP_AND  : integer := 4;
  constant ALU_OP_OR   : integer := 5;
  constant ALU_OP_XOR  : integer := 6;
  constant ALU_OP_TST  : integer := 7;
  constant ALU_OP_NEG  : integer := 8;
  constant ALU_OP_ADC  : integer := 9;  --  Add with carry
  constant ALU_OP_SBC  : integer := 10; --  Subtract with carry
end package;

package body typedefs is
  function vec_to_byte(vec : in std_logic_vector) return byte is
  begin
    return work.typedefs.byte(to_integer(unsigned(vec)));
  end;
  --
  function byte_to_vec(data : in byte) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(data, 8));
  end;
  --
  function flags_to_vec(flag : in t_FLAGS) return std_logic_vector is
    variable temp : std_logic_vector(7 downto 0) := (others => '0');
  begin
    temp(0) := flag.carry;
	 temp(1) := flag.sign;
	 temp(2) := flag.zero;
	 temp(3) := flag.error;
	 return temp;
  end;
  --
  function vec_to_flags(vec : in std_logic_vector) return t_FLAGS is
    variable temp : t_FLAGS := (others => '0');
  begin
    temp.carry := vec(0);
	 temp.sign  := vec(1);
	 temp.zero  := vec(2);
	 temp.error := vec(3);
    return temp;
  end;

end package body;