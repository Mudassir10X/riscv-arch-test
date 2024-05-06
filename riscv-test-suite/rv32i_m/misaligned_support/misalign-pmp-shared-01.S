//
// This assembly file tests the misaligned accesses on an address shared between two PMP regions.
// 
#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV32I_Zicsr")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

#ifdef TEST_CASE_1

RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); check hw_data_misaligned_support:=True; def rvtest_mtrap_routine=True;def TEST_CASE_1=True;",misalign-lw)

RVTEST_CASE(1,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*Zicsr.*); check hw_data_misaligned_support:=False; def rvtest_mtrap_routine=True;def TEST_CASE_1=True;",misalign-lw)

RVTEST_SIGBASE( x1,signature_x1_1)

main:
    LA      (t2, pmp1_data_check)						// Load starting address of PMP region                
    srli    t2, t2, PMP_SHIFT							// Right shift the Address by PMP_Shift(2) 
	ori     t2, t2, 0x3FF								// Selects the range of 8 kB
	csrw    pmpaddr0, t2								// Region # 2 for the pmp permissions

    LA      (t2, pmp0_data_check)						// Load starting address of PMP region                
    srli    t2, t2, PMP_SHIFT							// Right shift the Address by PMP_Shift(2) 
	ori     t2, t2, 0x7FF								// Selects the range of 16 kB 
	csrw    pmpaddr1, t2								// Region # 1 for the pmp permissions

	li      t2, 0x9F98  								// Region # 2: RWX, 1: ---
	csrw    pmpcfg0, t2 								// Write PMP Regions Configration   


#   Test SW
STORE_CHECK:
#   ERRH, OK
    LI      (t1, 0xBEEFCAFE)                            // initializing the register for store
    LI      (t3, 2)                                     // initializing register t3 with 2
    LA      (t2, pmp1_data_check)                       // loading address of PMP Region 2
    sub     t2, t2, t3                                  // subtracting t3 from address for misaligned store at boundary 
    sw      t1, 0(t2)                                   // Attempting misaligned store
#   OK, ERRL
    LI      (t1, 0xBEEFCAFE)                            // initializing the register for store
    LI      (t3, 2)                                     // initializing register t3 with 2
    LA      (t2, pmp3_data_check)                       // loading address of PMP Region 4
    sub     t2, t2, t3                                  // subtracting t3 from address for misaligned store at boundary
    sw      t1, 0(t2)                                   // Attempting misaligned store
#   ERRH, ERRL
    LI      (t1, 0xBEEFCAFE)                            // initializing the register for store
    LI      (t3, 2)                                     // initializing register t3 with 2
    LA      (t2, pmp2_data_check)                       // loading address of PMP Region 3
    sub     t2, t2, t3                                  // subtracting t3 from address for misaligned store at boundary 
    sw      t1, 0(t2)                                   // Attempting misaligned store

#  Test LW
LOAD_CHECK:
#   ERRH, OK
    LI      (t3, 2)                                     // initializing register t3 with 2
    LA      (t2, pmp1_data_check)                       // loading address of PMP Region 2
    sub     t2, t2, t3                                  // subtracting t3 from address for misaligned load at boundary 
    lw      t1, 0(t2)                                   // Attempting misaligned load
#   OK, ERRL
    LI      (t3, 2)                                     // initializing register t3 with 2
    LA      (t2, pmp3_data_check)                       // loading address of PMP Region 4
    sub     t2, t2, t3                                  // subtracting t3 from address for misaligned load at boundary 
    lw      t1, 0(t2)                                   // Attempting misaligned load
#   ERRH, ERRL
    LI      (t3, 2)                                     // initializing register t3 with 2
    LA      (t2, pmp2_data_check)                       // loading address of PMP Region 3
    sub     t2, t2, t3                                  // subtracting t3 from address for misaligned load at boundary 
    lw      t1, 0(t2)                                   // Attempting misaligned load
#endif


RVTEST_CODE_END
# RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 14
pmp0_data_check:                                        // RWX      (0x80008000 - 0x80008FFF)
    .fill 1024*(XLEN/32), 4 , 0xdeadbeef
pmp1_data_check:                                        // x        (0x80009000 - 0x80009FFF)
    .fill 1024*(XLEN/32), 4 , 0xbeefcafe
pmp2_data_check:                                        // none     (0x8000A000 - 0x8000AFFF)
    .fill 1024*(XLEN/32), 4 , 0xabcdefab
pmp3_data_check:                                        // RW       (0x8000B000 - 0x8000BFFF)
    .fill 1024*(XLEN/32), 4 , 0xfedcbafe
rvtest_data:
.word 0xbabecafe
.word 0xbabecafe
.word 0xbabecafe
.word 0xbabecafe
RVTEST_DATA_END


RVMODEL_DATA_BEGIN
rvtest_sig_begin:
sig_begin_canary:
CANARY;


signature_x1_0:
    .fill 0*(XLEN/32), 4 , 0xdeadbeef


signature_x1_1:
    .fill 3*(XLEN/32), 4 , 0xdeadbeef

#ifdef rvtest_mtrap_routine

tsig_begin_canary:
CANARY;
mtrap_sigptr:
    .fill 64*(XLEN/32), 4 , 0xdeadbeef
tsig_end_canary:
CANARY;

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 32*(XLEN/32), 4 , 0xdeadbeef

#endif

sig_end_canary:
CANARY;
rvtest_sig_end:
RVMODEL_DATA_END


