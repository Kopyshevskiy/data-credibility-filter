library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_start : in std_logic;
        i_add   : in std_logic_vector(15 downto 0);
        i_k     : in std_logic_vector(9 downto 0);
        
        o_done  : out std_logic;
        
        o_mem_addr  : out std_logic_vector(15 downto 0);
        i_mem_data  : in std_logic_vector(7 downto 0);
        o_mem_data  : out std_logic_vector(7 downto 0);
        o_mem_we    : out std_logic;
        o_mem_en    : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    signal mux_addr,curr_addr : std_logic_vector(15 downto 0);
    signal addr_sel,data_sel,addr_load,datareg_load,is_word_zero,is_cred_zero,mem_sel,rp_init,rp_load,cred_sel,cred_load,k_sel,rk_load,done,en,we,last  : std_logic;
    signal o_datareg,o_mux1,o_mux2,o_mux3,o_mux4,o_regpr,o_credreg    : std_logic_vector(7 downto 0);
    signal o_mux6,o_regk : std_logic_vector(9 downto 0);
    type S is (S0, S1, S2, S3, S4, S5, S6, S7);
    signal cur_state,next_state : S;
    

begin

    -- output assignment
    o_done <= done;
    o_mem_en <= en;
    o_mem_we <= we;

    -- addressreg process
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            curr_addr <= (others => '0');
        elsif rising_edge(i_clk) then
            if addr_load = '1' then
                curr_addr <= mux_addr;
            end if;
        end if;
    end process;
    
    -- address_selection process
    process(addr_sel, i_add, curr_addr)
    begin
        case addr_sel is
            when '0' => mux_addr <= i_add;
            when '1' => mux_addr <= std_logic_vector(unsigned(curr_addr) + 2);
            when others => mux_addr <= (others => 'X');
        end case;
    end process;
    
   -- datareg process
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            o_datareg <= (others => '0');
        elsif rising_edge(i_clk) then
            if datareg_load = '1' then
                if data_sel = '0' then
                    o_datareg <= i_mem_data;
                else
                    o_datareg <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    --wordcomp process
    process(i_rst,o_datareg)
    begin
        if i_rst = '1' then
            is_word_zero <= '0';
        else
            if o_datareg = "00000000" then
                is_word_zero <= '1';
            else
                is_word_zero <= '0';
            end if;
        end if;
    end process;
    
    -- address_to_write_mux process
--    process(mem_sel,curr_addr)
  --  begin
    --    case mem_sel is
    --        when '0' => o_mem_addr <= curr_addr;
      --      when '1' => o_mem_addr <= std_logic_vector(unsigned(curr_addr) + 1);
        --    when others => o_mem_addr <= (others => 'X');
   --     end case;
    --end process;
    
    -- data_to_write_mux process
    process(mem_sel, we, en, o_mux1, o_credreg)
    begin
        o_mem_data <= (others => '0');
        if we = '1' and en = '1' then
            case mem_sel is
                when '0' => 
                    o_mem_data <= o_mux1;
                when '1' => 
                    o_mem_data <= o_credreg;
                when others => o_mem_data <= (others => 'X');
            end case;
        end if;
    end process;
    
    -- mux1 process
    process(o_datareg,o_regpr,is_word_zero)
    begin
        case is_word_zero is
            when '0' => o_mux1 <= o_datareg;
            when '1' => o_mux1 <= o_regpr;
            when others => o_mux1 <= (others => 'X');
        end case;
    end process;
    
-- regpreviousword process
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            o_regpr <= (others => '0');
        elsif rising_edge(i_clk) then
            if rp_load = '1' then
                if rp_init = '0' then
                    o_regpr <= o_datareg;
                else
                    o_regpr <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
 -- rp_load process
    process(rp_init,is_word_zero)
    begin
        rp_load <= rp_init or not is_word_zero;
    end process;
    
 -- mux5 process
