# icesid

Icesid is an open source FPGA reimplementation of the famous MOS 6581/8580 SID chip used in the Commodore 64.

The icesid design has been primarly written to run on the [reDIP-SID board](https://github.com/daglem/reDIP-SID) designed by [daglem](https://github.com/daglem). That means it can be used directly as a drop-in replacement for the SID chip in a C64.

Special thanks go to [daglem](https://github.com/daglem) for both his SID wisdom and generosity in sending me an reDIP-SID board to develop with.  To [Sylvain "tnt" Munaut](https://github.com/smunaut/) for his patience answering lots of my questions and his invaluable work to get the reDIP-SID up and running. Also to [Paul Sajna](https://github.com/sajattack) for helping develop aspects of the code and extensive testing.

Drop by the 1BitSquared discord if you have any questions about icesid.

## EconoPET timing compatibility

Envelope register writes remain on the falling clock edge and take effect on
the next rising edge. The envelope update uses parallel carry/borrow prefixes
with separate update qualification to avoid a serial sustain-comparison and
borrow path within that half-cycle. Saturation, sustain equality, stage
transitions, and counter/divider timing are unchanged.

EconoPET's `sid_env_tb` verifies all envelope next-state combinations and
falling-edge sustain-write visibility under Icarus and Verilator.
