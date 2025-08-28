4.Demonstrate TLM usage for data transfer between a monitor and scoreboard.

step-1:Implement the Monitor, The monitor observes transactions from the DUT and forwards them to the scoreboard using a TLM analysis port.

class my_monitor extends uvm_monitor;
   `uvm_component_utils(my_monitor)
   
    uvm_analysis_port #(apb_transaction) mon_port; // TLM Analysis Port
	axi_interface v_intf; //interface instantiation 
	axi_packet pkt; //Packet instantiation 
	
	//Constructor
	function new (string name ="my_monitor", uvm_component parent =null);
	   super.new(name,parent);
	endfunction
		
	//Build phase 
	function void build_phase(uvm_phase phase);
	  `uvm_info(get_type_name(),"Message::in the build phase",UVM_MEDIUM)
	   //Build other components 
	   pkt = our_packet::type_id::create("our packet");
	   //Get method 
	   uvm_config_db #(virtual axi_interface)::get(null, "*", "intf",v_intf);
	   mon_port = new("monitor port",this);
	endfunction
	
	virtual task run_phase(uvm_phase phase);
	    forever begin
            pkt.addr = v_intf.paddr;//$random;
            pkt.data = v_intf.prdata;//$random;
            pkt.rw   = v_intf.pwrite; //$random % 2;
            `uvm_info("MONITOR", $sformatf("Observed transaction: addr=%0h, data=%0h, rw=%0b", pkt.addr, pkt.data, pkt.rw), UVM_MEDIUM)
            // Send the transaction to the scoreboard via the analysis port
            mon_port.write(pkt);
            // Wait for a clock or some delay
            #10ns;
        end
	endtask
endclass

step-2:Implement the Scoreboard,The scoreboard receives transactions from the monitor using a TLM analysis export and performs checks.

class my_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(my_scoreboard)

    uvm_analysis_imp #(apb_transaction, my_scoreboard) imp;  // TLM Analysis Export

    function new(string name = "my_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    virtual function void write(apb_transaction pkt);
        // Example check: If the transaction is a write, print the data
        if (pkt.rw) begin
            `uvm_info("SCOREBOARD", $sformatf("Checking write transaction: addr=%0h, data=%0h", pkt.addr, pkt.data), UVM_MEDIUM)
        end else begin
            `uvm_info("SCOREBOARD", $sformatf("Checking read transaction: addr=%0h", pkt.addr), UVM_MEDIUM)
        end
    endfunction
endclass

step-3:Connect the Monitor and Scoreboard in the Environment,The environment sets up the connections between the monitor and scoreboard using the TLM ports.
class my_env extends uvm_env;
   `uvm_component_utils(my_env)
   
    my_monitor monitor;//Monitor instantiation
    my_scoreboard scoreboard;//scoreboard instantiation

    function new(string name = "my_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Instantiate monitor and scoreboard by using factory create method
        monitor = my_monitor::type_id::create("monitor", this);
        scoreboard = my_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect the monitor's analysis port to the scoreboard's analysis export
        monitor.ap.connect(scoreboard.imp);
    endfunction
endclass
