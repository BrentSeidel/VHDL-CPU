--
--  A 1024x32 block of RAM.  This is used to provide a block
--  of memory that can be easily accessed by the CPU.  No
--  special SDRAM controller is needed.
--
--  It should also be modified to allow read/write from the
--  Arduino M0+ CPU so that values can be loaded or read from
--  the memory.
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library lpm;
use lpm.lpm_components.all;

entity ram_block is
  port(cpu_data_out : in std_logic_vector (31 downto 0);  --  From CPU
       cpu_data_in  : out std_logic_vector (31 downto 0);  --  To CPU
		 cpu_addr     : in std_logic_vector (31 downto 0);  --  From CPU
		 write_enable : in std_logic;
		 clock        : in std_logic);
end ram_block;

architecture rtl of ram_block is
begin
  ram: lpm_ram_dq
    generic map(lpm_widthad => 10, lpm_width => 32)
	 port map(data =>cpu_data_out,
	          address => cpu_addr(9 downto 0),
				 we => write_enable,
				 q => cpu_data_in,
				 inclock => clock,
				 outclock => clock);

end rtl;