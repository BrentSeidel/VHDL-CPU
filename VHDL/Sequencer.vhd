--
--  This is the state machine for controlling the CPU.  It is
--  expected that there will be lots of changes here as the
--  CPU develops.
--
--  Phase I just provides signals to read from registers to
--  the ALU and write the results back.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.Numeric_Std.all;

entity sequencer is
  generic(count : natural; size : natural);
  port(clock        : in std_logic;
       start        : in std_logic;  --  Start processing
		 incdec       : in std_logic;  --  Select an increment/decrement operation
		 host_write   : in std_logic;  --  Host request to write data
		 host_data    : in std_logic_vector (size-1 downto 0);
		 alu_data     : in std_logic_vector (size-1 downto 0);
		 flags_en     : in std_logic;  --  Host request to write psw
		 enable_op1    : out std_logic;
		 enable_op2    : out std_logic;
		 enable_res    : out std_logic;
		 psw_mux_sel   : out std_logic;
		 op2_mux_sel   : out std_logic;
		 set_psw       : out std_logic;
		 write_data    : out std_logic_vector (size-1 downto 0);
		 current_state : out std_logic_vector(3 downto 0));
end entity sequencer;

architecture rtl of sequencer is
  type states is (state_null, state_read_op, state_write_res, state_final);
  signal state : states := state_null;
  signal next_state : states := state_null;
begin
  --
  --  Transition states on the rising edge of a clock signal
  --
  state_advance: process(clock)
    variable temp : work.typedefs.byte;
  begin
    if rising_edge(clock) then
      state <= next_state;
		temp := state'Pos(state);
		current_state <= std_logic_vector(to_unsigned(temp, 4));
    end if;
  end process state_advance;
  --
  --  Compute what the next state should be and set output signals.
  --
  state_machine: process(state, start, host_write, flags_en, host_data, alu_data)
  begin
    case state is
	   when state_null =>  --  Wait for start signal to go high
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  enable_res <= host_write;
		  write_data <= host_data;
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= flags_en;
		  op2_mux_sel <= '0';
		  if start = '1' then
          next_state <= state_read_op;
		  else
			 next_state <= state_null;
		  end if;
		when state_read_op =>  --  Read operands for the ALU
		  enable_op1 <= '1';
		  enable_op2 <= '1';
		  enable_res <= host_write;
		  write_data <= alu_data;
		  psw_mux_sel <= '1';
	     op2_mux_sel <= incdec;
		  set_psw <= flags_en;
		  next_state <= state_write_res;
		when state_write_res =>  --  Write result from the ALU
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  enable_res <= '1';
		  write_data <= alu_data;
		  psw_mux_sel <= '1';
	     op2_mux_sel <= incdec;
		  set_psw <= '1';
		  if start = '0' then
		    next_state <= state_null;
		  else
		    next_state <= state_final;
		  end if;
		when state_final =>  -- Wait for start signal to go low
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  enable_res <= host_write;
		  write_data <= host_data;
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= flags_en;
		  if start = '0' then
		    next_state <= state_null;
		  else
		    next_state <= state_final;
		  end if;
		when others =>  --  Should never get here.  Set everthing to a sane state and try again.
		  next_state <= state_null;
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  enable_res <= host_write;
		  write_data <= host_data;
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= flags_en;
	 end case;
  end process state_machine;
end rtl;
