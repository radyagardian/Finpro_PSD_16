library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity tb_SlotMachine is
end tb_SlotMachine;

architecture Behavioral of tb_SlotMachine is

    component SlotMachine_Advanced is
        Port ( 
            clk           : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            coin_in       : in  INTEGER;
            spin_trig     : in  STD_LOGIC;
            admin_cheat   : in  STD_LOGIC;
            reel1_val     : out INTEGER;
            reel2_val     : out INTEGER;
            reel3_val     : out INTEGER;
            credit_saldo  : out INTEGER;
            game_status   : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    signal clk, reset, spin_trig, admin_cheat : STD_LOGIC := '0';
    signal coin_in : INTEGER := 0;
    signal r1, r2, r3, credit : INTEGER;
    signal status : STD_LOGIC_VECTOR(2 downto 0);

    constant clk_period : time := 10 ns;

begin

    UUT: SlotMachine_Advanced 
    port map (
        clk => clk, reset => reset, coin_in => coin_in, 
        spin_trig => spin_trig, admin_cheat => admin_cheat,
        reel1_val => r1, reel2_val => r2, reel3_val => r3,
        credit_saldo => credit, game_status => status
    );

    clk_process : process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
        file input_file  : text open read_mode is "input_cmds.txt";
        file output_file : text open write_mode is "output_log.txt";
        variable line_in, line_out : line;
        
        variable cmd_code : integer;
        variable val_in   : integer;
        
    begin
        -- Initial Reset
        reset <= '1'; wait for 20 ns; reset <= '0';
        wait for 20 ns;

        report "=======================================";
        report "   STARTING SLOT MACHINE SIMULATION    ";
        report "=======================================";

        -- Header for file output
        write(line_out, string'("--- SIMULATION LOG START ---")); 
        writeline(output_file, line_out);

        while not endfile(input_file) loop
            readline(input_file, line_in);
            read(line_in, cmd_code);
            read(line_in, val_in);

            case cmd_code is
                when 1 =>
                    coin_in <= val_in;
                    wait for clk_period;
                    coin_in <= 0;
                    
                    
                    report "[TESTBENCH] Action: Inserting " & integer'image(val_in) & " coins.";
                    
                    
                    write(line_out, string'("ACTION: Insert Coin -> Total Credit: "));
                    write(line_out, credit); 
                    writeline(output_file, line_out);

                when 2 =>
                    
                    report "[TESTBENCH] Action: Pressing SPIN Button.";
                    
                    spin_trig <= '1';
                    wait for clk_period * 2;
                    spin_trig <= '0';
                    
                    wait for clk_period * 20; 
                    
                    
                    report "[TESTBENCH] Result: " & integer'image(r1) & "-" & integer'image(r2) & "-" & integer'image(r3);
                    
                   
                    write(line_out, string'("RESULT: Reels ["));
                    write(line_out, r1); write(line_out, string'("-"));
                    write(line_out, r2); write(line_out, string'("-"));
                    write(line_out, r3); write(line_out, string'("] "));
                    
                    if status = "111" then 
                        write(line_out, string'("WINNER! "));
                        report "[TESTBENCH] >>> JACKPOT WINNER! <<<";
                    else 
                        write(line_out, string'("LOST. ")); 
                        report "[TESTBENCH] You Lost.";
                    end if;
                    
                    write(line_out, string'("Current Credit: ")); write(line_out, credit);
                    writeline(output_file, line_out);

                when 3 =>
                    admin_cheat <= '1';
                    report "[TESTBENCH] *** ADMIN CHEAT ENABLED ***";
                    write(line_out, string'("ACTION: ADMIN CHEAT ENABLED"));
                    writeline(output_file, line_out);

                when 4 =>
                    admin_cheat <= '0';
                    report "[TESTBENCH] *** ADMIN CHEAT DISABLED ***";
                    write(line_out, string'("ACTION: ADMIN CHEAT DISABLED"));
                    writeline(output_file, line_out);

                when others => null;
            end case;

            wait for 20 ns;
        end loop;

        report "=======================================";
        report "    SIMULATION COMPLETED SUCCESSFULLY  ";
        report "=======================================";
        
        write(line_out, string'("--- SIMULATION END ---")); 
        writeline(output_file, line_out);
        wait;
    end process;

end Behavioral;
