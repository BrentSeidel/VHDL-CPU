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
  port(clock         : in std_logic;
       start         : in std_logic;
		 incdec        : in std_logic;
		 bus_read_req  : in std_logic;
		 bus_write_req : in std_logic;
		 state         : out std_logic_vector(3 downto 0);
       r_addr1       : in natural range 0 to (2**count)-1;
		 r_addr2       : in natural range 0 to (2**count)-1;
		 r_addr3       : in natural range 0 to (2**count)-1;
		 r_data3       : out std_logic_vector (size-1 downto 0);
		 r_en3         : in std_logic;
		 w_addr        : in natural range 0 to (2**count)-1;
		 w_data        : in std_logic_vector (size-1 downto 0);
		 host_write    : in std_logic;  --  Write external data
       funct         : in work.typedefs.byte;
		 cpu_bus       : out work.typedefs.cpu_bus_ctrl;
		 cpu_bus_ret   : in work.typedefs.cpu_bus_ret;
		 flags_en      : in std_logic;  --  Write flags
       flags_in      : in work.typedefs.t_FLAGS;
       flags_out     : out work.typedefs.t_FLAGS);
end entity CPU;

architecture rtl of CPU is
  signal op1 : std_logic_vector (size-1 downto 0);  --  ALU Operand 1
  signal op2 : std_logic_vector (size-1 downto 0);  --  ALU Operand 2
  signal op2_reg : std_logic_vector (size-1 downto 0);  --  Operand 2 from register
  signal res : std_logic_vector (size-1 downto 0);  --  ALU Result
  signal reg : std_logic_vector (size-1 downto 0);  --  Mux to register file
  signal bus_data_in_int : std_logic_vector (size-1 downto 0);  --  Data from BIU
  signal enable_op1 : std_logic;
  signal enable_op2 : std_logic;
  signal enable_res : std_logic;
  signal set_psw    : std_logic;
  signal read_cmd   : std_logic;
  signal write_cmd  : std_logic;
  signal bus_busy   : std_logic;
  signal bus_ready  : std_logic;
  signal alu_flags_in  : work.typedefs.t_FLAGS;
  signal alu_flags_out : work.typedefs.t_FLAGS;
  signal flags_to_psw  : std_logic_vector (4 downto 0);
  signal psw_mux_sel   : std_logic;  --  Select source for writing to PSW
  signal op2_mux_sel   : std_logic;  --  Select source for op 2.

begin
--
--  Select some signals
--
  flags_to_psw <= work.typedefs.flags_to_vec(alu_flags_out) when psw_mux_sel = '1' else
                  work.typedefs.flags_to_vec(flags_in);

  op2 <= op2_reg when op2_mux_sel = '0' else std_logic_vector(to_unsigned(1, size));
--
--  Logic Blocks
--
  sequencer : work.sequencer
    generic map(count => count, size => size)
    port map(clock => clock,
	          start => start,
				 incdec => incdec,
				 host_write => host_write,
				 host_data => w_data,
				 alu_data => res,
				 bus_data => bus_data_in_int,
				 flags_en => flags_en,
             bus_read_req  => bus_read_req,
             bus_write_req => bus_write_req,
				 bus_busy => bus_busy,
				 bus_ready => bus_ready,
				 read_cmd => read_cmd,
				 write_cmd => write_cmd,
             enable_op1 => enable_op1,
             enable_op2 => enable_op2,
             enable_res => enable_res,    --  Write to register file
				 psw_mux_sel => psw_mux_sel,
				 op2_mux_sel => op2_mux_sel,
				 set_psw => set_psw,
				 write_data => reg,           --  Data to register file
				 current_state => state);
--
  reg_file :  work.register_file
    generic map(count => count, size => size)
	 port map(r_addr1 => r_addr1, 
             r_data1 => op1,      --  Internal
             r_en1   => enable_op1,
             r_addr2 => r_addr2,
             r_data2 => op2_reg,  --  Internal
             r_en2   => enable_op2,
             r_addr3 => r_addr3,
             r_data3 => r_data3,
             r_en3   => r_en3,
             w_addr  => w_addr,
             w_data  => reg,       --  From sequencer
             w_en    => enable_res);
--
  psw : work.psw
    port map(set_value => set_psw,
	          flags_in  => work.typedefs.vec_to_flags(flags_to_psw),
	          flags_out => alu_flags_in);
--
  flags_out <= alu_flags_in;
--
  alu : work.alu
    generic map(size => size)
	 port map(op1       => op1,
	          op2       => op2,
				 result    => res,
	          funct     => funct,  --  External
				 flags_in  => alu_flags_in,
				 flags_out => alu_flags_out);
--
  biu : work.bus_interface
    generic map(addr_size => size, data_size => size)
	 port map(clock => clock,
	          cpu_bus => cpu_bus,
				 cpu_bus_ret => cpu_bus_ret,
				 data_in_int => op1,
				 data_out_int => bus_data_in_int,
				 addr_in_int => op2_reg,
				 read_cmd => read_cmd,
				 write_cmd => write_cmd,
				 busy => bus_busy,
				 ready => bus_ready);
end rtl;
