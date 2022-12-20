--
--  An example 16 bit counter
--
library ieee;

use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity Counter is
  generic (location : work.typedefs.byte);
  port (data : inout std_logic_vector (7 downto 0);
        out_enable : in boolean;
		  set : in boolean;
		  addr : in work.typedefs.byte;
		  clock : in std_logic);
end entity Counter;

architecture rtl of Counter is
begin
  count : process(out_enable, set, addr, data, clock)
    variable value : std_logic_vector(31 downto 0) := (others => '0');
  begin
    if rising_edge(clock) then
	   value := value + 1;
	 end if;
	 if addr = location then
	   if out_enable and not set then
	     data <= value(23 downto 16);
      else
	     data <= (others => 'Z');
		end if;
	 elsif addr = location+1 then
	   if out_enable and not set then
	     data <= value(31 downto 24);
      else
	     data <= (others => 'Z');
		end if;
	 else
      data <= (others => 'Z');
    end if;
  end process count;
end rtl;
