--
--  A generic register file.  The size of the registers and the
--  number of registers are specified by the generic parameters.
--  There are three read ports and two write ports.
--  Two of the read ports are used for direct access by the ALU.
--  One write port is used for results from the ALU.
--  The remaining ports are used for other loading or reading of
--  registers.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity register_file is
  generic(count : integer;  --  Number of bits to address registers
          size : integer);  --  Size of registers
  port(r_addr1 : in natural range 0 to 2**(count-1);     --  Read port 1
       r_data1 : out std_logic_vector (size-1 downto 0);
		 r_en1   : in boolean;
		 r_addr2 : in natural range 0 to 2**(count-1);     --  Read port 2
		 r_data2 : out std_logic_vector (size-1 downto 0);
		 r_en2   : in boolean;
		 r_addr3 : in natural range 0 to 2**(count-1);     --  Read port 3
		 r_data3 : out std_logic_vector (size-1 downto 0);
		 r_en3   : in boolean;
		 w_addr1 : in natural range 0 to 2**(count-1);     --  Write port 1
		 w_data1 : in std_logic_vector (size-1 downto 0);
		 w_en1   : in boolean;
		 w_addr2 : in natural range 0 to 2**(count-1);     --  Write port 2
		 w_data2 : in std_logic_vector (size-1 downto 0);
		 w_en2   : in boolean);
end entity register_file;

architecture rtl of register_file is
begin
  reg_access: process(r_en1, r_en2, r_en3,
		 w_en1, w_en2)
    subtype addr is natural range 0 to 2**(count-1);
	 type registers is array(addr) of std_logic_vector (size-1 downto 0);
	 variable reg_file : registers;
  begin
    if w_en1 then  --  Write port 1
	   reg_file(w_addr1) := w_data1;
--	   reg_file(w_addr1) := (others => '0');
	 end if;
    if w_en2 then  --  Write port 2
	   reg_file(w_addr2) := w_data2;
--	   reg_file(w_addr2) := (others => '1');
	 end if;
	 if r_en1 then  --  Read port 1
	   r_data1 <= reg_file(r_addr1);
--	 else
--	   r_data1 <= (others => 'Z');
	 end if;
	 if r_en2 then  --  Read port 2
	   r_data2 <= reg_file(r_addr2);
--	 else
--	   r_data2 <= (others => 'Z');
	 end if;
	 if r_en3 then  --  Read port 3
	   r_data3 <= reg_file(r_addr3);
--	 else
--	   r_data3 <= (others => 'Z');
	 end if;
  end process reg_access;
end rtl;