--    process(rp_init,o_datareg)
--    begin
--        case rp_init is
--            when '0' => o_mux5 <= o_datareg;
--            when '1' => o_mux5 <= (others => '0');
--            when others => o_mux1 <= (others => 'X');
--        end case;
--    end process;

 -- credreg process
     process(i_clk, i_rst)
     begin
         if i_rst = '1' then
             o_credreg <= (others => '0');
         elsif rising_edge(i_clk) then
            if cred_load = '1' then
                o_credreg <= o_mux3;
            end if;
         end if; 
     end process;
     
 -- mux2 process
    process(is_word_zero,o_mux4)
        begin
            case is_word_zero is
            when '0' => o_mux2 <= "00011111";
            when '1' => o_mux2 <= o_mux4;                    
            when others => o_mux2 <= (others => 'X');
        end case;
    end process;
        
 -- mux3 process
    process(cred_sel,o_mux2)
        begin
            case cred_sel is
            when '0' => o_mux3 <= o_mux2;
            when '1' => o_mux3 <= (others => '0');
            when others => o_mux3 <= (others => 'X');
        end case;
    end process;   
 
 -- mux4 process
   process(is_cred_zero,o_credreg)
       begin
           case is_cred_zero is
           when '0' => o_mux4 <= std_logic_vector(unsigned(o_credreg) - 1);
           when '1' => o_mux4 <= (others => '0');
           when others => o_mux4 <= (others => 'X');
       end case;
   end process;
    
    --credcomp process
    process(i_clk,i_rst)
    begin
        if i_rst = '1' then
            is_cred_zero <= '0';
        elsif rising_edge(i_clk) then
            if o_credreg = "00000000" then
                is_cred_zero <= '1';
            else
                is_cred_zero <= '0';
            end if;
        end if;
    end process;
    
 -- regk process
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            o_regk <= (others => '1');
        elsif rising_edge(i_clk) then
            if rk_load = '1' then
                o_regk <= o_mux6;
            end if;
        end if;
    end process;
    
 -- mux6 process
      process(k_sel,i_k,o_regk)
      begin
          case k_sel is
              when '0' => o_mux6 <= i_k;
              when '1' => o_mux6 <= std_logic_vector(unsigned(o_regk) - 1);
              when others => o_mux6 <= (others => 'X');
          end case;
        end process;
        
 -- finalcomp process
     process(o_regk,i_rst)
     begin
         if i_rst = '1' then
             last <= '0';
         else
            if o_regk = "0000000001" then
                last <= '1';
            else
                last <= '0';
             end if;
         end if;
     end process;
     
 -- cur_state process
    process(i_rst,i_clk)
    begin
        if i_rst = '1' then
            cur_state <= S0;
        elsif rising_edge(i_clk) then
            cur_state <= next_state;
        end if;
    end process;   
     
 -- next_state process
    process(cur_state,i_start,done)
    begin
        next_state <= cur_state;
    case cur_state is
        when S0 =>
            if i_start = '1' then
                next_state <= S1;
            end if;
        when S1 =>
            if i_k = "0000000000" then
                next_state <= S7;
            else
                next_state <= S3;
            end if;
        when S2 =>
            next_state <= S3;
        when S3 =>
            next_state <= S4;
        when S4 =>
            next_state <= S5;
        when S5 =>
            next_state <= S6;
        when S6 =>
            if last = '0' then
                next_state <= S2;
            else
                next_state <= S7;
            end if;
        when S7 =>
            if i_start <= '0' then
                next_state <= S0;
            end if;
        when others =>
            next_state <= S0;
        end case;
    end process;
    
    -- signals process
    process(cur_state)
    begin 
        data_sel <= '0';
        addr_sel <= '1';
        addr_load <= '0';
        cred_sel <= '0';
        cred_load <= '0';
        rp_init <= '0';
        en <= '0';
        we <= '0';
        datareg_load <= '0';
        mem_sel <= '0';
        k_sel <= '1';
        rk_load <= '0';
        done <= '0';
        o_mem_addr <= (others => '0');
        case cur_state is            
            when S0 =>
            when S1 =>
                data_sel <= '1';
                k_sel <= '0';
                addr_sel <= '0';
                rk_load <= '1';
                addr_load <= '1';
                cred_sel <= '1';
                cred_load <= '1';
                datareg_load <= '1';
                rp_init <= '1';
            when S2 =>
                addr_load <= '1';
            when S3 =>
                o_mem_addr <= curr_addr;
                en <= '1';
            when S4 =>
                datareg_load <= '1';
            when S5 =>
                cred_load <= '1';
                o_mem_addr <= curr_addr;
                en <= '1';
                we <= '1';
            when S6 =>
                o_mem_addr <= std_logic_vector(unsigned(curr_addr) + 1);
                mem_sel <= '1';
                en <= '1';
                we <= '1';
                rk_load <= '1';
            when S7 =>
                done <= '1';
            when others =>
                null;
        end case;
    end process;  
end Behavioral;
