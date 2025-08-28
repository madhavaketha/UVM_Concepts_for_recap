//Here’s a complete working UVM testbench example that shows how to use key uvm_sequence_item built-in methods like copy(), clone(), compare(), print(),
//record(), etc., all in action within a small UVM environment.

//Transaction Class (with built-in methods used)
class my_txn extends uvm_sequence_item;
  rand bit [7:0] data;
  rand bit       valid;

  `uvm_object_utils(my_txn)

  function new(string name = "my_txn");
    super.new(name);
  endfunction

  function void do_copy(uvm_object rhs);
    my_txn tx_rhs;
    if (!$cast(tx_rhs, rhs)) begin
      `uvm_error("COPY", "Type mismatch in do_copy")
      return;
    end
    this.data  = tx_rhs.data;
    this.valid = tx_rhs.valid;
  endfunction

  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    my_txn tx_rhs;
    if (!$cast(tx_rhs, rhs)) return 0;

    bit match = 1;
    if (this.data != tx_rhs.data) begin
      `uvm_info("COMPARE", $sformatf("Data mismatch: %0h vs %0h", this.data, tx_rhs.data), UVM_LOW)
      match = 0;
    end
    if (this.valid != tx_rhs.valid) begin
      `uvm_info("COMPARE", $sformatf("Valid mismatch: %0b vs %0b", this.valid, tx_rhs.valid), UVM_LOW)
      match = 0;
    end
    return match;
  endfunction

  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("data", data, 8);
    printer.print_field("valid", valid, 1);
  endfunction
endclass


//Sequence That Uses All Built-in Methods
class my_sequence extends uvm_sequence #(my_txn);
  `uvm_object_utils(my_sequence)

  function new(string name = "my_sequence");
    super.new(name);
  endfunction

  task body();
    my_txn tx1, tx2, tx3;
    tx1 = my_txn::type_id::create("tx1");
    tx2 = my_txn::type_id::create("tx2");

    // Randomize tx1
    assert(tx1.randomize());

    // Copy tx1 → tx2
    tx2.copy(tx1);

    // Clone tx3
    tx3 = tx1.clone(); //copy + create object

    // Compare tx1 with tx2
    if (tx1.compare(tx2))
      `uvm_info("SEQ", "tx1 and tx2 match!", UVM_MEDIUM)
    else
      `uvm_error("SEQ", "Mismatch detected between tx1 and tx2")

    // Print tx1
    tx1.print();

    // Record tx1 (requires +uvm_record_enable in simulator)
    tx1.record();

    // Send item to driver
    start_item(tx1);
    finish_item(tx1);
  endtask
endclass

//Driver (Simple Display of Received Transaction)
class my_driver extends uvm_driver #(my_txn);
  `uvm_component_utils(my_driver)

  function new(string name = "my_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    my_txn tx;
    forever begin
      seq_item_port.get_next_item(tx);
      `uvm_info("DRV", $sformatf("Driving: data=0x%0h, valid=%0b", tx.data, tx.valid), UVM_LOW)
      seq_item_port.item_done();
    end
  endtask
endclass

//Env, Agent, and Sequencer
class my_sequencer extends uvm_sequencer #(my_txn);
  `uvm_component_utils(my_sequencer)
  function new(string name = "my_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass


class my_agent extends uvm_component;
  `uvm_component_utils(my_agent)

  my_driver drv;
  my_sequencer seqr;

  function new(string name = "my_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    drv  = my_driver::type_id::create("drv", this);
    seqr = my_sequencer::type_id::create("seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass


class my_env extends uvm_env;
  `uvm_component_utils(my_env)

  my_agent agt;

  function new(string name = "my_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    agt = my_agent::type_id::create("agt", this);
  endfunction
endclass

//Test Class
class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  my_env env;

  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    env = my_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    my_sequence seq = my_sequence::type_id::create("seq");
    seq.start(env.agt.seqr); // start sequence on sequencer

    #100ns;
    phase.drop_objection(this);
  endtask
endclass

//Top Module to Run Simulation
module tb;
  initial begin
    run_test("my_test");
  end
endmodule
