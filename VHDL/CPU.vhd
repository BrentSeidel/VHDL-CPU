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
		 flags_en  : in std_logic;  --  Write flags
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
  signal set_psw    : std_logic;
  signal alu_flags_in  : work.typedefs.t_FLAGS;
  signal alu_flags_out : work.typedefs.t_FLAGS;
  signal flags_to_psw  : std_logic_vector (4 downto 0);
  signal write_mux_sel : std_logic;  --  Select source for writing to registers
  signal psw_mux_sel   : std_logic;  --  Select source for writing to PSW

begin
  sequence : work.sequencer
    port map(clock => clock,
	          start => start,
             enable_op1 => enable_op1,
             enable_op2 => enable_op2,
             enable_res => enable_res,
				 write_mux_sel => write_mux_sel,
				 psw_mux_sel => psw_mux_sel,
				 set_psw => set_psw,
				 current_state => state);

  pws_mux : work.multiplexor2
    generic map(size => 5)
	 port map(selector => psw_mux_sel,
	          inp1 => work.typedefs.flags_to_vec(alu_flags_out),
				 inp2 => work.typedefs.flags_to_vec(flags_in),
				 out1 => flags_to_psw);

  reg_mux : work.multiplexor2
    generic map(size => size)
	 port map(selector => write_mux_sel,
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

  psw : work.psw
    port map(set_value => set_psw or flags_en,
	          flags_in  => work.typedefs.vec_to_flags(flags_to_psw),
	          flags_out => alu_flags_in);

  flags_out <= alu_flags_in;
				 
  alu : work.alu
    generic map(size => size)
	 port map(op1       => op1,
	          op2       => op2,
				 result    => res,
	          funct     => funct,  --  External
				 flags_in  => alu_flags_in,
				 flags_out => alu_flags_out);
end rtl;
