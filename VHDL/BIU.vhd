--
--  Entity for the CPU Bus Interface Unit.  This includes
--  address and data bus in and out as well as control signals.
--
--  Currently, the CPU is the only bus master allowed.  This is
--  to simplify things.
--
--  There are two sides to the BIU - the internal side to interface
--  with the CPU items and the external side to interface with the
--  outside devices and memory.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
--
--  Note that the cpu_bus_ctrl datatype is defined with 32 bit address and data bus
--  size.  This really should be a constrained record, but it appears not to be
--  supported in this tool.
--
entity bus_interface is
  generic(addr_size : natural; data_size : natural);
  port(clock        : in std_logic;
       cpu_bus      : out work.typedefs.cpu_bus_ctrl;
		 cpu_bus_ret  : in work.typedefs.cpu_bus_ret;
       data_in_int  : in std_logic_vector (data_size-1 downto 0);
       data_out_int : out std_logic_vector (data_size-1 downto 0);
		 addr_in_int  : in std_logic_vector (addr_size-1 downto 0);
		 read_int     : in std_logic;  --  Request from CPU to read
		 write_int    : in std_logic;  --  Request from CPU to write
		 busy         : out std_logic;  --  Tell CPU request in progress
		 ready        : out std_logic);  --  Tell CPU read data is ready
--
end entity;

architecture rtl of bus_interface is
  type states is (state_null, state_read_start, state_read_wait, state_write);
  signal state : states := state_null;
  signal next_state : states := state_null;
begin
  --
  --  Transition states on the rising edge of a clock signal
  --
  state_advance: process(clock)
  begin
    if rising_edge(clock) then
      state <= next_state;
    end if;
  end process state_advance;

  biu_state_machine: process(state, read_int, write_int)
  begin
    case state is
	   when state_null =>  --  Wait for request from CPU
		  cpu_bus.read_cmd <= '0';
		  cpu_bus.write_cmd <= '0';
		  busy <= '0';
		  ready <= '0';
		  cpu_bus.data <= (others => '0');
		  data_out_int <= (others => '0');
		  cpu_bus.addr <= (others => '0');
		  if read_int = '1' then
		    next_state <= state_read_start;
		  elsif write_int = '1' then
		    next_state <= state_write;
		  else
		    next_state <= state_null;
		  end if;
		when state_read_start =>  --  Start a read request
		  cpu_bus.addr <= addr_in_int;
		  cpu_bus.read_cmd <= '1';
		  busy <= '1';
		  next_state <= state_read_wait;
		when state_read_wait =>  --  Finish a read request
		  if ack = '1' then
		    data_out_int <= cpu_bus_ret.data;
			 ready <= '1';
			 next_state <= state_null;
		  else
		    next_state <= state_read_wait;
		  end if;
		when state_write =>  --  Start a write request
		  cpu_bus.addr <= addr_in_int;
		  cpu_bus.data <= data_in_int;
		  cpu_bus.write_cmd <= '1';
		  if ack = '1' then
		    next_state <= state_null;
		  else
		    next_state <= state_write;
		  end if;
		when others =>  --  Should never get here.  Set everthing to a sane state and try again.
		  cpu_bus.read_cmd <= '0';
		  cpu_bus.write_cmd <= '0';
		  busy <= '0';
		  ready <= '0';
		  cpu_bus.data <= (others => '0');
		  data_out_int <= (others => '0');
		  cpu_bus.addr <= (others => '0');
		  next_state <= state_null;
	 end case;
  end process;
end rtl;

