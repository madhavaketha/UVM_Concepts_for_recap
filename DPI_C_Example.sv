//============================================================= C - SV sync through DPI-C ===================================//
//1. SV Testbench starts and calls a C function
//2. C function configures DMA and waits
//3. After DMA completes, C calls back into SV
//4. SV logs the event or checks results

//1. SystemVerilog Side — Define the Callback Function
// File: dma_tb.sv
module dma_tb;
  // Exported SV callback function
  export "DPI-C" function void dma_done_callback;

  function void dma_done_callback();
    $display("[SV] DMA transfer completed — callback received at time %0t", $time);
    // Trigger next step, check memory, etc.
  endfunction

  // Import C function to start DMA
  import "DPI-C" function void start_dma_from_c();

  initial begin
    #5;
    $display("[SV] Calling C function to start DMA...");
    start_dma_from_c();  // Starts C-side flow
  end
endmodule

// 2. C Side — Start DMA and Notify SV via Callback
// File: dma_driver.c
#include <stdio.h>
#include <unistd.h> // For sleep (simulating delay)

// Declare SV callback function (imported from SV)
extern void dma_done_callback();

// Exported C function (called from SV)
void start_dma_from_c() {
    printf("[C ] Configuring DMA...\n");
    // Simulate DMA operation
    sleep(1);  // In real co-sim, could wait for IRQ or poll
    printf("[C ] DMA completed, calling SV callback...\n");

    // Notify SV testbench
    dma_done_callback();
}

//Output at Runtime:
//[SV] Calling C function to start DMA...
//[C ] Configuring DMA...
//[C ] DMA completed, calling SV callback...
//[SV] DMA transfer completed — callback received at time 1000
