--
--  A 1024x32 block of RAM.  This is used to provide a block
--  of memory that can be easily accessed by the CPU.  No
--  special SDRAM controller is needed.
--
--  The memory can also be accessed by software running on the
--  Arduino M0+ host processor.
--
--  Host registers
--  Base+  Type  Use
--    0    R/W   Write data bits 7-0
--    1    R/W   Write data bits 15-8
--    2    R/W   Write data bits 23-16
--    3    R/W   Write data bits 31-24
--    4     RO   Read data bits 7-0
--    5     RO   Read data bits 15-8
--    6     RO   Read data bits 23-16
--    7     RO   Read data bits 31-24
--    8    R/W   Addr LSB (7-0)
--    9    R/W   Addr MSB (9-8)
--                 4 - Enable read
--                 3 - Enable write
--                 2 - Disconnect CPU
--                 1 - Addr bit 9
--                 0 - Addr bit 8
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;

entity ram_block is
  generic(cpu_location : std_logic_vector (31 downto 0);  --  Location on CPU bus
         host_location : work.typedefs.byte);             --  Location for host registers
  port(cpu_bus         : in work.typedefs.cpu_bus_ctrl;
       cpu_ret_in      : in work.typedefs.cpu_bus_ret;
		 cpu_ret_out     : out work.typedefs.cpu_bus_ret;
		 clock           : in std_logic;
		 host_data_in    : in std_logic_vector (7 downto 0);
       host_data_out   : out std_logic_vector (7 downto 0);
		 host            : in work.typedefs.host_bus_ctrl);
end ram_block;

architecture rtl of ram_block is
  constant Wdata1_addr  : work.typedefs.byte := host_location;
  constant Wdata2_addr  : work.typedefs.byte := host_location + 1;
  constant Wdata3_addr  : work.typedefs.byte := host_location + 2;
  constant Wdata4_addr  : work.typedefs.byte := host_location + 3;
  constant Rdata1_addr  : work.typedefs.byte := host_location + 4;
  constant Rdata2_addr  : work.typedefs.byte := host_location + 5;
  constant Rdata3_addr  : work.typedefs.byte := host_location + 6;
  constant Rdata4_addr  : work.typedefs.byte := host_location + 7;
  constant Addr1_addr   : work.typedefs.byte := host_location + 8;
  constant Addr2_addr   : work.typedefs.byte := host_location + 9;
  constant Cdata1_addr  : work.typedefs.byte := host_location + 10;
  constant Cdata2_addr  : work.typedefs.byte := host_location + 11;
  constant Cdata3_addr  : work.typedefs.byte := host_location + 12;
  constant Cdata4_addr  : work.typedefs.byte := host_location + 13;
  constant Caddr1_addr  : work.typedefs.byte := host_location + 14;
  constant Caddr2_addr  : work.typedefs.byte := host_location + 15;
  constant Caddr3_addr  : work.typedefs.byte := host_location + 16;
  constant Caddr4_addr  : work.typedefs.byte := host_location + 17;
  signal host_ram_data_in  : std_logic_vector (31 downto 0);
  signal host_ram_data_out : std_logic_vector (31 downto 0);
  signal host_ram_addr     : std_logic_vector (9 downto 0);
  signal host_write : std_logic;
  signal host_read  : std_logic;
  signal host_clock : std_logic;
  signal cpu_selected : boolean;
  signal ram_data_in  : std_logic_vector (31 downto 0);
  signal ram_addr : std_logic_vector (9 downto 0);
  signal q  : std_logic_vector (31 downto 0);  --  Local data out port a
  signal we : std_logic;  --  Local write enable
begin
  alt_ram: altsyncram
    generic map(operation_mode => "BIDIR_DUAL_PORT",
	             width_a   => 32,  --  Port A is for CPU
					 widthad_a => 10,
					 width_b   => 32,  --  Port B is for Host
					 widthad_b => 10)
	 port map(address_a => cpu_bus.addr(9 downto 0),  --  Port A (CPU)
				 data_a => cpu_bus.data,
				 wren_a => cpu_bus.write_cmd,
				 q_a => q,
				 clocken0 => '1',
				 clock0 => clock,
				 address_b => host_ram_addr,  --  Port B (Host)
				 data_b => host_ram_data_in,
				 wren_b => host_write,
				 q_b => host_ram_data_out,
				 clocken1 => '1',
				 clock1 => host_clock);
--
--  Handle device selection.
--
  cpu_selected <= (cpu_location(31 downto 10) = cpu_bus.addr(31 downto 10));
  cpu_ret_out <= (data => q, ack => '0') when cpu_selected else
                 cpu_ret_in;
