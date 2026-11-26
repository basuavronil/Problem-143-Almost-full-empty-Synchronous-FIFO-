`timescale 1ns / 1ps

module tb_sync_fifo;

    reg        clk = 1'b0;
    reg        rst;
    reg        wr_en;
    reg        rd_en;
    reg  [7:0] data_in;
    wire [7:0] data_out;
    wire       empty, full, almost_empty, almost_full;

    sync_fifo dut (
        .clk(clk), .rst(rst),
        .wr_en(wr_en), .rd_en(rd_en),
        .data_in(data_in), .data_out(data_out),
        .empty(empty), .full(full),
        .almost_empty(almost_empty), .almost_full(almost_full)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Reference model (independent of the DUT's pointers/flags)
    // ------------------------------------------------------------
    reg [7:0] m_mem [0:15];
    reg [3:0] m_wp, m_rp;
    integer   m_cnt;
    reg [7:0] exp_data;
    integer   do_wr, do_rd;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            m_wp = 0; m_rp = 0; m_cnt = 0; exp_data = 8'd0;
        end else begin
            do_wr = (wr_en && m_cnt < 16);
            do_rd = (rd_en && m_cnt > 0);
            if (do_wr) begin m_mem[m_wp] = data_in;   m_wp = m_wp + 1; end
            if (do_rd) begin exp_data    = m_mem[m_rp]; m_rp = m_rp + 1; end
            m_cnt = m_cnt + do_wr - do_rd;
        end
    end

    // ------------------------------------------------------------
    // Checker: runs every negedge (outputs are stable by then)
    // ------------------------------------------------------------
    integer errors = 0;
    reg     checking = 1'b0;

    // Coverage counters
    integer seen_full = 0, seen_empty = 0, seen_afull = 0, seen_aempty = 0;

    always @(negedge clk) if (checking) begin
        if (data_out !== exp_data) begin
            errors = errors + 1;
            $display("[%0t] ERROR data_out=%0h expected=%0h", $time, data_out, exp_data);
        end
        if (empty !== (m_cnt == 0)) begin
            errors = errors + 1;
            $display("[%0t] ERROR empty=%b, count=%0d", $time, empty, m_cnt);
        end
        if (full !== (m_cnt == 16)) begin
            errors = errors + 1;
            $display("[%0t] ERROR full=%b, count=%0d", $time, full, m_cnt);
        end
        if (almost_empty !== (m_cnt <= 2)) begin
            errors = errors + 1;
            $display("[%0t] ERROR almost_empty=%b, count=%0d", $time, almost_empty, m_cnt);
        end
        if (almost_full !== (m_cnt >= 14)) begin
            errors = errors + 1;
            $display("[%0t] ERROR almost_full=%b, count=%0d", $time, almost_full, m_cnt);
        end
        if (full)         seen_full   = seen_full   + 1;
        if (empty)        seen_empty  = seen_empty  + 1;
        if (almost_full)  seen_afull  = seen_afull  + 1;
        if (almost_empty) seen_aempty = seen_aempty + 1;
    end

    // ------------------------------------------------------------
    // Tasks (all called while aligned to a negedge)
    // ------------------------------------------------------------
    task push(input [7:0] d);
        begin
            wr_en = 1; rd_en = 0; data_in = d;
            @(negedge clk);
            wr_en = 0;
        end
    endtask

    task pop;
        begin
            rd_en = 1; wr_en = 0;
            @(negedge clk);
            rd_en = 0;
        end
    endtask

    task push_pop(input [7:0] d);   // simultaneous read + write
        begin
            wr_en = 1; rd_en = 1; data_in = d;
            @(negedge clk);
            wr_en = 0; rd_en = 0;
        end
    endtask

    task idle(input integer n);
        integer k;
        begin
            wr_en = 0; rd_en = 0;
            for (k = 0; k < n; k = k + 1) @(negedge clk);
        end
    endtask

    task do_reset;
        begin
            rst = 0; wr_en = 0; rd_en = 0;
            @(negedge clk); @(negedge clk);
            rst = 1;
            @(negedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------
    integer i;
    integer mode;

    initial begin
        $dumpfile("tb_sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);

        rst = 0; wr_en = 0; rd_en = 0; data_in = 0;
        @(negedge clk); @(negedge clk);
        rst = 1;
        @(negedge clk);
        checking = 1;

        // ---- Test 1: state after reset
        $display("--- Test 1: reset state");
        if (!empty || full || !almost_empty || almost_full) begin
            errors = errors + 1;
            $display("ERROR: bad flags after reset");
        end
        idle(2);

        // ---- Test 2: fill completely (watch almost_full at 14, full at 16)
        $display("--- Test 2: fill to full");
        for (i = 0; i < 16; i = i + 1) push(8'hA0 + i);
        idle(2);

        // ---- Test 3: overflow attempts (must be ignored)
        $display("--- Test 3: write while full");
        for (i = 0; i < 4; i = i + 1) push(8'hFF);
        idle(1);

        // ---- Test 4: drain completely (watch almost_empty at 2, empty at 0)
        $display("--- Test 4: drain to empty");
        for (i = 0; i < 16; i = i + 1) pop;
        idle(2);

        // ---- Test 5: underflow attempts (must be ignored)
        $display("--- Test 5: read while empty");
        for (i = 0; i < 4; i = i + 1) pop;
        idle(1);

        // ---- Test 6: simultaneous read/write when empty (write only)
        $display("--- Test 6: push_pop on empty");
        push_pop(8'h11);
        push_pop(8'h22);
        idle(1);

        // ---- Test 7: simultaneous read/write at mid occupancy
        $display("--- Test 7: push_pop mid-level");
        for (i = 0; i < 6; i = i + 1) push(8'h30 + i);
        for (i = 0; i < 20; i = i + 1) push_pop(8'h50 + i);
        idle(1);

        // ---- Test 8: simultaneous read/write when full (read only)
        $display("--- Test 8: push_pop on full");
        while (!full) push(8'h77);
        push_pop(8'h88);
        idle(1);
        while (!empty) pop;
        idle(1);

        // ---- Test 9: pointer wrap-around (many fill/drain cycles)
        $display("--- Test 9: wrap-around");
        for (i = 0; i < 5; i = i + 1) begin
            repeat (10) push($random);
            repeat (10) pop;
        end
        idle(1);

        // ---- Test 10: reset in the middle of operation
        $display("--- Test 10: mid-operation reset");
        repeat (9) push($random);
        do_reset;
        if (!empty) begin
            errors = errors + 1;
            $display("ERROR: FIFO not empty after mid-operation reset");
        end
        push(8'hC3); pop;
        idle(1);

        // ---- Test 11: randomized traffic with alternating bias
        $display("--- Test 11: random traffic");
        for (i = 0; i < 3000; i = i + 1) begin
            mode = (i / 200) % 3;     // 0: write-heavy, 1: read-heavy, 2: balanced
            case (mode)
                0: begin wr_en = ({$random} % 10) < 8; rd_en = ({$random} % 10) < 2; end
                1: begin wr_en = ({$random} % 10) < 2; rd_en = ({$random} % 10) < 8; end
                default: begin wr_en = $random; rd_en = $random; end
            endcase
            data_in = $random;
            @(negedge clk);
        end
        wr_en = 0; rd_en = 0;
        idle(2);

        // ---- Summary
        $display("");
        $display("Coverage: full=%0d empty=%0d almost_full=%0d almost_empty=%0d cycles",
                 seen_full, seen_empty, seen_afull, seen_aempty);
        if (errors == 0) $display("*** TEST PASSED ***");
        else             $display("*** TEST FAILED: %0d errors ***", errors);
        $finish;
    end

    // Watchdog
    initial begin
        #2000000;
        $display("*** TIMEOUT ***");
        $finish;
    end

endmodule
