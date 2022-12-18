--
--  Define an ALU with registered inputs
--
library ieee;

use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
--
--  ALU entity.  This occupies a block of five registers starting
--  at a specified base address.
--
--  Base+  Type  Use
--    0    R/W   Operand 1
--    1    R/W   Operand 2
--    2    R/W   ALU Function
--    3    R/W   ALU Flags
--    4     RO   ALU Results
--
entity ALU8 is
  generic (location : work.typedefs.byte);
  port (data : inout std_logic_vector (7 downto 0);
        out_enable : in boolean;
		  set : in boolean;
		  addr : in work.typedefs.byte);
end entity ALU8;

architecture rtl of ALU8 is
  constant op1_addr  : work.typedefs.byte := location;
  constant op2_addr  : work.typedefs.byte := location + 1;
  constant func_addr : work.typedefs.byte := location + 2;
  constant flag_addr : work.typedefs.byte := location + 3;
  constant res_addr  : work.typedefs.byte := location + 4;
  signal op1_bus    : std_logic_vector (7 downto 0);
  signal op2_bus    : std_logic_vector (7 downto 0);
  signal results    : std_logic_vector (7 downto 0);
  signal func_value : work.typedefs.byte;
  signal flags_pre  : work.typedefs.t_FLAGS;
  signal flags_post : work.typedefs.t_FLAGS;
begin

  alu : work.alu
    generic map(size => 8)
	 port map(op1 => op1_bus, op2 => op2_bus, result => results,
	          funct => func_value, flags_in => flags_pre, flags_out => flags_post);
  --
  --  Register for operand 1
  --
  op1_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = op1_addr then
      if set then
	     saved := data;
		  op1_bus <= data;
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process op1_reg;
  --
  --  Register for operand 2
  --
  op2_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = op2_addr then
      if set then
	     saved := data;
		  op2_bus <= data;
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process op2_reg;
  --
  --  Register for ALU function
  --
  func_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = func_addr then
      if set then
	     saved := data;
		  func_value <= work.typedefs.vec_to_byte(data);
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process func_reg;
  --
  --  Register for flags.  Not really a register, though it looks like one.
  --  It writes flags to the ALU and reads flags from the ALU.
  --
  flag_reg : process(out_enable, set, addr, data)
  begin
	 if addr = flag_addr then
      if set then
		  flags_pre <= work.typedefs.vec_to_flags(data);
	   elsif out_enable then
	     data <= work.typedefs.flags_to_vec(flags_post);
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process flag_reg;
  --
  --  Register for results.  Not really a register, though it looks like one.
  --  Writes are discarded and reads return results from ALU.
  --
  res_reg : process(out_enable, set, addr, data)
  begin
	 if addr = res_addr then
	   if (not set) and out_enable then
	     data <= results;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process res_reg;

end rtl;

    