1. Understanding the run_phase and Forever Loop

In UVM, the run_phase is a task phase that allows parallel execution of components, typically for driving and monitoring DUT activity.
If you write something like:

task run_phase(uvm_phase phase);
  super.run_phase(phase);
  forever begin
    seq_item_port.get_next_item(req);
    drive_item(req);
    seq_item_port.item_done();
  end
endtask


Here, the forever loop means the run_phase never exits naturally on its own.
This is normal for drivers and monitors that need to keep running until simulation ends.

2. How End of Simulation Happens with Forever Loops

Even though your run_phase task never ends, UVM handles simulation shutdown in a controlled manner via:

a) Objection Mechanism
Every phase uses the raise_objection / drop_objection mechanism to determine when it’s safe to end.

Example:
Test or environment raises an objection at start of run_phase.
When stimulus generation is complete, it drops the objection.
Once all objections are dropped, UVM triggers the phase completion, even if components are still sitting in a forever loop.
Components in the forever loop should check for phase.is_done() to break cleanly.

Example:
task run_phase(uvm_phase phase);
  forever begin
    if (phase.is_done())
      break; // gracefully exit when phase ends

    seq_item_port.get_next_item(req);
    drive_item(req);
    seq_item_port.item_done();
  end
endtask

b) Kill/Drain Mechanism
At the end of the run_phase, UVM performs a kill on any still-active threads if they haven't exited gracefully.
This is a forceful stop and is generally not preferred, as it may lead to incomplete transactions or partial logging.

3. Where the Run Phases Are Involved
The run_phase belongs to the runtime phases of UVM’s phasing schedule:
| **Phase Group**         | **Phases** (simplified order)                                 |
| ----------------------- | ------------------------------------------------------------- |
| **Build**               | `build_phase`                                                 |
| **Connect**             | `connect_phase`                                               |
| **End of Elaboration**  | `end_of_elaboration_phase`                                    |
| **Start of Simulation** | `start_of_simulation_phase`                                   |
| **Run-time**            | `reset`, `configure`, `main`, `run`, etc.                     |
| **Post-run**            | `extract_phase`, `check_phase`, `report_phase`, `final_phase` |


run_phase typically handles continuous DUT interaction like:
Driving transactions
Monitoring signals
Handling responses or scoreboarding

4. Practical Use Case

Imagine a driver:
Needs to continuously drive requests until test sequence ends.
Objection is dropped after stimulus is done.
Driver checks phase.is_done() to stop gracefully.

Driver Example:
task run_phase(uvm_phase phase);
  forever begin
    if (phase.is_done())
      break; // stop cleanly when objections drop

    seq_item_port.get_next_item(req);
    drive_to_dut(req);
    seq_item_port.item_done();
  end
  `uvm_info("DRIVER", "Exiting run_phase cleanly", UVM_LOW)
endtask

5. Summary of Behavior
| **Scenario**                                                  | **Simulation End Behavior**                                   |
| ------------------------------------------------------------- | ------------------------------------------------------------- |
| No objection dropped                                          | Simulation hangs forever.                                     |
| Objection dropped, but thread doesn't check `phase.is_done()` | Thread is killed forcefully; simulation ends but not cleanly. |
| Objection dropped, and thread checks `phase.is_done()`        | Thread exits gracefully; clean simulation end.                |

Key Takeaways
run_phase often uses forever loops for continuous activity.
End-of-simulation is controlled by objections, not by the forever loop.
Always use phase.is_done() or similar checks to gracefully exit.
Proper objection handling ensures that post-run phases like extract_phase, check_phase, and report_phase execute correctly.


In UVM, “no objection dropped” means that some component (usually a test, sequence, or environment) raised an objection but never lowered it.
Since phase completion depends on all objections being dropped, the simulation never exits the current runtime phase (like run_phase) and will effectively hang forever.

How Objections Work
phase.raise_objection(this)
Signals that the component needs the current phase to remain active (e.g., stimulus is still running).

phase.drop_objection(this)
Signals that the component is done with its activity in this phase and it is okay for the phase to end.

UVM keeps a counter of objections.
Every raise increments the counter.
Every drop decrements it.

When the counter reaches 0, UVM knows it’s safe to end the phase and move forward.
Example
Test with Missing Drop
class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "Starting stimulus...", UVM_LOW);

    // Generate stimulus but forget to drop objection
    repeat (10) begin
      `uvm_info("TEST", "Sending packet", UVM_LOW);
      #10;
    end
    // Missing: phase.drop_objection(this);
  endtask
endclass

What happens:
run_phase stays alive indefinitely.
Simulation never progresses to extract_phase, check_phase, report_phase.
You’ll see the simulation hanging after stimulus is done.

Proper Way 
task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  `uvm_info("TEST", "Starting stimulus...", UVM_LOW);

  repeat (10) begin
    `uvm_info("TEST", "Sending packet", UVM_LOW);
    #10;
  end

  phase.drop_objection(this);
  `uvm_info("TEST", "Stimulus done, dropping objection", UVM_LOW);
endtask

Debugging Clues:
UVM Info Logs: You'll see something like
UVM_INFO @ 1000: uvm_root [UVM/PHASE] run_phase waiting for objections to drop...
Hanging Simulation: Time keeps progressing (if clocks are running), but nothing moves to next phases.

  outcomes:
| Situation                            | Result                                              |
| ------------------------------------ | --------------------------------------------------- |
| Objection raised but **not dropped** | Simulation **hangs forever** in that phase          |
| Objection never raised               | Phase ends immediately, may cause premature end     |
| Objection properly raised & dropped  | Simulation ends cleanly and post-run phases execute |

