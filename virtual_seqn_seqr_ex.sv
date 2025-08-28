//Start 2 seqeunces on to the single sequencer Sequentially in the Test
//Scenario 1:
class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  my_agent agent;

  function void build_phase(uvm_phase phase);
    agent = my_agent::type_id::create("agent", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    seq_A sA = seq_A::type_id::create("sA");
    seq_B sB = seq_B::type_id::create("sB");

    `uvm_info("TEST", "Starting seq_A", UVM_LOW)
    sA.start(agent.sequencer); // Blocking call
    `uvm_info("TEST", "seq_A finished. Waiting 100ns", UVM_LOW)

    #100ns;

    `uvm_info("TEST", "Starting seq_B", UVM_LOW)
    sB.start(agent.sequencer);
    `uvm_info("TEST", "seq_B finished", UVM_LOW)

    phase.drop_objection(this);
  endtask
endclass

//Scenario:2 
//🧱 Architecture
//Top-Level Test
//    ↓
//Start virtual sequence (on virtual sequencer)
//    ↓
//virtual sequence calls:
//    → seq_A.start()
//    → delay
//    → seq_B.start()

// ✅ Step-by-Step Example

// 🔧 Step 1: Regular Sequences (Already Done)
// We already have:
class seq_A extends uvm_sequence #(my_txn);
class seq_B extends uvm_sequence #(my_txn);

//🔧 Step 2: Define a Virtual Sequencer
//Since we need a sequencer to manage other sequencers, we define:

class virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(virtual_sequencer)

  my_sequencer seqr;  // the actual sequencer we will control

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass


//✅ This virtual_sequencer just holds a handle to your real sequencer.
//🔧 Step 3: Define a Virtual Sequence (Nested Sequence)

class top_seq extends uvm_sequence;
  `uvm_object_utils(top_seq)

  virtual_sequencer p_sequencer; // pointer to virtual_sequencer

  function new(string name = "top_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("TOP_SEQ", "Starting seq_A", UVM_LOW)

    seq_A sA = seq_A::type_id::create("sA");
    sA.start(p_sequencer.seqr); // launch on actual sequencer

    #100ns;

    `uvm_info("TOP_SEQ", "Starting seq_B", UVM_LOW)
    seq_B sB = seq_B::type_id::create("sB");
    sB.start(p_sequencer.seqr); // launch on actual sequencer
  endtask
endclass

//🔧 Step 4: Environment Connections
//In your env/agent, expose both virtual_sequencer and my_sequencer:

class my_env extends uvm_env;
  `uvm_component_utils(my_env)

  virtual_sequencer v_seqr;
  my_sequencer       seqr;

  function void build_phase(uvm_phase phase);
    seqr    = my_sequencer::type_id::create("seqr", this);
    v_seqr  = virtual_sequencer::type_id::create("v_seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    //Because the virtual_sequencer itself does not automatically know or link to the actual sequencer — we have to tell it.
	//is how the virtual_sequencer gets access to the actual sequencer.
    v_seqr.seqr = seqr; // link virtual to actual sequencer
  endfunction
endclass


//🔧 Step 5: Test Starts the Virtual Sequence
class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  my_env env;

  function void build_phase(uvm_phase phase);
    env = my_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    top_seq seq = top_seq::type_id::create("top_seq");
    seq.start(env.v_seqr);  // run on virtual sequencer

    phase.drop_objection(this);
  endtask
endclass

//✅ Summary
//| Concept                | Description                                         |
//| ---------------------- | --------------------------------------------------- |
//| `virtual_sequencer`    | Holds reference(s) to real sequencers               |
//| `top_seq`              | A parent sequence that controls other sequences     |
//| `.start()` in `body()` | Launches `seq_A`, then waits, then launches `seq_B` |
//| Real test              | Starts the `top_seq` on the virtual sequencer       |


//Scenario 3:
//If your testbench only has one sequencer and you're not planning to scale to multiple agents, then:
//✔️ You can safely skip the virtual sequencer and run everything using just the main sequencer and a top-level uvm_sequence#(my_txn).

class top_seq extends uvm_sequence #(my_txn); // not generic now
  `uvm_object_utils(top_seq)

  function new(string name = "top_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("TOP_SEQ", "Running top_seq", UVM_LOW)

    seq_A sA = seq_A::type_id::create("sA");
	//"m_sequencer" is a built-in protected handle in the uvm_sequence base class.
    sA.start(m_sequencer); // m_sequencer is already of type my_sequencer

    #100ns;

    seq_B sB = seq_B::type_id::create("sB");
    sB.start(m_sequencer);
  endtask
endclass

//💡 Interpretation: 
//top_seq is started on my_sequencer (your only sequencer).
//So m_sequencer inside top_seq points to that my_sequencer instance.
//You’re using it to launch child sequences (seq_A and seq_B) on the same sequencer.

task run_phase(uvm_phase phase);
  phase.raise_objection(this);

  top_seq seq = top_seq::type_id::create("top_seq");
  seq.start(env.seqr); // directly start on my_sequencer

  phase.drop_objection(this);
endtask
