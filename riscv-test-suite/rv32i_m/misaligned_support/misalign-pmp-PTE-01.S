#include "model_test.h"
#include "arch_test.h"

RVTEST_ISA("RV32I_Zicsr")

# Test code region
.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN
#ifdef TEST_CASE_1
    RVTEST_CASE(1,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def rvtest_strap_routine=True; def TEST_CASE_1=True",sv32)

RVTEST_SIGBASE( x13,signature_x13_1)
  	
main:

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=

#ifdef rvtest_mtrap_routine								        	// Verification of existance of rvtest_mtrap_routine
	LI a4, 0xceed
	RVTEST_SIGUPD(x13,a4)
#endif
#ifdef rvtest_strap_routine					         		        // Verification of existance of rvtest_strap_routine
	LI a4, 0xbeed
	RVTEST_SIGUPD(x13,a4)
#endif
	csrw    satp,x0       								            //Bare Mode setup

    li s9, 0x34
    la s9, rvtest_sig_begin
    la s9, signature_x13_1
    la s9, sig_begin_canary

    

	.set va,		0x90000000                                      // Page table level 1  VA   
	.set pa,		0x80000000                                      // rvtest_entry_point physical address
	.set va_data,	0x91000000                                      // rvtest_data Virtual address set at level 1 
    .set sig_data,  0x93003110                                      // virtual address of signature_x13_1

#   PMP Regions configuration
	LA(t2, pa)									    // Loads the address of PA                
	srli t2, t2, PMP_SHIFT							// Right shift the PA by PMP_Shift(2) 
	ori t2, t2, 0x1FF								// Selects the range of 4kB    
	csrw pmpaddr0, t2								// Region 1 for the pmp permissions  

	LA(t2, rvtest_slvl1_pg_tbl )					// loads the base address of level1 4kbpage table                 
	srli t2, t2, PMP_SHIFT							// Right shift the address of level 1 page table  by PMP_Shift(2)		
	ori t2, t2, 0x1FF								// Selects the range of 4kB								 	 										
	csrw pmpaddr1, t2								// Region 2 for the pmp permission  

	LA( t2, rvtest_Sroot_pg_tbl)					// loads the base address of root page table               
	srli t2, t2, PMP_SHIFT							// Right shift the address of root page table by PMP_Shift(2)
	ori t2, t2, 0x1FF								// Selects the range of 4kB
	csrw pmpaddr2, t2								// Region 3 for the pmp permission   

	LA( t2, rvtest_data )							// loads the base address of rvtest_data label        
	srli t2, t2, PMP_SHIFT							// Right shift the address of rvtest_data label by PMP_Shift(2)
	ori t2, t2, 0xF									// Selects the range of 128B
	csrw pmpaddr3, t2								// Region 4 for the pmp permission

	LA( t2, rvtest_sig_begin )						// loads the base address of rvtest_sig_begin label        
	srli t2, t2, PMP_SHIFT							// Right shift the address of rvtest_sig_begin label by PMP_Shift(2)
	ori t2, t2, 0xF									// Selects the range of 128B
	csrw pmpaddr4, t2								// Region 5 for the pmp permission

	LI(t2, 0x181F1F1F)								// Region 1: NAPOT with RW PMP Permissions, Region 2, 3 4: NAPOT with RWX PMP Permissions
	csrw pmpcfg0, t2								// Write PMP Regions Configration   

	LI(t2, 0x1F)									// Region5: NAPOT with RWX PMP Permissions
	csrw pmpcfg1, t2								// Write PMP Regions Configration       

	csrw satp,x0									// SATP bare mode 


#------------------------------------------------------PTE setup--------------------------------------------------------------
    // PTE setup for sig_data -> rvtest_slvl1_pg_tbl
	la a0, rvtest_slvl1_pg_tbl                                      // loads the base address of the pg_tbl0        				
	li a1, (PTE_V)                                                  // sets the permissions bits                
	PTE_SETUP_RV32(a0, a1, t0, t1, sig_data, LEVEL1)                // setup the PTE for level1 
    // PTE setup for Instruction memory 0x90000000 -> 0x80000000
	LI a0, pa										                //Loads the address in a0	
	LI a1, (PTE_D | PTE_A | PTE_G | PTE_X | PTE_W | PTE_R | PTE_V)  //sets the permission bits 
	PTE_SETUP_RV32(a0, a1, t0, t1, va, LEVEL1)                      //PTE Setup at level 1

    #PTE SETUP at level 1 -- rvtest_data physical address stored
	LA (a0, rvtest_data)                                            //loads the address in a0
	LI a1, (PTE_A | PTE_X | PTE_V)                                  //sets the permission bits(PTE.GDRW = 0, PTE.AXV=111)
	PTE_SETUP_RV32(a0, a1, t0, t1, va_data, LEVEL1)                 //PTE setup at level 1
    
    
    // PTE setup for 0x93003114 -> signature_x13_1
	la a0, rvtest_sig_begin   						                // Physical address of signature area
	li a1, ( PTE_D | PTE_A | PTE_R | PTE_W | PTE_X | PTE_V)         // sets the permissions bits 
	PTE_SETUP_RV32(a0, a1, t0, t1, sig_data, LEVEL0) 			    // PTE Setup for signature area address at pgtbl0
#-----------------------------------------------------------------------------------------------------------------------------

#---------------satp mode setup-----------------#
	LI (t0, sig_data)                                                       
	LA (t1, rvtest_sig_begin)                                                      
	sub t0, t0, t1 					        		                // (VA-PA) Note: VA > PA 
	add s11, x13, t0				        		                // Translation of Signature reg

    SATP_SETUP_SV32                                                 // set the SATP for virtualization

	/* Save Virtual addresses in of Code and Data 
	in their respective S-mode save area */

	/****** code ******/
	SIGNATURE_AREA_SETUP_CODE(va, pa)						// signature area for code 
	SIGNATURE_AREA_SETUP_DATA(va_data,rvtest_data)				// signature area for data 
	SIGNATURE_AREA_SETUP_SIG(sig_data, signature_x13_1)				// signature area for signature 
	SIGNATURE_AREA_SETUP_VMEM(va_data, rvtest_data)				// signature area for vmem
	sfence.vma                                                              // flush the TLB
#-----------------------------------------------------------------------------------------------------------------------------

	RVTEST_GOTO_LOWER_MODE	Smode		                                    // Switching to S mode

#-----------------------------------------------------------------------------------------------------------------------------
vm_en:
	LI (a4, 0xdead)
	RVTEST_SIGUPD(s11,a4)                                                   // Verification of virtualization enabeled
    
STORE_CHECK:
#   ERRH, ERRL
    LI      (t1, 0xBEEFCAFE)                                // initializing the register for store
    LA      (t2, va_data)                                   // Loading address of the page start with pmp restrictions
    sw      t1, 2(t2)                                       // Attempting misaligned store at that address

# #  Test LW
LOAD_CHECK:
#   ERRH, ERRL
    LA      (t2, va_data)                                   // Loading address of the page start with pmp restrictions
    lw      t1, 2(t2)                                       // Attempting misaligned load at that address

    add     s3, s2, s1
    nop                                             
        
	LI (a4, 0xbeef)                                                         // Verification of coming back from trap handler 
	RVTEST_SIGUPD(s11,a4)

	RVTEST_GOTO_MMODE		                                                // Switching back to M mode
        
        nop
	LI (a4, 0x123)
	RVTEST_SIGUPD(x13,a4)                                                   // Verification of virtualization disabled

#endif

#-----------------------------------------------------------------------------------------------------------------------------
RVTEST_CODE_END
# RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 24
rvtest_data:
.word 0xbeefcafe
.word 0xbabecafe
.word 0xbabecafe
.word 0xbabecafe


#ifdef rvtest_strap_routine
.align 12
rvtest_slvl1_pg_tbl:
    RVTEST_PTE_IDENT_MAP(0,2,RVTEST_ALLPERMS)
#endif
RVTEST_DATA_END
RVMODEL_DATA_BEGIN
rvtest_sig_begin:
sig_begin_canary:
CANARY;

// test signatures initialization
signature_x13_1:
    .fill 32*(XLEN/32),4,0xcafebeef

// trap signatures initialization
#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif

sig_end_canary:
CANARY;
rvtest_sig_end:
RVMODEL_DATA_END
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=
