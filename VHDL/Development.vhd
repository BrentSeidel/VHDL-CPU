--
--  This is a development project for experimenting with various things.
--
--  Note that the signal list was copied from an Arduino forum post
--  in this thread https://forum.arduino.cc/t/how-to-code-and-run-vhdl-examples/561115/11
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.Numeric_Std.all;

entity Development is
port
(
-- system signals
iCLK : in std_logic;  --  I found a forum post stating that this is 48MHz

--iRESETn  : in std_logic;
--iSAM_INT : in std_logic;
--oSAM_INT : out std_logic;

-- SDRAM
--oSDRAM_CLK : out std_logic;
--oSDRAM_ADDR : out std_logic_vector (11 downto 0 );
--oSDRAM_BA : out std_logic_vector (1 downto 0 );
--oSDRAM_CASn : out std_logic;
--oSDRAM_CKE : out std_logic;
--oSDRAM_CSn : out std_logic;
--bSDRAM_DQ : inout std_logic_vector (15 downto 0 );
--oSDRAM_DQM : out std_logic_vector (1 downto 0 );
--oSDRAM_RASn : out std_logic;
--oSDRAM_WEn : out std_logic;

-- Mini PCIe
-- bPEX_RST : inout std_logic;
-- bPEX_PIN6 : inout std_logic;
-- bPEX_PIN8 : inout std_logic;
-- bPEX_PIN10 : inout std_logic;
-- iPEX_PIN11 : in std_logic;
-- bPEX_PIN12 : inout std_logic;
-- iPEX_PIN13 : in std_logic;
-- bPEX_PIN14 : inout std_logic;
-- bPEX_PIN16 : inout std_logic;
-- bPEX_PIN20 : inout std_logic;
-- iPEX_PIN23 : in std_logic;
-- iPEX_PIN25 : in std_logic;
-- bPEX_PIN28 : inout std_logic;
-- bPEX_PIN30 : inout std_logic;
-- iPEX_PIN31 : in std_logic;
-- bPEX_PIN32 : inout std_logic;
-- iPEX_PIN33 : in std_logic;
-- bPEX_PIN42 : inout std_logic;
-- bPEX_PIN44 : inout std_logic;
-- bPEX_PIN45 : inout std_logic;
-- bPEX_PIN46 : inout std_logic;
-- bPEX_PIN47 : inout std_logic;
-- bPEX_PIN48 : inout std_logic;
-- bPEX_PIN49 : inout std_logic;
-- bPEX_PIN51 : inout std_logic;

-- NINA interface
-- bWM_PIO1 : inout std_logic;
-- bWM_PIO2 : inout std_logic;
-- bWM_PIO3 : inout std_logic;
-- bWM_PIO4 : inout std_logic;
-- bWM_PIO5 : inout std_logic;
-- bWM_PIO7 : inout std_logic;
-- bWM_PIO8 : inout std_logic;
-- bWM_PIO18 : inout std_logic;
-- bWM_PIO20 : inout std_logic;
-- bWM_PIO21 : inout std_logic;
-- bWM_PIO27 : inout std_logic;
-- bWM_PIO28 : inout std_logic;
-- bWM_PIO29 : inout std_logic;
-- bWM_PIO31 : inout std_logic;
-- iWM_PIO32 : in std_logic;
-- bWM_PIO34 : inout std_logic;
-- bWM_PIO35 : inout std_logic;
-- bWM_PIO36 : inout std_logic;
-- iWM_TX : in std_logic;
-- oWM_RX : inout std_logic;
-- oWM_RESET : inout std_logic;

-- HDMI output
-- oHDMI_TX : out std_logic_vector (2 downto 0 );
-- oHDMI_CLK : out std_logic;

-- bHDMI_SDA : inout std_logic;
-- bHDMI_SCL : inout std_logic;

-- iHDMI_HPD : in std_logic;

-- MIPI input
-- iMIPI_D : in std_logic_vector (1 downto 0 );
-- iMIPI_CLK : in std_logic;
-- bMIPI_SDA : inout std_logic;
-- bMIPI_SCL : inout std_logic;
-- bMIPI_GP : inout std_logic_vector (1 downto 0 );

--// Q-SPI Flash interface
-- oFLASH_SCK  : out std_logic;
-- oFLASH_CS   : out std_logic;
-- oFLASH_MOSI : inout std_logic;
-- iFLASH_MISO : inout std_logic;
-- oFLASH_HOLD : inout std_logic;
-- oFLASH_WP   : inout std_logic;

-- SAM D21 PINS
bMKR_AREF : inout std_logic;
bMKR_A : inout std_logic_vector (6 downto 0);
bMKR_D : inout std_logic_vector (14 downto 0)

);
end Development ;
--
--  Memory map
--  Addr  Usage
--    0   Counter LSB
--    1   Counter MSB
--    2+  CPU32 registers
--      0    R/W   Write data bits 7-0
--      1    R/W   Write data bits 15-8
--      2    R/W   Write data bits 23-16
--      3    R/W   Write data bits 31-24
--      4     RO   Read data bits 7-0
--      5     RO   Read data bits 15-8
--      6     RO   Read data bits 23-16
--      7     RO   Read data bits 31-24
--      8    R/W   Raddr 1 (bits 7-4) Raddr 2 (bits 3-0)
--      9    R/W   Raddr 3 (bits 7-4)
--     10    R/W   Waddr (bits 3-0)
--     11    R/W   ALU function
--     12    R/W   ALU flags
--     13    R/W   Enables
--                 2 - Enable read
--                 1 - Enable write
--                 0 - Start state machine
--
architecture rtl of Development is
--
--  Translate the physical pins into internal signals
--
  signal data_in    : std_logic_vector (7 downto 0);  --  Data in from host
  signal data_out   : std_logic_vector (7 downto 0);  --  Data out to host
  signal data_b1    : std_logic_vector (7 downto 0);  --  Internal daisy chain bus
  signal data_b2    : std_logic_vector (7 downto 0);  --  Internal daisy chain bus
  signal cpu_data1  : std_logic_vector (31 downto 0);
  signal cpu_data2  : std_logic_vector (31 downto 0);
  signal ack_chain1 : std_logic;
  signal slow_clock : std_logic;  --  Clock programmatically toggled by Arduino
  signal internal_clock : std_logic;
  signal host       : work.typedefs.host_bus_ctrl;
  signal cpu_bus    : work.typedefs.cpu_bus_ctrl;
  signal cpu_bus_ret1 : work.typedefs.cpu_bus_ret;
