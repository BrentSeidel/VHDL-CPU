--
--  An example 32 bit counter
--
library ieee;

use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity Counter is
  generic (location : work.typedefs.byte);
  port (data_in  : in std_logic_vector (7 downto 0);
        data_out : out std_logic_vector (7 downto 0);
        out_enable : in boolean;
		  set : in boolean;
		  addr : in work.typedefs.byte;
		  clock : in std_logic);
end entity Counter;
--
--  The 16 LSBs are unavailable to the user.  The 16 MSBs are
--  read as two bytes.  Reading the LSB (bits 23 downto 16)
--  makes a copy of the counter so that the MSB (bits 32 downto 24)
--  can be read without being updated by the counter.
--
architecture rtl of Counter is
begin
  count : process(out_enable, set, addr, data_in, clock)
    variable value : std_logic_vector(31 downto 0) := (others => '0');
	 variable temp : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clock) then
	   value := value + 1;
	 end if;
	 if addr = location then
	   if out_enable and not set then
		  temp := value;
	     data_out <= temp(23 downto 16);
      else
		  data_out <= data_in;
		end if;
	 elsif addr = location+1 then
	   if out_enable and not set then
	     data_out <= temp(31 downto 24);
      else
		  data_out <= data_in;
		end if;
	 else
      data_out <= data_in;
    end if;
  end process count;
end rtl;
