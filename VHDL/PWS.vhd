--
--  This is the model for the processor status work.  It
--  currently just holds the ALU flags, but will be expanded
--  as necessary.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity PSW is
  port(set_value : in std_logic;
       flags_in  : in work.typedefs.t_FLAGS;
       flags_out : out work.typedefs.t_FLAGS);

end PSW;

architecture rtl of PSW is
begin
  flags_out <= flags_in when rising_edge(set_value);
end rtl;
