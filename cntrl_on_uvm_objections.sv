// Controlling the uvm objections 
class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  // Declare an event
  event done_event;

  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    `uvm_info("TEST", "Raising objection", UVM_LOW)
    phase.raise_objection(this);  // Start of run_phase work

    fork
      // 🕒 Timeout Thread — Drop after 200ns if nothing happens
      begin
        #200ns;
        if (!done_event.triggered)
          `uvm_info("TEST", "Timeout reached — dropping objection", UVM_LOW)
          phase.drop_objection(this);
      end

      // ✅ Event-based Thread — Drop immediately on event
      begin
        @done_event;
        `uvm_info("TEST", "Event triggered — dropping objection", UVM_LOW)
        phase.drop_objection(this);
      end
    join_any

    // Clean up leftover forked threads
    disable fork;
  endtask
endclass
