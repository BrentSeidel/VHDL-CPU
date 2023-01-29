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
  --  Register for general data registers
  --
  general_reg : process(out_enable, set, addr, data, write_bus)
  begin
    case addr is
	   when Wdata1_addr =>  --  Write data 1
        if set then
	       write_bus(7 downto 0) <= data;
	     elsif out_enable then
	       data <= write_bus(7 downto 0);
		  end if;
	   when Wdata2_addr =>  --  Write data 2
        if set then
	       write_bus(15 downto 8) <= data;
	     elsif out_enable then
	       data <= write_bus(15 downto 8);
		  end if;
	   when Wdata3_addr =>  --  Write data 3
        if set then
	       write_bus(23 downto 16) <= data;
	     elsif out_enable then
	       data <= write_bus(23 downto 16);
		  end if;
	   when Wdata4_addr =>  --  Write data 4
        if set then
	       write_bus(31 downto 24) <= data;
	     elsif out_enable then
	       data <= write_bus(31 downto 24);
		  end if;
		when funct_addr =>  --  ALU function
        if set then
		    func_value <= work.typedefs.vec_to_byte(data);
	     elsif out_enable then
	       data <= work.typedefs.byte_to_vec(func_value);
		  end if;
		when flag_addr =>  --  ALU flags
        if set then
		    flags_pre <= work.typedefs.vec_to_flags(data);
	     elsif out_enable then
	       data <= work.typedefs.flags_to_vec(flags_post);
		  end if;
		when Rdata1_addr =>  --  Read data 1
	     if (not set) and out_enable then
	       data <= read_bus(7 downto 0);
		  end if;
		when Rdata2_addr =>  --  Read data 2
	     if (not set) and out_enable then
	       data <= read_bus(15 downto 8);
		  end if;
		when Rdata3_addr =>  --  Read data 3
	     if (not set) and out_enable then
	       data <= read_bus(23 downto 16);
		  end if;
		when Rdata4_addr =>  --  Read data 4
	     if (not set) and out_enable then
	       data <= read_bus(31 downto 24);
		  end if;
      when others =>
	     data <= (others => 'Z');
    end case;		
	 if (not set) and (not out_enable) then
      data <= (others => 'Z');
	 end if;
  end process general_reg;
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

    