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
--                 4 - Select Op 2 as 1
--                 3 - Enable flags
--                 2 - Enable read
--                 1 - Enable write
--                 0 - Start state machine
--
entity CPU32 is
  generic (location : work.typedefs.byte);
  port (data_in  : in std_logic_vector (7 downto 0);
        data_out : out std_logic_vector (7 downto 0);
        host  : work.typedefs.host_bus_ctrl;
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
  signal incdec         : std_logic;
  signal enable_read    : std_logic;
  signal enable_write   : std_logic;
  signal func_value     : work.typedefs.byte;
  signal flags_en       : std_logic;
  signal flags_pre      : work.typedefs.t_FLAGS;
  signal flags_post     : work.typedefs.t_FLAGS;
  signal state          : std_logic_vector(3 downto 0);

begin
  cpu : work.cpu
  generic map (count => count, size => size)
  port map (
       clock => clock,
		 start => start,
		 incdec => incdec,
		 state => state,
       r_addr1   => raddr1,     --  Read port 1
		 r_addr2   => raddr2,     --  Read port 2
		 r_addr3   => raddr3,     --  Read port 3
		 r_data3   => read_bus,
		 r_en3     => enable_read,
		 w_addr    => waddr,
		 w_data    => write_bus,
		 host_write => enable_write,
       funct     => func_value, --  ALU Function
		 flags_en  => flags_en,     --  Set ALU flags
       flags_in  => flags_pre,    --  ALU Flags in
       flags_out => flags_post);  --  ALU Flags out
  --
  --  Register for general data registers
  --
  general_reg : process(host, data_in, write_bus,
    read_bus, func_value, flags_post, raddr1, raddr2, raddr3,
	 state, waddr, enable_read, enable_write, start, flags_en)
  begin
    case host.addr is
	   when Wdata1_addr =>  --  Write data 1
        if host.cmd_write then
	       write_bus(7 downto 0) <= data_in;
			 data_out <= data_in;
	     elsif host.cmd_read then
	       data_out <= write_bus(7 downto 0);
		  end if;
	   when Wdata2_addr =>  --  Write data 2
        if host.cmd_write then
	       write_bus(15 downto 8) <= data_in;
			 data_out <= data_in;
	     elsif host.cmd_read then
	       data_out <= write_bus(15 downto 8);
		  end if;
	   when Wdata3_addr =>  --  Write data 3
        if host.cmd_write then
	       write_bus(23 downto 16) <= data_in;
			 data_out <= data_in;
	     elsif host.cmd_read then
	       data_out <= write_bus(23 downto 16);
		  end if;
	   when Wdata4_addr =>  --  Write data 4
        if host.cmd_write then
	       write_bus(31 downto 24) <= data_in;
	     elsif host.cmd_read then
	       data_out <= write_bus(31 downto 24);
		  end if;
		when funct_addr =>  --  ALU function
        if host.cmd_write then
		    func_value <= work.typedefs.vec_to_byte(data_in);
			 data_out <= data_in;
	     elsif host.cmd_read then
	       data_out <= work.typedefs.byte_to_vec(func_value);
		  end if;
		when flag_addr =>  --  ALU flags
        if host.cmd_write then
		    flags_pre <= work.typedefs.vec_to_flags(data_in);
			 data_out <= data_in;
	     elsif host.cmd_read then
		    data_out(7 downto 5) <= (others => '0');
	       data_out(4 downto 0) <= work.typedefs.flags_to_vec(flags_post);
		  end if;
		when Rdata1_addr =>  --  Read data 1
	     if (not host.cmd_write) and host.cmd_read then
	       data_out <= read_bus(7 downto 0);
		  else
			 data_out <= data_in;
		  end if;
		when Rdata2_addr =>  --  Read data 2
	     if (not host.cmd_write) and host.cmd_read then
	       data_out <= read_bus(15 downto 8);
		  else
			 data_out <= data_in;
		  end if;
		when Rdata3_addr =>  --  Read data 3
	     if (not host.cmd_write) and host.cmd_read then
	       data_out <= read_bus(23 downto 16);
		  else
			 data_out <= data_in;
		  end if;
		when Rdata4_addr =>  --  Read data 4
	     if (not host.cmd_write) and host.cmd_read then
	       data_out <= read_bus(31 downto 24);
		  else
			 data_out <= data_in;
		  end if;
		when Raddr12_addr =>  --  Read register addresses 1 & 2
        if host.cmd_write then
	       raddr1 <= work.typedefs.vec_to_byte(data_in(7 downto 4));
		    raddr2 <= work.typedefs.vec_to_byte(data_in(3 downto 0));
			 data_out <= data_in;
	     elsif host.cmd_read then
		    data_out(7 downto 4) <= work.typedefs.byte_to_vec(raddr1)(3 downto 0);
		    data_out(3 downto 0) <= work.typedefs.byte_to_vec(raddr2)(3 downto 0);
		  end if;
		when Raddr3_addr =>  --  Read register address 3
        if host.cmd_write then
		    raddr3 <= work.typedefs.vec_to_byte(data_in(7 downto 4));
			 data_out <= data_in;
	     elsif host.cmd_read then
	       data_out <= work.typedefs.byte_to_vec(raddr3);
		  end if;
		when Waddr_addr =>  --  Write register address
        if host.cmd_write then
		    waddr <= work.typedefs.vec_to_byte(data_in(3 downto 0));
			 data_out <= data_in;
	     elsif host.cmd_read then
		    data_out(7 downto 4) <= state;
	       data_out(3 downto 0) <= work.typedefs.byte_to_vec(waddr)(3 downto 0);
		  end if;
		when enable_addr =>  --  Enable/control bits
        if host.cmd_write then
		    incdec       <= data_in(4);
		    flags_en     <= data_in(3);
		    enable_read  <= data_in(2);
		    enable_write <= data_in(1);
		    start        <= data_in(0);
			 data_out <= data_in;
	     elsif host.cmd_read then
		    data_out <= (0 => start, 1 => enable_write, 2 => enable_read,
			              3 => flags_en, 4 => incdec, others => '0');
		  end if;
      when others =>
	     data_out <= data_in;
    end case;		
	 if (not host.cmd_write) and (not host.cmd_read) then
      data_out <= data_in;
	 end if;
  end process general_reg;

end rtl;

    