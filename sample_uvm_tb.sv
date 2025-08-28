/* This is representing the basic/standard approach to bringupt the test bench in the UVM
 It will used full quick review for interview on UVM architecture and its connections*/
 
`include "uvm_macros.svh"
import uvm_pkg::*;

module top(); 
   our_design uut(); // instantiated our design 
   our_interface intf(); //Instantiated our interface 
   
   //We need to use the "set" method to set the interface in the database 
   initial begin 
     //set method 
     uvm_config_db #(virtual our_interface)::set(null, "*", "intf" , intf);
   end 
   
   initial begin 
     run_test("our_test");//run test 
   end 
endmodule 

//Oops concepts get involved from here on wards in testbench(inheretance / encapsulation / polymorphism / abstraction 
class my_test extends uvm_test;
    //register our class in the factory 
	`uvm_component_utils(my_test);
	
	//Instantiate the classes 
	my_env my_env_h;
	
	//Constuctor 
	function new (string name = "my_test", uvm_component parent = null);
	   super.new(name, parent);
	endfunction
	
	//Build phase 
	function void build_phase(uvm_phase phase);
	   //Build other components 
	   //Build env class
	   //factory create method 
	   my_env_h = my_env::type_id::create("my_env_h",this);//create env class
	endfunction
	
	//Connect phase 
	function void connect_phase(uvm_phase phase);
	   //Neccessary connections
	endfunction
	
	//Run phase
	task run_phase(uvm_phase phase);
	  //Main logic 
	endtask
    //Methods 
	//Properties 
endclass

class my_env extends uvm_env; 
   //register class in the factory
   `uvm_component_utils(my_env);
   
    // Instantiate classes
	my_agent my_agent_h;
    //Constructor 
	function new (string name = "my_env", uvm_component parent = null);
	  super.new(name,parent);
	endfunction
	
	//Build phase 
	function void build_phase(uvm_phase phase);
	   `uvm_info(get_type_name(),"Message::in the build phase",UVM_MEDIUM)
	   //Build other components 
	   //Build agent class
       //factory create method 
	   my_agent_h = my_agent::type_id::create("my_agent_h",this);	   
	endfunction
	
	//Connect phase 
	function void connect_phase(uvm_phase phase);
	   //Neccessary connections
	endfunction
	
endclass


class my_agent extends uvm_agent;
   //register class in the factory
   `uvm_component_utils(my_agent);
   
   // Instantiate the classes
   my_sequencer my_sequencer_h;
   my_driver    my_driver_h;
   my_monitor   my_monitor_h;
   //Constructor 
	function new (string name = "my_agent", uvm_component parent = null);
	  super.new(name,parent);
	endfunction
	
	//Build phase 
	function void build_phase(uvm_phase phase);
	  `uvm_info(get_type_name(),"Message::in the build phase",UVM_MEDIUM)
	   //Build other components 
	   //Build sequencer , monitor, driver 
	   //cretae components by using factory create method 
	   my_sequencer_h = my_sequencer::type_id::create("my_sequencer_h",this);
	   my_driver_h    = my_driver::type_id::create("my_driver_h",this);
	   my_monitor_h   = my_monitor::type_id::create("my_monitor_h",this);
	endfunction
	
	//Connect phase 
	function void connect_phase(uvm_phase phase);
	   //Neccessary connections
	   my_driver_h.seq_item_port.connect(my_sequencer_h.seq_item_export);
	endfunction
	
endclass

// For sequencer there is nothig to do here mostly importantly we need to parameterize the class
class my_sequencer extends uvm_sequencer #(our_packet);
    //register class in the factory
   `uvm_component_utils(my_sequencer);
    //Constructor 
	function new (string name = "my_sequencer", uvm_component parent = null);
	  super.new(name,parent);
	endfunction
	
	//Build phase 
	function void build_phase(uvm_phase phase);
	  `uvm_info(get_type_name(),"Message::in the build phase",UVM_MEDIUM)
	   //Build other components 
	endfunction
	
	//Connect phase 
	function void connect_phase(uvm_phase phase);
	   //Neccessary connections
	endfunction
	
	//main logic
