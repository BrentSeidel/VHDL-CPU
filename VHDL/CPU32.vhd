--
--  Define a 32 bit CPU with registered inputs for test purposes
--
library ieee;

use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
--
--  CPU entity.  This occupies a block of 14 registers starting
--  at a specified base address.
--
--  Base+  Type  Use
--    0    R/W   Write data bits 7-0
--    1    R/W   Write data bits 15-8
--    2    R/W   Write data bits 23-16
--    3    R/W   Write data bits 31-24
--    4     RO   Read data bits 7-0
--    5     RO   Read data bits 15-8
--    6     RO   Read data bits 23-16
--    7     RO   Read data bits 31-24
--    8    R/W   Raddr 1 (bits 7-4) Raddr 2 (bits 3-0)
--    9    R/W   Raddr 3 (bits 7-4)
--   10    R/W   Waddr (bits 3-0)
--   11    R/W   ALU function
--   12    R/W   ALU flags
--   13    R/W   Enables
--                 2 - Enable read
--                 1 - Enable write
--                 0 - Start state machine
--
entity CPU32 is
  generic (location : work.typedefs.byte);
  port (data : inout std_logic_vector (7 downto 0);
        out_enable : in boolean;
		  set : in boolean;
		  addr : in work.typedefs.byte;
		  clock : in std_logic);
end entity CPU32;

architecture rtl of CPU32 is
  constant Wdata1_addr  : work.typedefs.byte := location;
  constant Wdata2_addr  : work.typedefs.byte := location + 1;
  constant Wdata3_addr  : work.typedefs.byte := location + 2;
  constant Wdata4_addr  : work.typedefs.byte := location + 3;
  constant Rdata1_addr  : work.typedefs.byte := location + 4;
  constant Rdata2_addr  : work.typedefs.byte := location + 5;
  constant Rdata3_addr  : work.typedefs.byte := location + 6;
  constant Rdata4_addr  : work.typedefs.byte := location + 7;
  constant Raddr12_addr : work.typedefs.byte := location + 8;
  constant Raddr3_addr  : work.typedefs.byte := location + 9;
  constant Waddr_addr   : work.typedefs.byte := location + 10;
  constant funct_addr   : work.typedefs.byte := location + 11;
  constant flag_addr    : work.typedefs.byte := location + 12;
  constant enable_addr  : work.typedefs.byte := location + 13;
  constant count        : natural := 4;  --  Number of bits in register address
  constant size         : natural := 32; --  Number of bits in word
  signal read_bus       : std_logic_vector (size-1 downto 0);
  signal write_bus      : std_logic_vector (size-1 downto 0);
  signal raddr1         : natural range 0 to (2**count)-1;
  signal raddr2         : natural range 0 to (2**count)-1;
  signal raddr3         : natural range 0 to (2**count)-1;
  signal waddr          : natural range 0 to (2**count)-1;
  signal start          : std_logic;
  signal enable_read    : std_logic;
  signal enable_write   : std_logic;
  signal func_value     : work.typedefs.byte;
  signal flags_pre      : work.typedefs.t_FLAGS;
  signal flags_post     : work.typedefs.t_FLAGS;
  signal state          : std_logic_vector(3 downto 0);

begin
  cpu : work.cpu
  generic map (count => count, size => size)
  port map (
       clock => clock,
		 start => start,
		 state => state,
       r_addr1   => raddr1,     --  Read port 1
		 r_addr2   => raddr2,     --  Read port 2
		 r_addr3   => raddr3,     --  Read port 3
		 r_data3   => read_bus,
		 r_en3     => enable_read,
		 w_addr    => waddr,
		 w_data    => write_bus,
		 w_en2     => enable_write,
       funct     => func_value, --  ALU Function
       flags_in  => flags_pre,  --  ALU Flags in
       flags_out => flags_post);  --  ALU Flags out
  --
  --  Register for write data 1
  --
  wdata1_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = Wdata1_addr then
      if set then
	     saved := data;
		  write_bus(7 downto 0) <= data;
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process wdata1_reg;
  --
  --  Register for write data 2
  --
  wdata2_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = Wdata2_addr then
      if set then
	     saved := data;
		  write_bus(15 downto 8) <= data;
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process wdata2_reg;
  --
  --  Register for write data 3
  --
  wdata3_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = Wdata3_addr then
      if set then
	     saved := data;
		  write_bus(23 downto 16) <= data;
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process wdata3_reg;
  --
  --  Register for write data 4
  --
  wdata4_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = Wdata4_addr then
      if set then
	     saved := data;
		  write_bus(31 downto 24) <= data;
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process wdata4_reg;
  --
  --  Register for ALU function
  --
  func_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = funct_addr then
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
  flag_reg : process(out_enable, set, addr, data, flags_post)
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
  --  Register for read data 1.
  --
  rdata1_reg : process(out_enable, set, addr, data, read_bus)
  begin
	 if addr = Rdata1_addr then
	   if (not set) and out_enable then
	     data <= read_bus(7 downto 0);
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process rdata1_reg;
  --
  --  Register for read data 2.
  --
  rdata2_reg : process(out_enable, set, addr, data, read_bus)
  begin
	 if addr = Rdata2_addr then
	   if (not set) and out_enable then
	     data <= read_bus(15 downto 8);
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process rdata2_reg;
  --
  --  Register for read data 3.
  --
  rdata3_reg : process(out_enable, set, addr, data, read_bus)
  begin
	 if addr = Rdata3_addr then
	   if (not set) and out_enable then
	     data <= read_bus(23 downto 16);
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process rdata3_reg;
  --
  --  Register for read data 4.
  --
  rdata4_reg : process(out_enable, set, addr, data, read_bus)
  begin
	 if addr = Rdata4_addr then
	   if (not set) and out_enable then
	     data <= read_bus(31 downto 24);
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process rdata4_reg;
  --
  --  Register for address r1 and r2
  --
  raddr12_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = Raddr12_addr then
      if set then
	     saved := data;
		  raddr1 <= work.typedefs.vec_to_byte(saved(7 downto 4));
		  raddr2 <= work.typedefs.vec_to_byte(saved(3 downto 0));
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process raddr12_reg;
  --
  --  Register for address r3
  --
  raddr3_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = Raddr3_addr then
      if set then
	     saved := data;
		  raddr3 <= work.typedefs.vec_to_byte(saved(7 downto 4));
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process raddr3_reg;
  --
  --  Register for write address.  Reading also returns sequencer state
  --
  waddr_reg : process(out_enable, set, addr, data, state)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = Waddr_addr then
      if set then
	     saved := data;
		  waddr <= work.typedefs.vec_to_byte(saved(3 downto 0));
	   elsif out_enable then
		  saved(7 downto 4) := state;
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process waddr_reg;
  --
  --  Register for enable bits
  --
  enable_reg : process(out_enable, set, addr, data)
    variable saved : std_logic_vector (7 downto 0) := (others => '0');
  begin
	 if addr = enable_addr then
      if set then
        saved := data;
		  enable_read <= saved(2);
		  enable_write <= saved(1);
		  start <= saved(0);
	   elsif out_enable then
	     data <= saved;
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process enable_reg;

end rtl;

    