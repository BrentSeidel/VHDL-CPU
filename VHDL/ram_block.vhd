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
--    8    R/W   Addr LSB
--    9    R/W   Addr MSB
--   10    R/W   Control Bits
--                 2 - Enable read
--                 1 - Enable write
--                 0 - Disconnect CPU
--
--  To prevent conflict, the Disconnect CPU bit should be set
--  before the host reads and writes the RAM.
--
--  
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library lpm;
use lpm.lpm_components.all;

entity ram_block is
  generic(cpu_location : std_logic_vector (31 downto 0);  --  Location on CPU bus
         host_location : work.typedefs.byte);             --  Location for host registers
  port(cpu_data_out  : in std_logic_vector (31 downto 0);  --  From CPU
       cpu_data_in   : out std_logic_vector (31 downto 0);  --  To CPU
		 cpu_addr      : in std_logic_vector (31 downto 0);  --  From CPU
		 read_in   : in std_logic;
		 write_in  : in std_logic;
		 read_out  : out std_logic;
		 write_out : out std_logic;
		 ack_in    : in std_logic;
		 ack_out   : out std_logic;
		 clock         : in std_logic;
		 host_data_in  : in std_logic_vector (7 downto 0);
       host_data_out : out std_logic_vector (7 downto 0);
       host_out_enable : in boolean;
	    host_set      : in boolean;
	    host_addr     : in work.typedefs.byte);
end ram_block;

architecture rtl of ram_block is
  signal q  : std_logic_vector (31 downto 0);  --  Local data out
  signal we : std_logic;  --  Local write enable
begin
  ram: lpm_ram_dq
    generic map(lpm_widthad => 10, lpm_width => 32)
	 port map(data =>cpu_data_out,
	          address => cpu_addr(9 downto 0),
				 we => we,
				 q => q,
				 inclock => clock,
				 outclock => clock);
--
--  Handle device selection.  If not selected, just pass data through and force write_enable false.
--
  cpu_data_in <= q when (cpu_location(31 downto 10) = cpu_addr(31 downto 10)) else
                 cpu_data_out;
  we <= write_in when (cpu_location(31 downto 10) = cpu_addr(31 downto 10)) else '0';
end rtl;