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
  port(clock : in std_logic;
       start : in std_logic;
		 enable_op1 : out std_logic;
		 enable_op2 : out std_logic;
		 enable_res : out std_logic;
		 write_mux_sel : out std_logic;
		 psw_mux_sel : out std_logic;
		 op2_mux_sel : out std_logic;
		 set_psw : out std_logic;
		 current_state : out std_logic_vector(3 downto 0));
end entity sequencer;

architecture rtl of sequencer is
  type states is (state_null, state_read_op, state_write_res, state_final,
                  state_incr);
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
  state_machine: process(state, start)
  begin
    case state is
	   when state_null =>  --  Wait for start signal to go high
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  enable_res <= '0';
		  write_mux_sel <= '0';
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= '0';
		  op2_mux_sel <= '0';
		  if start = '1' then
          next_state <= state_read_op;
		  else
			 next_state <= state_null;
		  end if;
		when state_read_op =>  --  Read operands for the ALU
		  enable_op1 <= '1';
		  enable_op2 <= '1';
		  enable_res <= '0';
		  write_mux_sel <= '1';
		  psw_mux_sel <= '1';
		  op2_mux_sel <= '0';
		  set_psw <= '0';
		  next_state <= state_write_res;
		when state_incr =>  --  Prepare for an increment
		  enable_op1 <= '1';
		  enable_op2 <= '1';
		  enable_res <= '0';
		  write_mux_sel <= '1';
		  psw_mux_sel <= '1';
		  op2_mux_sel <= '1';
		  set_psw <= '0';
		  next_state <= state_write_res;
		when state_write_res =>  --  Write result from the ALU
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  enable_res <= '1';
		  write_mux_sel <= '1';
		  psw_mux_sel <= '1';
		  op2_mux_sel <= '0';
		  set_psw <= '1';
		  if start = '0' then
		    next_state <= state_null;
		  else
		    next_state <= state_final;
		  end if;
		when state_final =>  -- Wait for start signal to go low
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  enable_res <= '0';
		  write_mux_sel <= '0';
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= '0';
		  if start = '0' then
		    next_state <= state_null;
		  else
		    next_state <= state_final;
		  end if;
		when others =>  --  Should never get here.  Set everthing to a sane state and try again.
		  next_state <= state_null;
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  enable_res <= '0';
		  write_mux_sel <= '0';
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= '0';
	 end case;
  end process state_machine;
end rtl;