--
--  Control process
--
  ram_ctrl: process(host, host_data_in, host_ram_data_in, host_ram_addr,
    host_clock, host_write, host_read, host_ram_data_out)
  begin
    case host.addr is
	   when Wdata1_addr =>  --  Write data 1
        if host.cmd_write then
	       host_ram_data_in(7 downto 0) <= host_data_in;
			 host_data_out <= host_data_in;
	     elsif host.cmd_read then
	       host_data_out <= host_ram_data_in(7 downto 0);
		  end if;
	   when Wdata2_addr =>  --  Write data 2
        if host.cmd_write then
	       host_ram_data_in(15 downto 8) <= host_data_in;
			 host_data_out <= host_data_in;
	     elsif host.cmd_read then
	       host_data_out <= host_ram_data_in(15 downto 8);
		  end if;
	   when Wdata3_addr =>  --  Write data 3
        if host.cmd_write then
	       host_ram_data_in(23 downto 16) <= host_data_in;
			 host_data_out <= host_data_in;
	     elsif host.cmd_read then
	       host_data_out <= host_ram_data_in(23 downto 16);
		  end if;
	   when Wdata4_addr =>  --  Write data 4
        if host.cmd_write then
	       host_ram_data_in(31 downto 24) <= host_data_in;
	     elsif host.cmd_read then
	       host_data_out <= host_ram_data_in(31 downto 24);
		  end if;
		when Rdata1_addr =>  --  Read data 1
	     if (not host.cmd_write) and host.cmd_read then
	       host_data_out <= host_ram_data_out(7 downto 0);
		  else
			 host_data_out <= host_data_in;
		  end if;
		when Rdata2_addr =>  --  Read data 2
	     if (not host.cmd_write) and host.cmd_read then
	       host_data_out <= host_ram_data_out(15 downto 8);
		  else
			 host_data_out <= host_data_in;
		  end if;
		when Rdata3_addr =>  --  Read data 3
	     if (not host.cmd_write) and host.cmd_read then
	       host_data_out <= host_ram_data_out(23 downto 16);
		  else
			 host_data_out <= host_data_in;
		  end if;
		when Rdata4_addr =>  --  Read data 4
	     if (not host.cmd_write) and host.cmd_read then
	       host_data_out <= host_ram_data_out(31 downto 24);
		  else
			 host_data_out <= host_data_in;
		  end if;
		when Addr1_addr =>  --  Write register address
        if host.cmd_write then
		    host_ram_addr(7 downto 0) <= host_data_in;
			 host_data_out <= host_data_in;
	     elsif host.cmd_read then
		    host_data_out <= host_ram_addr(7 downto 0);
		  end if;
		when Addr2_addr =>  --  Write register address
        if host.cmd_write then
		    host_ram_addr(9 downto 8) <= host_data_in(1 downto 0);
			 host_read <= host_data_in(4);
			 host_write <= host_data_in(3);
			 host_clock <= host_data_in(2);
			 host_data_out <= host_data_in;
	     elsif host.cmd_read then
		    host_data_out(1 downto 0) <= host_ram_addr(9 downto 8);
			 host_data_out(2) <= host_clock;
			 host_data_out(3) <= host_write;
			 host_data_out(4) <= host_read;
			 host_data_out(7 downto 5) <= (others => '0');
		  end if;
		when Cdata1_addr =>  --  Read from CPU data bus (read only)
		  if host.cmd_read then
		    host_data_out <= cpu_bus.data(7 downto 0);
		  end if;
		when Cdata2_addr =>  --  Read from CPU data bus (read only)
		  if host.cmd_read then
		    host_data_out <= cpu_bus.data(15 downto 8);
		  end if;
		when Cdata3_addr =>  --  Read from CPU data bus (read only)
		  if host.cmd_read then
		    host_data_out <= cpu_bus.data(23 downto 16);
		  end if;
		when Cdata4_addr =>  --  Read from CPU data bus (read only)
		  if host.cmd_read then
		    host_data_out <= cpu_bus.data(31 downto 24);
		  end if;
		when Caddr1_addr =>  --  Read from CPU address bus (read only)
		  if host.cmd_read then
		    host_data_out <= cpu_bus.addr(7 downto 0);
		  end if;
		when Caddr2_addr =>  --  Read from CPU address bus (read only)
		  if host.cmd_read then
		    host_data_out <= cpu_bus.addr(15 downto 8);
		  end if;
		when Caddr3_addr =>  --  Read from CPU address bus (read only)
		  if host.cmd_read then
		    host_data_out <= cpu_bus.addr(23 downto 16);
		  end if;
		when Caddr4_addr =>  --  Read from CPU address bus (read only)
		  if host.cmd_read then
		    host_data_out <= cpu_bus.addr(31 downto 24);
		  end if;
      when others =>  --  Not being addressed
	     host_data_out <= host_data_in;
    end case;		
	 if (not host.cmd_write) and (not host.cmd_read) then
      host_data_out <= host_data_in;
	 end if;
  end process ram_ctrl;
end rtl;