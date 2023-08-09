--
--  This is the state machine for controlling the CPU.  It is
--  expected that there will be lots of changes here as the
--  CPU develops.
--
--  Phase 1 just provides signals to read from registers to
--  the ALU and write the results back.
--
--  Phase 2 adds control of the CPU bus to read and write to/from
--  RAM.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.Numeric_Std.all;

entity sequencer is
  generic(count : natural; size : natural);
  port(clock         : in std_logic;
       start         : in std_logic;  --  Start processing
		 incdec        : in std_logic;  --  Select an increment/decrement operation
		 host_write    : in std_logic;  --  Host request to write data
		 host_data     : in std_logic_vector (size-1 downto 0);  --  Data from host computer
		 alu_data      : in std_logic_vector (size-1 downto 0);  --  Data from ALU
		 bus_data      : in std_logic_vector (size-1 downto 0);  --  Data from BIU
		 flags_en      : in std_logic;  --  Host request to write psw
		 bus_read_req  : in std_logic;  --  Host request for a CPU bus read
		 bus_write_req : in std_logic;  --  Host request for a CPU bus write
		 bus_busy      : in std_logic;
		 bus_ready     : in std_logic;
		 read_cmd      : out std_logic;
		 write_cmd     : out std_logic;
		 enable_op1    : out std_logic;
		 enable_op2    : out std_logic;
		 enable_res    : out std_logic;
		 psw_mux_sel   : out std_logic;
		 op2_mux_sel   : out std_logic;
		 set_psw       : out std_logic;
		 write_data    : out std_logic_vector (size-1 downto 0);  --  Data to register file
		 current_state : out std_logic_vector(3 downto 0));
end entity sequencer;

architecture rtl of sequencer is
  type states is (state_null,        --  0 - Idle state waiting for command
                  state_read_op,     --  1 - Read operands for an ALU operation
						state_alu_wait1,   --  2 - Wait for ALU to complete
						state_write_res,   --  3 - Write results of ALU operation
						state_final,       --  4 - Wait for start signal to go low
                  state_mem_write,   --  5 - Write from CPU register to memory
						state_mem_read1,   --  6 - Read from memory
						state_mem_read2);  --  7 - Write data from memory to CPU register
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
  state_machine: process(state, start, host_write, flags_en, host_data, bus_data, alu_data)
  begin
    case state is
	   when state_null =>  --  Wait for start signal to go high
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  read_cmd <= '0';
		  write_cmd <= '0';
		  enable_res <= host_write;
		  write_data <= host_data;
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= flags_en;
		  op2_mux_sel <= '0';
		  if start = '1' then              --  Check for operation start
          next_state <= state_read_op;
		  elsif bus_write_req = '1' then   --  Check for bus write request
		    next_state <= state_mem_write;
		  elsif bus_read_req = '1' then    --  Check for bus read request
		    next_state <= state_mem_read1;
		  else
			 next_state <= state_null;
		  end if;
		when state_read_op =>  --  Read operands for the ALU
		  enable_op1 <= '1';
		  enable_op2 <= '1';
		  read_cmd <= '0';
		  write_cmd <= '0';
		  enable_res <= host_write;
		  write_data <= alu_data;
		  psw_mux_sel <= '1';
	     op2_mux_sel <= incdec;
		  set_psw <= flags_en;
		  next_state <= state_alu_wait1;
		when state_alu_wait1 =>  --  Wait one cycle for ALU to finish
		  enable_op1 <= '1';
		  enable_op2 <= '1';
		  read_cmd <= '0';
		  write_cmd <= '0';
		  enable_res <= host_write;
		  write_data <= alu_data;
		  psw_mux_sel <= '1';
	     op2_mux_sel <= incdec;
		  set_psw <= flags_en;
		  next_state <= state_write_res;
		when state_write_res =>  --  Write result from the ALU
		  enable_op1 <= '1';
		  enable_op2 <= '1';
		  enable_res <= '1';
		  read_cmd <= '0';
		  write_cmd <= '0';
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
		  enable_op1 <= '1';
		  enable_op2 <= '1';
		  read_cmd <= '0';
		  write_cmd <= '0';
		  enable_res <= host_write;
		  write_data <= host_data;
		  psw_mux_sel <= '0';
		  op2_mux_sel <= incdec;
		  set_psw <= flags_en;
		  if start = '0' then
		    next_state <= state_null;
		  else
		    next_state <= state_final;
		  end if;
		when state_mem_write =>  --  CPU Write to memory
		  enable_op1 <= '1';
		  enable_op2 <= '1';
		  read_cmd <= '0';
		  write_cmd <= '1';
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= '0';
		  if (bus_ready = '1') and (bus_write_req = '0') then
		    next_state <= state_null;
		  else
          next_state <= state_mem_write;
		  end if;
		when state_mem_read1 =>  --  CPU read from memory
		  enable_op1 <= '0';
		  enable_op2 <= '1';     --  OP2 is the memory address
		  enable_res <= '0';
		  read_cmd <= '1';       --  Read command to BIU
		  write_cmd <= '0';
		  write_data <= bus_data;
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= '0';
		  if bus_ready = '1' then  --  Wait for bus ready before moving to next state
		    next_state <= state_mem_read2;
		  else
		    next_State <= state_mem_read1;
		  end if;
		when state_mem_read2 =>  --  Write read data to register
        enable_op1 <= '0';
		  enable_op2 <= '1';
		  enable_res <= '1';
		  read_cmd <= '1';       --  Read command to BIU
		  write_cmd <= '0';
		  write_data <= bus_data;
		  psw_mux_sel <= '0';
	     op2_mux_sel <= '0';
		  set_psw <= '0';
		  if bus_read_req = '0' then
		    next_state <= state_null;
		  else
		    next_state <= state_mem_read2;
		  end if;
		when others =>  --  Should never get here.  Set everthing to a sane state and try again.
		  next_state <= state_null;
		  enable_op1 <= '0';
		  enable_op2 <= '0';
		  read_cmd <= '0';
		  write_cmd <= '0';
		  enable_res <= '0';
		  write_data <= (others => '0');
		  psw_mux_sel <= '0';
		  op2_mux_sel <= '0';
		  set_psw <= flags_en;
	 end case;
  end process state_machine;
end rtl;