--
--  Some constants for register base addresses
--
  constant addr_count : natural := 0;
  constant addr_cpu   : natural := addr_count + 2;
  constant addr_ram   : natural := addr_cpu + 14;
begin
  --
  --  Start out with the I/O pins tri-stated.
  --
  bMKR_A <= (others => 'Z');
  bMKR_D(14) <= 'Z';
  bMKR_D(13) <= 'Z';
  bMKR_D(12) <= 'Z';
  bMKR_D(11) <= 'Z';
  bMKR_D(10) <= 'Z';
  bMKR_D(9) <= 'Z';
  bMKR_D(8) <= 'Z';
  bMKR_AREF <= 'Z';
  --
  --  Set the internal clock.  Everything uses this so it should be
  --  changed in only one spot.  The two options are:
  --  * iCLK - which seems to be a 48MHz clock
  --  * slow_clock, which comes from an output on the M0+ that is
  --    toggled under program control.
  --  * Possible PLL value, if needed.
  -- 
  --
  internal_clock <= iCLK;
--  internal_clock <= slow_clock;
  --
  --  Read signals from inputs and route to internal buses
  --
  slow_clock <= bMKR_A(2);
  data_in <= bMKR_D(7 downto 0);
  host <= (cmd_read => (bMKR_A(1) = '1'), cmd_write => (bMKR_A(0) = '1'),
           addr => work.typedefs.vec_to_byte(bMKR_D(14 downto 8)));
  bMKR_D(7 downto 0) <= data_out when (not host.cmd_write) and host.cmd_read else
                        (others => 'Z');
--
--  Instantiate the counter entity
--
  counter: entity work.Counter
    generic map(location => addr_count)
	 port map(data_in => data_in, data_out => data_b1,
	           host => host, clock => internal_clock);
--
--  Instantiate the CPU and test system
--
  cpu32: entity work.CPU32
    generic map(location => addr_cpu)
	 port map(data_in => data_b1, data_out => data_b2,
	           host => host,
				  cpu_bus => cpu_bus,
--				  cpu_bus_ret => (data => (others => '1'), ack => '1'),
				  cpu_bus_ret => cpu_bus_ret1,
				  clock => internal_clock);
--
--  Instantiate a RAM block
--
  ram1: entity work.ram_block
    generic map(cpu_location => (others => '0'), host_location => addr_ram)
    port map(cpu_bus => cpu_bus,
	          cpu_ret_out => cpu_bus_ret1,
				 cpu_ret_in => (data => (others => '0'), ack => '0'),
				 clock => internal_clock,
				 host_data_in => data_b2,
				 host_data_out => data_out,
				 host => host);
				 
end rtl;

