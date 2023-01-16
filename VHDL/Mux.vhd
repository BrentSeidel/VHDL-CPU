--
--  A generic multiplexer.  It takes input from one of
--  two inputs and passes it to the output.
--
library ieee;

use ieee.std_logic_1164.all;

entity mux is
  generic(size : natural);     --  Number of bits
  port(selector : in boolean;  --  True for input 1, false for input 2
       inp1 : in std_logic_vector (size-1 downto 0);
       inp2 : in std_logic_vector (size-1 downto 0);
		 out1 : out std_logic_vector (size-1 downto 0));
end entity mux;

architecture rtl of mux is
begin
  out1 <= inp1 when selector else
          inp2;
end rtl;
