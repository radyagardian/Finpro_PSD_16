library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SlotMachine_Advanced is
    Port ( 
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        coin_in       : in  INTEGER range 0 to 1000;
        spin_trig     : in  STD_LOGIC;
        admin_cheat   : in  STD_LOGIC;
        reel1_val     : out INTEGER range 0 to 9;
        reel2_val     : out INTEGER range 0 to 9;
        reel3_val     : out INTEGER range 0 to 9;
        credit_saldo  : out INTEGER;
        game_status   : out STD_LOGIC_VECTOR(2 downto 0)
    );
end SlotMachine_Advanced;

architecture Behavioral of SlotMachine_Advanced is

    type Reel_Array is array (1 to 3) of INTEGER range 0 to 9;
    signal reels : Reel_Array := (0, 0, 0);

    type State_Type is (IDLE, SPINNING, STOPPING, EVALUATE, PAYOUT);
    signal current_state : State_Type := IDLE;

    signal internal_credit : INTEGER := 0;
    signal spin_timer      : INTEGER := 0;
    signal lfsr_reg        : STD_LOGIC_VECTOR(15 downto 0) := x"ACE1";
    signal rand_val        : INTEGER range 0 to 9;

    function calculate_reward(current_reels : Reel_Array; bet_cost : integer) return integer is
    begin
        if (current_reels(1) = 7) and (current_reels(2) = 7) and (current_reels(3) = 7) then
            return 500;
        elsif (current_reels(1) = current_reels(2)) and (current_reels(2) = current_reels(3)) then
            return 100;
        elsif (current_reels(1) = current_reels(2)) or (current_reels(2) = current_reels(3)) or (current_reels(1) = current_reels(3)) then
            return 20;
        else
            return 0;
        end if;
    end function;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
            internal_credit <= 0;
            lfsr_reg <= x"ACE1";
            reels <= (0, 0, 0);
            game_status <= "000";
            
        elsif rising_edge(clk) then
            
            lfsr_reg(15 downto 1) <= lfsr_reg(14 downto 0);
            lfsr_reg(0) <= lfsr_reg(15) XOR lfsr_reg(13) XOR lfsr_reg(12) XOR lfsr_reg(10);
            rand_val <= to_integer(unsigned(lfsr_reg(3 downto 0))) mod 10;

            case current_state is
            
                when IDLE =>
                    game_status <= "000";
                    if coin_in > 0 then
                        internal_credit <= internal_credit + coin_in;
                        
                        report "[DESIGN] Coin Accepted. Current Credit: " & integer'image(internal_credit + coin_in);
                    end if;
                    
                    if spin_trig = '1' and internal_credit >= 10 then
                        internal_credit <= internal_credit - 10;
                        spin_timer <= 0;
                        current_state <= SPINNING;
                        
                        report "[DESIGN] Spin Triggered! Deducting 10 credits.";
                    end if;

                when SPINNING =>
                    game_status <= "001";
                    spin_timer <= spin_timer + 1;
                    
                    reels(1) <= (reels(1) + 1) mod 10; 
                    reels(2) <= (reels(2) + rand_val) mod 10;
                    reels(3) <= (reels(3) + 2) mod 10;
                    
                    if spin_timer > 10 then
                        current_state <= STOPPING;
                    end if;

                when STOPPING =>
                    if admin_cheat = '1' then
                        reels <= (7, 7, 7);
                        
                        report "[DESIGN] ADMIN CHEAT DETECTED! Forcing Jackpot.";
                    else
                        reels(1) <= to_integer(unsigned(lfsr_reg(3 downto 0))) mod 10;
                        reels(2) <= to_integer(unsigned(lfsr_reg(7 downto 4))) mod 10;
                        reels(3) <= to_integer(unsigned(lfsr_reg(11 downto 8))) mod 10;
                    end if;
                    current_state <= EVALUATE;

                when EVALUATE =>
                    internal_credit <= internal_credit + calculate_reward(reels, 10);
                    current_state <= PAYOUT;

                when PAYOUT =>
                    if calculate_reward(reels, 10) > 0 then
                        game_status <= "111";
                        
                        report "[DESIGN] WINNER! Reward: " & integer'image(calculate_reward(reels, 10));
                    else
                        game_status <= "100";
                        
                        report "[DESIGN] No Win.";
                    end if;
                    current_state <= IDLE;

            end case;
        end if;
    end process;

    credit_saldo <= internal_credit;
    reel1_val <= reels(1);
    reel2_val <= reels(2);
    reel3_val <= reels(3);

end Behavioral;
