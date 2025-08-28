5.How to use UVM callbacks in a driver to modify behavior dynamically?

In UVM, callbacks allow you to dynamically modify the behavior of components (like drivers, monitors, scoreboards) without modifying the base code. This makes your testbench more flexible, reusable, and easier to maintain.

✅ What is a UVM Callback?
A callback is a hook method that is called inside a UVM component. By default, the base class provides empty (or default) behavior, but users can extend and override it at runtime using a callback mechanism.

🎯 Purpose of UVM Callbacks
	• To change functionality without altering base driver/monitor code.
	• To inject custom behavior based on test scenarios.
	• To promote reuse and cleaner separation between components and tests.
	• To avoid creating multiple driver classes for small changes.

🧱 Steps to Use Callbacks in a UVM Driver
✅ Step 1: Define a Callback Base Class

class my_driver_callback extends uvm_callback;
  `uvm_object_utils(my_driver_callback)
// Virtual task to override
  virtual task modify_transaction(ref my_txn tx);
  endtask
endclass

✅ Step 2: Modify the Driver to Support Callbacks

class my_driver extends uvm_driver#(my_txn);
  `uvm_component_utils(my_driver)
// Register the callback
  `uvm_register_cb(my_driver, my_driver_callback)
function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      
      // Call user callback hook (if any registered)
      `uvm_do_callbacks(my_driver, my_driver_callback, modify_transaction(req))
// Now drive the modified request
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask
task drive_transfer(my_txn tx);
    `uvm_info("DRV", $sformatf("Driving tx: %s", tx.convert2string()), UVM_MEDIUM)
    // Code to drive tx to DUT
  endtask
endclass

✅ Step 3: Define a Callback Extension to Customize Behavior

class my_custom_callback extends my_driver_callback;
  `uvm_object_utils(my_custom_callback)
virtual task modify_transaction(ref my_txn tx);
    // Modify the transaction dynamically
    tx.data = 8'hFF; // Force data to 0xFF for example
    `uvm_info("CB", "Callback modified the transaction", UVM_MEDIUM)
  endtask
endclass

✅ Step 4: Register the Callback in the Test or Environment

class my_test extends uvm_test;
  `uvm_component_utils(my_test)
my_env env;
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = my_env::type_id::create("env", this);
  endfunction
function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
// Create and register the callback
    my_custom_callback cb = my_custom_callback::type_id::create("cb");
    uvm_callbacks#(my_driver, my_driver_callback)::add(env.agent.drv, cb);
  endfunction
endclass

📌 Important Notes
	• Callbacks must not block the simulation unless necessary.
	• Useful for:
		○ Randomization overrides
		○ Data injection
		○ Protocol violations
		○ Transaction manipulation

🧠 Applications of UVM Callbacks
Application	Description
Protocol error injection	Corrupt address, data, or control
Test-specific overrides	Customize driver behavior for certain tests
Stimulus variation	Change drive delays, timings dynamically
Scoreboard hooks	Delay or skip checks conditionally
Monitor filtering	Drop or modify packets before analysis


✅ Summary
Topic	Details
Purpose	Modify component behavior dynamically without changing base code
Key Components	uvm_callback, uvm_register_cb, uvm_do_callbacks
Use In	Driver, monitor, scoreboard, reference model
Test Control	Enables fine-grained control from test layer
