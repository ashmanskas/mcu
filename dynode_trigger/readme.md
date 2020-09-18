
### dynode_trigger coding exercise ###

This code will eventually be incorporated into the 'rocstar' project,
but for now we are developing/testing it in a subdirectory of the
'mcu' project, since the 'ashmanskas/mcu' github repo is the place we
have been using to get additional people up to speed with Verilog
coding for FPGAs for the BPET project.

The rocstar board's 'dynode_trigger' code will input a stream of 8-bit
ADC samples at 100 MSPS (megasamples per second), will operate from a
100 MHz clock, and will output once per clock cycle two signals: one
called 'single' (1 bit wide) that indicates that a single-photon
trigger occurred, and another called 'offset' (6 bits wide) that is a
twos-complement timing offset with respect to the clock edge, measured
in units of 1/32 of a 10ns clock tick.