endclass


class my_driver extends uvm_driver #(our_packet);
   //register class in the factory
   `uvm_component_utils(my_driver);
   
    our_interface intf; //Instantiated our interface
    our_packet pkt; // Instantiated the packet 
    //Constructor 
	function new (string name = "my_driver", uvm_component parent = null);
	  super.new(name,parent);
	endfunction
	
	//Build phase 
	function void build_phase(uvm_phase phase);
	  `uvm_info(get_type_name(),"Message::in the build phase",UVM_MEDIUM)
	   //Build other components 
	   pkt = our_packet::type_id::create("our packet");
	   //Get method 
	   uvm_config_db #(virtual our_interface)::get(null, "*", "intf", intf);
	endfunction
	
	//Connect phase 
	function void connect_phase(uvm_phase phase);
	   //Neccessary connections
	endfunction
	
	//main logic 
	task run_phase(uvm_phase phase);
	  forever begin
	    @(posedge intf.clk)
		   seq_item_port.get_next_item(pkt);
		   
		    intf.input_1 <= pkt.input_1;
			intf.input_2 <= pkt.input_2;
			
		   seq_item_port.item_done();
	  end 
	endtask
endclass

class my_monitor extends uvm_monitor;
   //register class in the factory
   `uvm_component_utils(my_monitor);
   
   uvm_analysis_port #(our_packet) mon_port;
   
   our_interface intf; //Instantiated our interface
   our_packet pkt; // Instantiated the packet 
   //Constructor 
	function new (string name = "my_monitor", uvm_component parent = null);
	  super.new(name,parent);
	endfunction
	
	//Build phase 
	function void build_phase(uvm_phase phase);
	  `uvm_info(get_type_name(),"Message::in the build phase",UVM_MEDIUM)
	   //Build other components 
	   pkt = our_packet::type_id::create("our packet");
	   //Get method 
	   uvm_config_db #(virtual our_interface)::get(null, "*", "intf",intf);
	   mon_port = new("monitor port",this);
	endfunction
	
	//Connect phase 
	function void connect_phase(uvm_phase phase);
	   //Neccessary connections
	endfunction
	
	//main logic 
	task run_phase(uvm_phase phase);
	    forever begin
	      @(posedge intf.clk);		   
		    pkt.input_1 <= intf.input_1;
			pkt.input_2 <= intf.input_2;	
	    end 
	endtask
endclass

class our_packet extends uvm_sequence_item;
   `uvm_object_utils(our_packet);
   
    //request items 
    rand bit [7:0] input_1;
	rand bit [7:0] input_2;
	
	//response items 
	bit [15:0] output_1;
	
    //Constructor 
	function new (string name = "our_packet");
	   super.new(name);
	endfunction
endclass

class our_sequence extends uvm_sequence;
   `uvm_object_utils(our_sequence);
   
    our_packet pkt;
	
    //Constructor 
	function new (string name = "our_sequence");
	 super.new(name);
	endfunction
	
	task body();
	  //Used for randomizing the transaction class 
	  // Used to generate our stimulus
	  pkt = our_packet::type_id::create("our packet");
	  
	  //This is how we generate the stimulus for the driver 
	  repeat(10)
	     begin 
		  start_item(pkt);
		  pkt.randomize();
		  finish_item(pkt);
		 end 
	  
	endtask
endclass

//interface:: related signals together into one(single) entity 
//set in the module and get tha handle in the components (where ever it is required)

interface our_interface(input logic clk);
  //input_1
  //input_2
  logic [7:0] input_1;
  logic [7:0] input_2;
 
  //output 
   logic [7:0] output_3;
endinterface
