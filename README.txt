This is the progress we've made on the cache project so far.

All the designs have been made, including:

- cache_control.sv
Which controls the miscellaneous logic in the cache, including the done signal, internal write enables, cache input data muxing, and data output muxing.
This one's currently being debugged.
- cache_data.sv
Stores the actual data for the cache.
- cache_hit.sv
Logic block that determines if the requested read/write is present in the cache.
- cache_lru.sv
Stores the pointers to the least recently used banks for each index and outputs the least recently used one.
- cache_tag.sv
Stores the tags for each index of the cache.
- cache_top.sv
Integrates all "cache_" prefixed blocks to form the cache.
- cache_valid.sv
Stores the valid bits for each index of the cache.
- component_delay.sv
Parameterizable delay block.
- component_register.sv
Parameterizable register block.
- logic_done.sv
Logic block that outputs when the cache has finished its requested operation.
- logic_we.sv
Logic block that muxes internal signals for the internal write enables.
- ram.sv
RAM that the cache block will interface with.

All the testbenches for each block have been made, except for:

- Cache Control block testbench
Currently debugging and adjusting the design.
- Full System Top-Level testbench
Yet to start

For more information, see the Cache Documentation.docx in the documentation folder.
It's currently sitting at ~6k words.