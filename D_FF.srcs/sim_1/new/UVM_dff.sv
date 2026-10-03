`timescale 1ns/1ns

/*
UVM verification environment for a D filp-flop.
This envrionment consists of a driver, monitor, scoreboard and a sequence to generate transactions.
*/

`include "uvm_macros.svh"
import uvm_pkg::*;

interface dff_if(input logic clk);

logic reset;
logic d;
logic q;
logic q_bar;

endinterface : dff_if

// transaction class
class transaction extends uvm_sequence_item;

`uvm_object_utils(transaction);

function new(string name = "transaction");
super.new(name);
endfunction : new

rand bit d;
rand bit reset;
bit q;
bit q_bar;

endclass : transaction

// reset sequence class
class reset_sequence extends uvm_sequence #(transaction);

`uvm_object_utils(reset_sequence);

function new(string name = "reset_sequence");
super.new(name);
endfunction

task body();
transaction tx;
repeat(5) begin
tx = transaction::type_id::create("tx");
tx.randomize() with { reset == 1; };
start_item(tx);
finish_item(tx);
end
endtask

endclass : reset_sequence

// data sequence class
class data_sequence extends uvm_sequence #(transaction);

`uvm_object_utils(data_sequence);

function new(string name = "data_sequence");
super.new(name);
endfunction

task body();
transaction tx;
repeat(5) begin
tx = transaction::type_id::create("tx");
tx.randomize() with { reset == 0; };
start_item(tx);
finish_item(tx);
end
endtask

endclass : data_sequence

// driver class
class driver extends uvm_driver #(transaction);

virtual dff_if in;

`uvm_component_utils(driver);

function new(string name = "driver", uvm_component parent);
super.new(name, parent);
endfunction 

function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db #(virtual dff_if) :: get(this,"","vif",in)) `uvm_fatal("IMON", $sformatf("virtual interface never recieved"));
endfunction

task run_phase(uvm_phase phase);
transaction tx;
forever begin
seq_item_port.get_next_item(tx);
@(negedge in.clk);
in.d = tx.d;
in.reset = tx.reset;
`uvm_info("DRV", $sformatf("driving the payload which contains d=%0b, reset=%0b", tx.d, tx.reset), UVM_LOW);
seq_item_port.item_done();
end
endtask

endclass : driver

// output monitor class
class output_monitor extends uvm_monitor;

virtual dff_if in;
transaction tx;
uvm_analysis_port #(transaction) mon_to_scoreboard;

`uvm_component_utils(output_monitor);

function new(string name = "output_monitor", uvm_component parent);
super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db #(virtual dff_if) :: get(this,"","vif",in)) `uvm_fatal("OMON", $sformatf("virtual interface never recieved"));
mon_to_scoreboard = new("mon_to_scoreboard",this);
endfunction

task run_phase(uvm_phase phase);
forever begin
tx = transaction::type_id::create("tx");
@(negedge in.clk);
tx.q = in.q;
tx.q_bar = in.q_bar;
mon_to_scoreboard.write(tx);
`uvm_info("OMON", $sformatf("monitoring the output payload which contains q=%0b, q_bar=%0b", tx.q, tx.q_bar), UVM_LOW);
end
endtask

endclass : output_monitor

// input monitor class
class input_monitor extends uvm_monitor;

transaction tx;
virtual dff_if in;
uvm_analysis_port #(transaction) input_to_scoreboard;

`uvm_component_utils(input_monitor);

function new(string name = "input_monitor", uvm_component parent);
super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db #(virtual dff_if) :: get(this,"","vif",in)) `uvm_fatal("IMON", $sformatf("virtual interface never recieved"));
input_to_scoreboard = new("input_to_scoreboard",this);
endfunction

