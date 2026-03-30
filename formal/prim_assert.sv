`ifndef FORMAL_PRIM_ASSERT_SV_
`define FORMAL_PRIM_ASSERT_SV_

// Minimal assertion macro stubs used to compile the DUT in this take-home repo.
// The formal harness supplies the real verification checks.

`define ASSERT(__name, __prop)
`define ASSERT_INIT(__name, __prop)
`define ASSERT_KNOWN(__name, __sig)
`define ASSERT_KNOWN_IF(__name, __sig, __cond)
`define ASSERT_INIT_NET(__name, __prop)

`endif
