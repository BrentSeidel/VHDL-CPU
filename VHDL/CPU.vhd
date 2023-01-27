--
--  File to collect and assemble components for a CPU.
--  This is expected to go through many iterations before
--  a full CPU is working.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity CPU is
  generic(count : natural; size : natural);
  port(clock   : in std_logic;
       start   : in std_logic;
		 state   : out std_logic_vector(3 downto 0);
       r_addr1 : in natural range 0 to (2**count)-1;
		 r_addr2 : in natural range 0 to (2**count)-1;
		 r_addr3 : in natural range 0 to (2**count)-1;
		 r_data3 : out std_logic_vector (size-1 downto 0);
		 r_en3   : in std_logic;
		 w_addr  : in natural range 0 to (2**count)-1;
		 w_data  : in std_logic_vector (size-1 downto 0);
		 w_en2   : in std_logic;  --  Write external data
       funct     : in work.typedefs.byte;
       flags_in  : in work.typedefs.t_FLAGS;
       flags_out : out work.typedefs.t_FLAGS);
end entity CPU;

architecture rtl of CPU is
  signal op1 : std_logic_vector (size-1 downto 0);  --  ALU Operand 1
  signal op2 : std_logic_vector (size-1 downto 0);  --  ALU Operand 2
  signal res : std_logic_vector (size-1 downto 0);  --  ALU Result
  signal reg : std_logic_vector (size-1 downto 0);  --  Mux to register file
  signal enable_op1 : std_logic;
  signal enable_op2 : std_logic;
  signal enable_res : std_logic;

begin
  sequence : work.sequencer
    port map(clock => clock,
	          start => start,
             enable_op1 => enable_op1,
             enable_op2 => enable_op2,
             enable_res => enable_res,
				 current_state => state);

  multiplexor : work.mux
    generic map(size => size)
	 port map(selector => (enable_res = '1'),
	          inp1 => res,
				 inp2 => w_data,
				 out1 => reg);

  reg_file :  work.register_file
    generic map(count => count, size => size)
	 port map(r_addr1 => r_addr1, 
             r_data1 => op1,      --  Internal
             r_en1   => enable_op1,
             r_addr2 => r_addr2,
             r_data2 => op2,      --  Internal
             r_en2   => enable_op2,
             r_addr3 => r_addr3,
             r_data3 => r_data3,
             r_en3   => r_en3,
             w_addr  => w_addr,
             w_data  => reg,       --  From mux
             w_en    => (enable_res or w_en2));

  alu : work.alu
    generic map(size => size)
	 port map(op1       => op1,  --  Internal
	          op2       => op2,  --  Internal
				 result    => res,  --  Internal
	          funct     => funct,
				 flags_in  => flags_in,
				 flags_out => flags_out);
end rtl;