task run_phase(uvm_phase phase);
forever begin
tx = transaction::type_id::create("tx");
@(posedge in.clk);
tx.d = in.d;
tx.reset = in.reset;
`uvm_info("IMON", $sformatf("monitoring the input payload which contains d=%0b, reset=%0b", tx.d, tx.reset), UVM_LOW);
input_to_scoreboard.write(tx);
end
endtask

endclass : input_monitor

// scoreboard class
class scoreboard extends uvm_scoreboard;

uvm_tlm_analysis_fifo #(transaction) mon_to_scoreboard;
uvm_tlm_analysis_fifo #(transaction) input_to_scoreboard;
transaction tx_exp,tx_act;

int fail_count = 0;
int pass_count = 0;

`uvm_component_utils(scoreboard);

function new(string name = "scoreboard", uvm_component parent);
super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
mon_to_scoreboard = new("mon_to_scoreboard",this);
input_to_scoreboard = new("input_to_scoreboard",this);
endfunction

task run_phase(uvm_phase phase);
forever begin
mon_to_scoreboard.get(tx_act);
input_to_scoreboard.get(tx_exp);
if(compare_start()) begin pass_count++; `uvm_info("SCR", $sformatf("data is matched"), UVM_LOW); end
else begin fail_count++; `uvm_info("SCR", $sformatf("data is mis-matched"), UVM_LOW); end
end
endtask

function bit compare_start();
if(tx_exp.reset) return(tx_act.q == 0 && tx_act.q_bar == 1);
else return(tx_act.q == tx_exp.d && tx_act.q_bar == ~tx_exp.d);
endfunction

function void check_phase(uvm_phase phase);
super.check_phase(phase);
`uvm_info("SCR", $sformatf("pass count = %0d and fail count = %0d",pass_count,fail_count), UVM_LOW);
if(fail_count > 0) begin `uvm_error("SCR", $sformatf("DUT failed the test")); end
else begin `uvm_info("SCR", $sformatf("DUT passed the test"), UVM_LOW); end
endfunction

endclass : scoreboard

// agent class
class agent extends uvm_agent;

driver drv;
uvm_sequencer #(transaction) seqr;
output_monitor omon;
input_monitor imon;  

`uvm_component_utils(agent);

function new(string name = "agent", uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
drv = driver::type_id::create("drv",this);
seqr = uvm_sequencer #(transaction) :: type_id :: create("seqr",this);
omon = output_monitor::type_id::create("omon",this);
imon = input_monitor::type_id::create("imon",this);
endfunction

function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
drv.seq_item_port.connect(seqr.seq_item_export);
endfunction

endclass : agent

// environment class
class env extends uvm_env; 

`uvm_component_utils(env);

function new(string name = "env", uvm_component parent);
super.new(name,parent);
endfunction

agent a;
scoreboard score;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
a = agent::type_id::create("a",this);
score = scoreboard::type_id::create("score",this);
endfunction

function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
a.omon.mon_to_scoreboard.connect(score.mon_to_scoreboard.analysis_export);
a.imon.input_to_scoreboard.connect(score.input_to_scoreboard.analysis_export);
endfunction

endclass : env

// test class
class test extends uvm_test;

`uvm_component_utils(test);

function new(string name = "test", uvm_component parent);
super.new(name,parent);
endfunction

env e;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
e = env::type_id::create("e",this);
endfunction

task run_phase(uvm_phase phase);
data_sequence d;
reset_sequence r;
phase.raise_objection(this);
begin
r = reset_sequence::type_id::create("r");
r.start(e.a.seqr);
end
begin
d = data_sequence::type_id::create("d");
d.start(e.a.seqr);
end
phase.drop_objection(this);
endtask

endclass : test

// main module
module UVM_dff();

logic clk = 0;
always #5 clk = ~clk;

dff_if phys_if(clk);

//DUT instantance
DFF dff
    (
    .clk(phys_if.clk),
    .reset(phys_if.reset),
    .d(phys_if.d),
    .q(phys_if.q),
    .q_bar(phys_if.q_bar)
    );

initial begin
phys_if.d = 0;
phys_if.reset = 1;
uvm_config_db #(virtual dff_if) :: set(null,"*","vif",phys_if);
run_test("test");
end

endmodule : UVM_dff