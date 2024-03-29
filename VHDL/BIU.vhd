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
		 read_cmd     : in std_logic;    --  Request from CPU to read
		 write_cmd    : in std_logic;    --  Request from CPU to write
		 busy         : out std_logic;   --  Tell CPU request in progress
		 ready        : out std_logic);  --  Tell CPU read data is ready
--
end entity;

architecture rtl of bus_interface is
  type states is (state_null, state_read_1, state_read_2, state_write_1, state_write_2);
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

  biu_state_machine: process(state, read_cmd, write_cmd)
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
		  if read_cmd = '1' then      --  Check for bus read command
		    next_state <= state_read_1;
		  elsif write_cmd = '1' then  --  Check for bus write command
		    next_state <= state_write_1;
		  else                        --  Otherwise keep waiting
		    next_state <= state_null;
		  end if;
		when state_read_1 =>  --  Start a read request
		  cpu_bus.addr <= addr_in_int;
		  cpu_bus.read_cmd <= '1';
		  busy <= '1';
		  data_out_int <= cpu_bus_ret.data;
		  next_state <= state_read_2;
		when state_read_2 =>  --  Finish a read request
		  cpu_bus.addr <= addr_in_int;
		  cpu_bus.read_cmd <= '1';
		  if cpu_bus_ret.ack = '1' then  --  Wait for an ack from the bus device
		    data_out_int <= cpu_bus_ret.data;
			 busy <= '1';
			 ready <= '1';
			 next_state <= state_null;
		  else
		    next_state <= state_read_2;
		  end if;
		when state_write_1 =>  --  Start a write request
		  cpu_bus.addr <= addr_in_int;
		  cpu_bus.data <= data_in_int;
		  cpu_bus.write_cmd <= '0';
		  next_state <= state_write_2;
		when state_write_2 =>  --  Finish a write request
		  cpu_bus.addr <= addr_in_int;
		  cpu_bus.data <= data_in_int;
		  cpu_bus.write_cmd <= '1';
		  if cpu_bus_ret.ack = '1' then
		    next_state <= state_null;
		  else
		    next_state <= state_write_2;
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

