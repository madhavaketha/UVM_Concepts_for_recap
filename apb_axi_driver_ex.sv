class apb_driver extends uvm_driver #(apb_transaction);

    virtual apb_if vif;
    `uvm_component_utils(apb_driver)

    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for apb_driver")
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_transaction tr;

        forever begin
            seq_item_port.get_next_item(tr);
            drive_transfer(tr);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(apb_transaction tr);
        // Setup phase
        vif.paddr   <= tr.addr;
        vif.pwrite  <= tr.write;
        vif.psel    <= 1'b1;
        vif.penable <= 1'b0;
        vif.pwdata  <= tr.write ? tr.data : '0;

        @(posedge vif.clk);

        // Enable phase
        vif.penable <= 1'b1;

        // Wait for ready
        wait(vif.pready === 1'b1);

        if (!tr.write)
            tr.read_data = vif.prdata;

        @(posedge vif.clk);

        // Deassert signals
        vif.psel    <= 0;
        vif.penable <= 0;
        vif.paddr   <= '0;
        vif.pwrite  <= 0;
        vif.pwdata  <= '0;
    endtask

endclass


class axi_driver extends uvm_driver#(axi_transaction);
`uvm_component_utils(axi_driver)
 virtual axi_if vif; // AXI Interface
function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("AXI_DRIVER", "Virtual interface not found")
  endfunction
task run_phase(uvm_phase phase);
    forever begin
      axi_transaction txn;
      seq_item_port.get_next_item(txn); // Get next transaction
      if (txn.write)
        drive_write(txn); // Write transaction
      else
        drive_read(txn); // Read transaction
     seq_item_port.item_done();
    end
  endtask
// Write transaction driver
  task drive_write(axi_transaction txn);
    vif.AWVALID  <= 1;
    vif.AWADDR  <= txn.addr;
    vif.AWLEN      <= txn.len;
    vif.AWSIZE      <= txn.size;
    vif.AWBURST  <= txn.burst;
   @(posedge vif.ACLK);
    while (!vif.AWREADY) @(posedge vif.ACLK);
    vif.AWVALID <= 0; // Address phase done
// Write data phase
    for (int i = 0; i <= txn.len; i++) begin
      vif.WVALID <= 1;
      vif.WDATA  <= txn.wdata[i];
      vif.WLAST  <= (i == txn.len);
      @(posedge vif.ACLK);
      while (!vif.WREADY) @(posedge vif.ACLK);
    end
    vif.WVALID <= 0;
  endtask
// Read transaction driver
  task drive_read(axi_transaction txn);
    vif.ARVALID <= 1;
    vif.ARADDR  <= txn.addr;
    vif.ARLEN   <= txn.len;
    vif.ARSIZE  <= txn.size;
    vif.ARBURST <= txn.burst;
@(posedge vif.ACLK);
    while (!vif.ARREADY) @(posedge vif.ACLK);
    vif.ARVALID <= 0; // Address phase done
  endtask
endclass
