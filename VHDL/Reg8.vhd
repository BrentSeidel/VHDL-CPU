--
--  Define an 8 bit register
--
library ieee;

use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
--
--  Register entity
--
entity Reg8 is
  generic (location : work.typedefs.byte);
  port (data : inout std_logic_vector (7 downto 0);
        out_enable : in boolean;
		  set : in boolean;
		  addr : in work.typedefs.byte);
end entity Reg8;

architecture rtl of Reg8 is
begin
  store : process(out_enable, set, addr, data)
    variable saved_data : std_logic_vector (7 downto 0) := (others => '0');
  begin
    if addr = location then
      if set then
	     saved_data := data;
	   elsif out_enable then
	     data <= saved_data;
      else
	     data <= (others => 'Z');
		end if;
    else
      data <= (others => 'Z');
	 end if;
  end process store;
end rtl;

    