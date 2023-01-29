--
--  A generic multiplexer.  It takes input from one of
--  two inputs and passes it to the output.  This is based
--  on a number of examples found on the internet.
--
library ieee;

use ieee.std_logic_1164.all;

entity multiplexor2 is
  generic(size : natural);     --  Number of bits
  port(selector : in std_logic;  --  True for input 1, false for input 2
       inp1 : in std_logic_vector (size-1 downto 0);
       inp2 : in std_logic_vector (size-1 downto 0);
		 out1 : out std_logic_vector (size-1 downto 0));
end entity multiplexor2;

architecture rtl of multiplexor2 is
begin
  out1 <= inp1 when (selector = '1') else
          inp2;
end rtl;
