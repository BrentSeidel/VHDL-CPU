--
--  This is a development project for experimenting with various things.
--
--  Note that the signal list was copied from an Arduino forum post
--  in this thread https://forum.arduino.cc/t/how-to-code-and-run-vhdl-examples/561115/11
--
library ieee;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
use ieee.Numeric_Std.all;

entity Development is
port
(
-- system signals
iCLK : in std_logic ;

iRESETn :in std_logic ;
iSAM_INT: in std_logic ;
--oSAM_INT : out std_logic ;

-- SDRAM
--oSDRAM_CLK : out std_logic ;
--oSDRAM_ADDR : out std_logic_vector (11 downto 0 );
--oSDRAM_BA : out std_logic_vector (1 downto 0 );
--oSDRAM_CASn : out std_logic ;
--oSDRAM_CKE : out std_logic ;
--oSDRAM_CSn : out std_logic ;
--bSDRAM_DQ : inout std_logic_vector (15 downto 0 );
--oSDRAM_DQM : out std_logic_vector (1 downto 0 );
--oSDRAM_RASn : out std_logic ;
--oSDRAM_WEn : out std_logic ;

-- Mini PCIe
-- bPEX_RST : inout std_logic ;
-- bPEX_PIN6 : inout std_logic ;
-- bPEX_PIN8 : inout std_logic ;
-- bPEX_PIN10 : inout std_logic ;
-- iPEX_PIN11 : in std_logic ;
-- bPEX_PIN12 : inout std_logic ;
-- iPEX_PIN13 : in std_logic ;
-- bPEX_PIN14 : inout std_logic ;
-- bPEX_PIN16 : inout std_logic ;
-- bPEX_PIN20 : inout std_logic ;
-- iPEX_PIN23 : in std_logic ;
-- iPEX_PIN25 : in std_logic ;
-- bPEX_PIN28 : inout std_logic ;
-- bPEX_PIN30 : inout std_logic ;
-- iPEX_PIN31 : in std_logic ;
-- bPEX_PIN32 : inout std_logic ;
-- iPEX_PIN33 : in std_logic ;
-- bPEX_PIN42 : inout std_logic ;
-- bPEX_PIN44 : inout std_logic ;
-- bPEX_PIN45 : inout std_logic ;
-- bPEX_PIN46 : inout std_logic ;
-- bPEX_PIN47 : inout std_logic ;
-- bPEX_PIN48 : inout std_logic ;
-- bPEX_PIN49 : inout std_logic ;
-- bPEX_PIN51 : inout std_logic ;

-- NINA interface
-- bWM_PIO1 : inout std_logic ;
-- bWM_PIO2 : inout std_logic ;
-- bWM_PIO3 : inout std_logic ;
-- bWM_PIO4 : inout std_logic ;
-- bWM_PIO5 : inout std_logic ;
-- bWM_PIO7 : inout std_logic ;
-- bWM_PIO8 : inout std_logic ;
-- bWM_PIO18 : inout std_logic ;
-- bWM_PIO20 : inout std_logic ;
-- bWM_PIO21 : inout std_logic ;
-- bWM_PIO27 : inout std_logic ;
-- bWM_PIO28 : inout std_logic ;
-- bWM_PIO29 : inout std_logic ;
-- bWM_PIO31 : inout std_logic ;
-- iWM_PIO32 : in std_logic ;
-- bWM_PIO34 : inout std_logic ;
-- bWM_PIO35 : inout std_logic ;
-- bWM_PIO36 : inout std_logic ;
-- iWM_TX : in std_logic ;
-- oWM_RX : inout std_logic ;
-- oWM_RESET : inout std_logic ;

-- HDMI output
-- oHDMI_TX : out std_logic_vector (2 downto 0 );
-- oHDMI_CLK : out std_logic ;

-- bHDMI_SDA : inout std_logic ;
-- bHDMI_SCL : inout std_logic ;

-- iHDMI_HPD : in std_logic ;

-- MIPI input
-- iMIPI_D : in std_logic_vector (1 downto 0 );
-- iMIPI_CLK : in std_logic ;
-- bMIPI_SDA : inout std_logic ;
-- bMIPI_SCL : inout std_logic ;
-- bMIPI_GP : inout std_logic_vector (1 downto 0 );

--// Q-SPI Flash interface
-- oFLASH_SCK : out std_logic ;
-- oFLASH_CS : out std_logic ;
-- oFLASH_MOSI : inout std_logic ;
-- iFLASH_MISO : inout std_logic ;
-- oFLASH_HOLD : inout std_logic ;
-- oFLASH_WP : inout std_logic;

-- SAM D21 PINS
bMKR_AREF : inout std_logic ;
bMKR_A : inout std_logic_vector (6 downto 0);
bMKR_D : inout std_logic_vector (14 downto 0)

);
end Development ;
--
--  Memory map
--  Addr  Usage
--    0   Reg0
--    1   Reg1
--    2   Reg2
--    3   ALU Op 1
--    4   ALU Op 2
--    5   ALU Func
--    6   ALU Flags
--    7   ALU Result
--    8   Counter LSB
--    9   Counter MSB
--
architecture rtl of Development is
--
--  Translate the physical pins into internal signals
--
  signal addr_bus  : work.typedefs.byte;
  signal write_reg : boolean;
  signal read_reg  : boolean;
--
--  Some constants
--
  constant max_reg : work.typedefs.byte := 24;  --  Number of assigned registers
begin
  addr_bus <= work.typedefs.vec_to_byte(bMKR_D(14 downto 8));
  write_reg <= (bMKR_A(0) = '1');
  read_reg  <= (bMKR_A(1) = '1');
  --
  --  Define some registers
  --
  reg0 : entity work.Reg8
    generic map(location => 0)
    port map (data => bMKR_D(7 downto 0),
	           out_enable => read_reg, set => write_reg, addr => addr_bus);
  reg1 : entity work.Reg8
    generic map(location => 1)
    port map (data => bMKR_D(7 downto 0),
	           out_enable => read_reg, set => write_reg, addr => addr_bus);
  reg2 : entity work.Reg8
    generic map(location => 2)
    port map (data => bMKR_D(7 downto 0),
	           out_enable => read_reg, set => write_reg, addr => addr_bus);
  alu8 : entity work.ALU8
    generic map(location => 3)
	 port map(data => bMKR_D(7 downto 0),
	           out_enable => read_reg, set => write_reg, addr => addr_bus);
  counter : entity work.Counter
    generic map(location => 8)
	 port map(data => bMKR_D(7 downto 0),
	           out_enable => read_reg, set => write_reg, addr => addr_bus, clock => iCLK);
  cpu32 : entity work.CPU32
    generic map(location => 10)
	 port map(data => bMKR_D(7 downto 0),
	           out_enable => read_reg, set => write_reg, addr => addr_bus);
	--
	--  Define values for unassigned addresses.  The value returned is simply
	--  the address value.  Writes are ignored.
	--
	data_bus : process(read_reg, write_reg, addr_bus)
	begin
		if write_reg then
			bMKR_D(7 downto 0) <= (others => 'Z');
		elsif read_reg and (addr_bus > max_reg) then
			bMKR_D(7 downto 0) <= work.typedefs.byte_to_vec(addr_bus);
		else
			bMKR_D(7 downto 0) <= (others => 'Z');
		end if;
	end process data_bus;

	end rtl;

