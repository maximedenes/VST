# See the file BUILD_ORGANIZATION for
# explanations of why this is the way it is

default_target: .loadpath version.vo msl veric floyd progs

COMPCERT ?= compcert
-include CONFIGURE
#Note:  You can make a CONFIGURE file with the definition
#   COMPCERT=../compcert
# if, for example, you want to build from a compcert distribution
# that is sitting in a sister directory to vst.
#
# One can also add in CONFIGURE the line
#   COQBIN=/path/to/bin/
# to a directory containing the coqc/coqdep/... you wish to use, if it
# is not your path.

#Note2:  By default, the rules for converting .c files to .v files
# are inactive.  To activate them, do something like
#CLIGHTGEN=$(COMPCERT)/clightgen 

#Note3: for SSReflect, one solution is to install MathComp 1.6
# somewhere add this line to a CONFIGURE file
# MATHCOMP=/my/path/to/mathcomp
# and on Windows, it might be   MATHCOMP=c:/Coq/lib/user-contrib/mathcomp

# ANNOTATE=true   # label chatty output from coqc with file name
ANNOTATE=silent   # suppress chatty output from coqc
# ANNOTATE=false  # leave chatty output of coqc unchanged

CC_TARGET=compcert/cfrontend/Clight.vo
CC_DIRS= lib common cfrontend exportclight
VSTDIRS= msl sepcomp veric floyd progs concurrency ccc26x86 
OTHERDIRS= wand_demo sha fcf hmacfcf tweetnacl20140427 hmacdrbg aes mailbox
DIRS = $(VSTDIRS) $(OTHERDIRS)
CONCUR = concurrency

CV1=$(shell cat compcert/VERSION)
CV2=$(shell cat $(COMPCERT)/VERSION)

ifneq ($(CV1), $(CV2))
 $(error COMPCERT_VERSION=$(CV1) but $(COMPCERT)/VERSION=$(CV2))
endif

ifeq ($(wildcard $(COMPCERT)/*/Clight.vo), )
ifeq ($(COMPCERT), compcert)
else
 $(error FIRST BUILD COMPCERT, by:  cd $(COMPCERT); make clightgen)
endif
endif

EXTFLAGS= -R $(COMPCERT) compcert

# for SSReflect
ifdef MATHCOMP
 EXTFLAGS:=$(EXTFLAGS) -R $(MATHCOMP) mathcomp
endif

COQFLAGS=$(foreach d, $(VSTDIRS), $(if $(wildcard $(d)), -Q $(d) VST.$(d))) $(foreach d, $(OTHERDIRS), $(if $(wildcard $(d)), -Q $(d) $(d))) $(EXTFLAGS)
DEPFLAGS:=$(COQFLAGS)

# DO NOT DISABLE coqc WARNINGS!  That would hinder the Coq team's continuous integration.
# Warning setting  -w -deprecated-focus  is needed until we no longer
# list version 8.7._ in the COQVERSION list.
COQC=$(COQBIN)coqc -w -deprecated-focus,-deprecated-unfocus
COQTOP=$(COQBIN)coqtop
COQDEP=$(COQBIN)coqdep $(DEPFLAGS)
COQDOC=$(COQBIN)coqdoc -d doc/html -g  $(DEPFLAGS)

MSL_FILES = \
  Axioms.v Extensionality.v base.v eq_dec.v sig_isomorphism.v \
  ageable.v sepalg.v psepalg.v age_sepalg.v \
  sepalg_generators.v functors.v sepalg_functors.v combiner_sa.v \
  cross_split.v join_hom_lemmas.v cjoins.v \
  boolean_alg.v tree_shares.v shares.v pshares.v \
  knot.v knot_prop.v \
  knot_lemmas.v knot_unique.v \
  knot_hered.v \
  knot_full.v knot_full_variant.v knot_shims.v knot_full_sa.v \
  corable.v corable_direct.v \
  predicates_hered.v predicates_sl.v subtypes.v subtypes_sl.v \
  contractive.v predicates_rec.v \
  msl_direct.v msl_standard.v msl_classical.v \
  predicates_sa.v \
  normalize.v \
  env.v corec.v Coqlib2.v sepalg_list.v op_classes.v \
  simple_CCC.v seplog.v alg_seplog.v alg_seplog_direct.v log_normalize.v \
  ghost.v ghost_seplog.v \
  iter_sepcon.v ramification_lemmas.v wand_frame.v wandQ_frame.v #age_to.v

SEPCOMP_FILES = \
  Address.v \
  step_lemmas.v \
  extspec.v \
  rg_lemmas.v \
  FiniteMaps.v \
  mem_lemmas.v mem_wd.v \
  nucular_semantics.v \
  semantics.v semantics_lemmas.v \
  globalSep.v simulations.v \
  simulations_lemmas.v \
  structured_injections.v \
  effect_semantics.v effect_simulations.v effect_simulations_lemmas.v \
  effect_properties.v \
  event_semantics.v \
  full_composition.v \
  closed_safety.v compcert.v \
  val_casted.v \
  reach.v \
  arguments.v \
  internal_diagram_trans.v \
  wholeprog_simulations.v \
  wholeprog_lemmas.v

# what is:  erasure.v context.v context_equiv.v jstep.v

CONCUR_FILES= \
  addressFiniteMap.v cast.v compcert_imports.v \
  compcert_threads_lemmas.v threadPool.v  \
  semantics.v \
  concurrent_machine.v disjointness.v dry_context.v dry_machine.v \
  dry_machine_lemmas.v dry_machine_step_lemmas.v \
  Clight_bounds.v enums_equality.v\
  ClightSemantincsForMachines.v Clight_coreSemantincsForMachines.v \
  JuicyMachineModule.v DryMachineSource.v \
  erased_machine.v erasure_proof.v erasure_safety.v erasure_signature.v \
  fineConc_safe.v inj_lemmas.v join_sm.v juicy_machine.v \
  lksize.v \
  main.v mem_obs_eq.v memory_lemmas.v permissions.v permjoin_def.v pos.v pred_lemmas.v \
  bounded_maps.v \
  rc_semantics.v rc_semantics_lemmas.v \
  scheduler.v TheSchedule.v sepcomp.v seq_lemmas.v ssromega.v stack.v \
  threads_lemmas.v wf_lemmas.v \
  x86_inj.v x86_safe.v x86_context.v fineConc_x86.v executions.v SC_erasure.v spinlocks.v \
  sync_preds_defs.v sync_preds.v oracular_refinement.v \
  semax_conc_pred.v semax_conc.v semax_to_juicy_machine.v \
  semax_invariant.v semax_initial.v \
  semax_simlemmas.v cl_step_lemmas.v \
  semax_progress.v semax_preservation.v \
  semax_preservation_jspec.v \
  semax_preservation_local.v \
  semax_preservation_acquire.v \
  semax_safety_release.v \
  semax_safety_makelock.v \
  semax_safety_freelock.v \
  semax_safety_spawn.v \
  resource_decay_lemmas.v \
  rmap_locking.v \
  permjoin.v \
  resource_decay_join.v join_lemmas.v coqlib5.v \
  konig.v safety.v \
	reestablish.v \
	lifting.v lifting_safety.v \
linking_spec.v	\
  machine_semantics.v machine_semantics_lemmas.v machine_simulation.v \
  coinductive_safety.v CoreSemantics_sum.v \
  concurrent_machine_rec.v HybridMachine.v

#  reach_lemmas.v linking_inv.v  call_lemmas.v ret_lemmas.v \

PACO_FILES= \
  hpattern.v\
  paco.v\
  paco0.v\
  paco1.v\
  paco2.v\
  paco3.v\
  paco4.v\
  paco5.v\
  paco6.v\
  paco7.v\
  pacodef.v\
  paconotation.v\
  pacotac.v\
  pacotacuser.v\
  tutorial.v

CCC26x86_FILES = \
  Archi.v Bounds.v Conventions1.v Conventions.v Separation.v \
  Decidableplus.v Locations.v Op.v Ordered.v Stacklayout.v Linear.v LTL.v \
  Machregs.v Asm.v \
  Switch.v Cminor.v \
  I64Helpers.v BuiltinEffects.v load_frame.v Asm_coop.v Asm_eff.v \
  Asm_nucular.v Asm_event.v \
  Clight_coop.v Clight_eff.v

LINKING_FILES= \
  sepcomp.v \
  pos.v \
  stack.v \
  pred_lemmas.v \
  rc_semantics.v \
  rc_semantics_lemmas.v \
  linking.v \
  compcert_linking.v \
  compcert_linking_lemmas.v \
  core_semantics_tcs.v \
  linking_spec.v \
  erase_juice.v \
  safety.v \
  semax_linking.v \
  cast.v \
  tuple.v \
  finfun.v

VERIC_FILES= \
  base.v Memory.v shares.v splice.v rmaps.v rmaps_lemmas.v compcert_rmaps.v Cop2.v juicy_base.v type_induction.v composite_compute.v align_mem.v change_compspecs.v \
  tycontext.v lift.v expr.v expr2.v environ_lemmas.v \
  binop_lemmas.v binop_lemmas2.v binop_lemmas3.v binop_lemmas4.v binop_lemmas5.v binop_lemmas6.v \
  expr_lemmas.v expr_lemmas2.v expr_lemmas3.v expr_lemmas4.v \
  expr_rel.v extend_tc.v \
  Clight_lemmas.v Clight_new.v Clightnew_coop.v Clight_core.v Clight_sim.v \
  slice.v res_predicates.v own.v seplog.v mapsto_memory_block.v assert_lemmas.v \
  juicy_mem.v juicy_mem_lemmas.v local.v juicy_mem_ops.v juicy_safety.v juicy_extspec.v \
  semax.v semax_lemmas.v semax_call.v semax_straight.v semax_loop.v semax_switch.v semax_congruence.v \
  initial_world.v initialize.v semax_prog.v semax_ext.v SeparationLogic.v SeparationLogicSoundness.v  \
  NullExtension.v SequentialClight.v superprecise.v jstep.v address_conflict.v valid_pointer.v coqlib4.v \
  semax_ext_oracle.v mem_lessdef.v Clight_sim.v age_to_resource_at.v aging_lemmas.v

FLOYD_FILES= \
   coqlib3.v base.v seplog_tactics.v typecheck_lemmas.v val_lemmas.v assert_lemmas.v \
   base2.v go_lower.v \
   library.v proofauto.v computable_theorems.v \
   type_induction.v align_compatible_dec.v reptype_lemmas.v aggregate_type.v aggregate_pred.v \
   nested_pred_lemmas.v compact_prod_sum.v \
   sublist.v sublist2.v smt_test.v extract_smt.v \
   client_lemmas.v canon.v canonicalize.v closed_lemmas.v jmeq_lemmas.v \
   compare_lemmas.v sc_set_load_store.v \
   loadstore_mapsto.v loadstore_field_at.v field_compat.v nested_loadstore.v \
   call_lemmas.v extcall_lemmas.v forward_lemmas.v forward.v \
   entailer.v globals_lemmas.v \
   local2ptree_denote.v local2ptree_eval.v fieldlist.v mapsto_memory_block.v\
   nested_field_lemmas.v efield_lemmas.v proj_reptype_lemmas.v replace_refill_reptype_lemmas.v \
   data_at_rec_lemmas.v field_at.v field_at_wand.v stronger.v \
   for_lemmas.v semax_tactics.v expr_lemmas.v diagnosis.v simple_reify.v simpl_reptype.v \
   freezer.v deadvars.v Clightnotations.v unfold_data_at.v hints.v reassoc_seq.v
#real_forward.v

# CONCPROGS must be kept separate (see util/PACKAGE), and
# each line that contains the word CONCPROGS must be deletable independently
CONCPROGS= conclib.v incr.v verif_incr.v cond.v verif_cond.v ghost.v

PROGS_FILES= \
  $(CONCPROGS) \
  bin_search.v list_dt.v verif_reverse.v verif_reverse2.v verif_reverse3.v verif_queue.v verif_queue2.v verif_sumarray.v \
  insertionsort.v reverse.v queue.v sumarray.v message.v string.v object.v \
  revarray.v verif_revarray.v insertionsort.v append.v min.v int_or_ptr.v \
  dotprod.v strlib.v \
  verif_min.v verif_float.v verif_global.v verif_ptr_compare.v \
  verif_nest3.v verif_nest2.v verif_load_demo.v verif_store_demo.v \
  logical_compare.v verif_logical_compare.v field_loadstore.v  verif_field_loadstore.v \
  even.v verif_even.v odd.v verif_odd.v verif_evenodd_spec.v  \
  merge.v verif_merge.v verif_append.v verif_append2.v bst.v bst_oo.v verif_bst.v verif_bst_oo.v \
  verif_bin_search.v verif_floyd_tests.v \
  verif_sumarray2.v verif_switch.v verif_message.v verif_object.v \
  funcptr.v verif_funcptr.v tutorial1.v  \
  verif_int_or_ptr.v verif_union.v verif_cast_test.v verif_dotprod.v \
  verif_strlib.v
# verif_insertion_sort.v

SHA_FILES= \
  general_lemmas.v SHA256.v common_lemmas.v pure_lemmas.v sha_lemmas.v functional_prog.v \
  sha.v spec_sha.v verif_sha_init.v \
  verif_sha_update.v verif_sha_update3.v verif_sha_update4.v \
  bdo_lemmas.v verif_sha_bdo.v  \
  verif_sha_bdo4.v verif_sha_bdo7.v verif_sha_bdo8.v \
  verif_sha_final2.v verif_sha_final3.v verif_sha_final.v \
  verif_addlength.v verif_SHA256.v call_memcpy.v

HMAC_FILES= \
  HMAC_functional_prog.v HMAC256_functional_prog.v \
  vst_lemmas.v hmac_pure_lemmas.v hmac_common_lemmas.v \
  hmac.v spec_hmac.v verif_hmac_cleanup.v \
  verif_hmac_init_part1.v verif_hmac_init_part2.v verif_hmac_init.v\
  verif_hmac_update.v verif_hmac_final.v verif_hmac_simple.v \
  verif_hmac_double.v verif_hmac_crypto.v protocol_spec_hmac.v

HKDF_FILES= \
  hkdf_functional_prog.v hkdf.v hkdf_compspecs.v spec_hkdf.v \
  verif_hkdf_extract.v verif_hkdf_expand.v verif_hkdf.v

FCF_FILES= \
  Admissibility.v Encryption.v NotationV1.v RndDup.v \
  Array.v NotationV2.v RndGrpElem.v \
  Asymptotic.v  Encryption_PK.v OracleCompFold.v RndInList.v \
  Bernoulli.v EqDec.v OracleHybrid.v RndListElem.v \
  Blist.v ExpectedPolyTime.v OTP.v RndNat.v \
  Class.v FCF.v PRF.v RndPerm.v \
  Comp.v Fold.v PRF_Convert.v SemEquiv.v \
  CompFold.v GenTacs.v PRG.v GroupTheory.v  \
  Crypto.v HasDups.v ProgramLogic.v StdNat.v \
  DetSem.v Hybrid.v ProgTacs.v Tactics.v \
  DiffieHellman.v Limit.v TwoWorldsEquiv.v \
  DistRules.v  WC_PolyTime.v \
  DistSem.v Lognat.v Rat.v WC_PolyTime_old.v \
  DistTacs.v NoDup_gen.v RepeatCore.v SplitVector.v \
  PRF_DRBG.v HMAC_DRBG_nonadaptive.v HMAC_DRBG_definitions_only.v \
  map_swap.v
# ConstructedFunc.v Encryption_2W.v Sigma.v ListHybrid.v Procedure.v PRP_PRF.v RandPermSwitching.v State.v

#FCF_FILES= \
#  Limit.v Blist.v StdNat.v Rat.v EqDec.v Fold.v Comp.v DetSem.v DistSem.v \
#  DistRules.v DistTacs.v ProgTacs.v GenTacs.v Crypto.v SemEquiv.v \
#  ProgramLogic.v RndNat.v Bernoulli.v FCF.v HasDups.v CompFold.v \
#  RepeatCore.v PRF_Encryption_IND_CPA.v PRF.v Array.v Encryption.v \
#  Asymptotic.v Admissibility.v RndInList.v OTP.v RndGrpElem.v \
#  GroupTheory.v WC_PolyTime.v RndListElem.v RndPerm.v NoDup_gen.v \
#  Hybrid.v OracleCompFold.v PRF_Convert.v

HMACFCF_FILES= \
  splitVector.v cAU.v hF.v HMAC_spec.v NMAC_to_HMAC.v \
  GNMAC_PRF.v GHMAC_PRF.v HMAC_PRF.v

HMACEQUIV_FILES= \
  HMAC256_functional_prog.v ShaInstantiation.v XorCorrespondence.v \
  sha_padding_lemmas.v Bruteforce.v ByteBitRelations.v \
  HMAC_common_defs.v HMAC_spec_pad.v HMAC256_spec_pad.v \
  HMAC_spec_concat.v HMAC256_spec_concat.v \
  HMAC_spec_list.v HMAC256_spec_list.v \
  HMAC_spec_abstract.v HMAC_equivalence.v HMAC256_equivalence.v \
  HMAC_isPRF.v HMAC256_isPRF.v

TWEETNACL_FILES = \
  split_array_lemmas.v Salsa20.v Snuffle.v tweetNaclBase.v \
  verif_salsa_base.v tweetnaclVerifiableC.v spec_salsa.v \
  verif_ld_st.v verif_fcore_loop1.v verif_fcore_loop2.v \
  verif_fcore_jbody.v verif_fcore_loop3.v \
  verif_fcore_epilogue_hfalse.v verif_fcore_epilogue_htrue.v \
  verif_fcore.v verif_crypto_core.v \
  verif_crypto_stream_salsa20_xor.v verif_crypto_stream.v \
  verif_verify.v

HMACDRBG_FILES = \
  entropy.v entropy_lemmas.v DRBG_functions.v HMAC_DRBG_algorithms.v \
  HMAC256_DRBG_functional_prog.v HMAC_DRBG_pure_lemmas.v \
  HMAC_DRBG_update.v \
  hmac_drbg.v hmac_drbg_compspecs.v \
  spec_hmac_drbg.v HMAC256_DRBG_bridge_to_FCF.v spec_hmac_drbg_pure_lemmas.v \
  HMAC_DRBG_common_lemmas.v  HMAC_DRBG_pure_lemmas.v \
  drbg_protocol_specs.v \
  verif_hmac_drbg_update_common.v verif_hmac_drbg_update.v \
  verif_hmac_drbg_reseed_common.v verif_hmac_drbg_WF.v \
  verif_hmac_drbg_generate_common.v \
  verif_hmac_drbg_seed_common.v verif_hmac_drbg_reseed.v \
  verif_hmac_drbg_generate.v verif_hmac_drbg_seed_buf.v verif_mocked_md.v \
  verif_hmac_drbg_seed.v verif_hmac_drbg_NISTseed.v verif_hmac_drbg_other.v \
  drbg_protocol_proofs.v verif_hmac_drbg_generate_abs.v
#  mocked_md.v mocked_md_compspecs.v

# these are only the top-level AES files, but they depend on many other AES files, so first run "make depend"
AES_FILES = \
  verif_encryption_LL.v verif_gen_tables_LL.v verif_setkey_enc_LL.v equiv_encryption.v

# DRBG_Files = \
#  hmac_drbg.v HMAC256_DRBG_functional_prog.v hmac_drbg_compspecs.v \
#  entropy.v DRBG_functions.v HMAC_DRBG_algorithms.v spec_hmac_drbg.v \
#  HMAC_DRBG_pure_lemmas.v HMAC_DRBG_common_lemmas.v verif_mocked_md.v \
#  verif_hmac_drbg_update.v verif_hmac_drbg_reseed.v verif_hmac_drbg_generate.v


# SINGLE_C_FILES are those to be clightgen'd individually with -normalize flag
# LINKED_C_FILES are those that need to be clightgen'd in a batch with others

SINGLE_C_FILES = reverse.c revarray.c queue.c queue2.c message.c object.c insertionsort.c float.c global.c logical_compare.c nest2.c nest3.c ptr_compare.c load_demo.c store_demo.c dotprod.c string.c field_loadstore.c merge.c append.c bin_search.c bst.c bst_oo.c min.c switch.c funcptr.c floyd_tests.c incr.c cond.c sumarray.c sumarray2.c int_or_ptr.c union.c cast_test.c strlib.c

LINKED_C_FILES = even.c odd.c
C_FILES = $(SINGLE_C_FILES) $(LINKED_C_FILES)

FILES = \
 $(MSL_FILES:%=msl/%) \
 $(SEPCOMP_FILES:%=sepcomp/%) \
 $(VERIC_FILES:%=veric/%) \
 $(FLOYD_FILES:%=floyd/%) \
 $(PROGS_FILES:%=progs/%) \
 $(WAND_DEMO_FILES:%=wand_demo/%) \
 $(SHA_FILES:%=sha/%) \
 $(HMAC_FILES:%=sha/%) \
 $(FCF_FILES:%=fcf/%) \
 $(HMACFCF_FILES:%=hmacfcf/%) \
 $(HMACEQUIV_FILES:%=sha/%) \
 $(TWEETNACL_FILES:%=tweetnacl20140427/%) \
 $(HMACDRBG_Files:%=hmacdrbg/%)
# $(CCC26x86_FILES:%=ccc26x86/%) \
# $(CONCUR_FILES:%=concurrency/%) \
# $(DRBG_FILES:%=verifiedDrbg/spec/%)

%_stripped.v: %.v
# e.g., 'make progs/verif_reverse_stripped.v will remove the tutorial comments
# from progs/verif_reverse.v
	grep -v '^.[*][*][ )]' $*.v >$@

%.vo: %.v
	@echo COQC $*.v
ifeq ($(TIMINGS), true)
#	bash -c "wc $*.v >>timings; date +'%s.%N before' >> timings; $(COQC) $(COQFLAGS) $*.v; date +'%s.%N after' >>timings" 2>>timings
	echo true timings
	@bash -c "/usr/bin/time --output=TIMINGS -a -f '%e real, %U user, %S sys %M mem, '\"$(shell wc $*.v)\" $(COQC) $(COQFLAGS) $*.v"
#	echo -n $*.v " " >>TIMINGS; bash -c "/usr/bin/time -o TIMINGS -a $(COQC) $(COQFLAGS) $*.v"
else ifeq ($(TIMINGS), simple)
	@/usr/bin/time -f 'TIMINGS %e real, %U user, %S sys %M kbytes: '"$*.v" $(COQC) $(COQFLAGS) $*.v
else ifeq ($(strip $(ANNOTATE)), true)
	@$(COQC) $(COQFLAGS) $*.v | awk '{printf "%s: %s\n", "'$*.v'", $$0}'
else ifeq ($(strip $(ANNOTATE)), silent)
	@$(COQC) $(COQFLAGS) $*.v >/dev/null
else 
	@$(COQC) $(COQFLAGS) $*.v
#	@util/annotate $(COQC) $(COQFLAGS) $*.v 
endif

# you can also write, COQVERSION= 8.6 or-else 8.6pl2 or-else 8.6pl3   (etc.)
COQVERSION= 8.7.0 or-else 8.7.1 or-else 8.7.2 or-else 8.8+beta1
COQV=$(shell $(COQC) -v)
ifeq ($(IGNORECOQVERSION),true)
else
 ifeq ("$(filter $(COQVERSION),$(COQV))","")
  $(error FAILURE: You need Coq $(COQVERSION) but you have this version: $(COQV))
 endif
endif



#  This is causing problems, so commented out.  -- Appel, Feb 23, 2017
# $(COMPCERT)/lib/%.vo: $(COMPCERT)/lib/%.v
# 	@
# $(COMPCERT)/common/%.vo: $(COMPCERT)/common/%.v
# 	@
# $(COMPCERT)/cfrontend/%.vo: $(COMPCERT)/cfrontend/%.v
# 	@
# $(COMPCERT)/exportclight/%.vo: $(COMPCERT)/exportclight/%.v
# 	@
# $(COMPCERT)/flocq/Appli/%.vo: $(COMPCERT)/flocq/Appli/%.v
# 	@
# $(COMPCERT)/flocq/Calc/%.vo: $(COMPCERT)/flocq/Calc/%.v
# 	@
# $(COMPCERT)/flocq/Core/%.vo: $(COMPCERT)/flocq/Core/%.v
# 	@
# $(COMPCERT)/flocq/Prop/%.vo: $(COMPCERT)/flocq/Prop/%.v
# 	@
# $(COMPCERT)/flocq/%.vo: $(COMPCERT)/flocq/%.v
# 	@

travis: default_target progs sha hmac mailbox

files: .loadpath version.vo $(FILES:.v=.vo)

all: default_target files travis hmacdrbg tweetnacl aes


# ifeq ($(COMPCERT), compcert)
# compcert: $(COMPCERT)/exportclight/Clightdefs.vo
# $(COMPCERT)/exportclight/Clightdefs.vo:
# 	cd $(COMPCERT) && $(MAKE) exportclight/Clightdefs.vo
# $(patsubst %.v,sepcomp/%.vo,$(SEPCOMP_FILES)): compcert
# $(patsubst %.v,veric/%.vo,$(VERIC_FILES)): compcert
# $(patsubst %.v,floyd/%.vo,$(FLOYD_FILES)): compcert
# msl/Coqlib2.vo: compcert
# endif
 
msl:     .loadpath version.vo $(MSL_FILES:%.v=msl/%.vo)
sepcomp: .loadpath $(CC_TARGET) $(SEPCOMP_FILES:%.v=sepcomp/%.vo)
ccc26x86:   .loadpath $(CCC26x86_FILES:%.v=ccc26x86/%.vo)
concurrency: .loadpath $(CC_TARGET) $(SEPCOMP_FILES:%.v=sepcomp/%.vo) $(CONCUR_FILES:%.v=concurrency/%.vo)
paco: .loadpath $(PACO_FILES:%.v=concurrency/paco/src/%.vo)
linking: .loadpath $(LINKING_FILES:%.v=linking/%.vo)
veric:   .loadpath $(VERIC_FILES:%.v=veric/%.vo)
floyd:   .loadpath $(FLOYD_FILES:%.v=floyd/%.vo)
progs:   .loadpath $(PROGS_FILES:%.v=progs/%.vo)
wand_demo:   .loadpath $(WAND_DEMO_FILES:%.v=wand_demo/%.vo)
sha:     .loadpath $(SHA_FILES:%.v=sha/%.vo)
hmac:    .loadpath $(HMAC_FILES:%.v=sha/%.vo)
hmacequiv:    .loadpath $(HMAC_FILES:%.v=sha/%.vo)
fcf:     .loadpath $(FCF_FILES:%.v=fcf/%.vo)
hmacfcf: .loadpath $(HMACFCF_FILES:%.v=hmacfcf/%.vo)
tweetnacl: .loadpath $(TWEETNACL_FILES:%.v=tweetnacl20140427/%.vo)
hmac0: .loadpath sha/verif_hmac_init.vo sha/verif_hmac_cleanup.vo sha/verif_hmac_final.vo sha/verif_hmac_simple.vo  sha/verif_hmac_double.vo sha/verif_hmac_update.vo sha/verif_hmac_crypto.vo
hmacdrbg:   .loadpath $(HMACDRBG_FILES:%.v=hmacdrbg/%.vo)
aes: .loadpath $(AES_FILES:%.v=aes/%.vo)
hkdf:    .loadpath $(HKDF_FILES:%.v=sha/%.vo)
# drbg: .loadpath $(DRBG_FILES:%.v=verifiedDrbg/%.vo)
mailbox: .loadpath mailbox/verif_mailbox_all.vo
atomics: .loadpath mailbox/verif_kvnode_atomic.vo mailbox/verif_kvnode_atomic_ra.vo mailbox/verif_hashtable_atomic.vo mailbox/verif_hashtable_atomic_ra.vo 

CGFLAGS =  -DCOMPCERT

$(patsubst %.c,progs/%.vo,$(C_FILES)): compcert

CVFILES = $(patsubst %.c,progs/%.v,$(C_FILES))

cvfiles: $(CVFILES)

dochtml:
	mkdir -p doc/html
	$(COQDOC) $(MSL_FILES:%=msl/%) $(VERIC_FILES:%=veric/%) $(FLOYD_FILES:%=floyd/%) $(SEPCOMP_FILES:%=sepcomp/%)

dochtml-full:
	mkdir -p doc/html
	$(COQDOC) $(FILES)

clean_cvfiles:
	rm $(CVFILES)

ifdef CLIGHTGEN
# SPECIAL-CASE RULES FOR LINKED_C_FILES:
sha/sha.v sha/hmac.v hmacdrbg/hmac_drbg.v sha/hkdf.v: sha/sha.c sha/hmac.c hmacdrbg/hmac_drbg.c sha/hkdf.c
	$(CLIGHTGEN) ${CGFLAGS} $^
progs/even.v: progs/even.c progs/odd.c
	$(CLIGHTGEN) ${CGFLAGS} $^
progs/odd.v: progs/even.v
mailbox/mailbox.v: mailbox/atomic_exchange.c mailbox/mailbox.c
	$(CLIGHTGEN) ${CGFLAGS} $^
# GENERAL RULES FOR SINGLE_C_FILES and NORMAL_C_FILES
$(patsubst %.c,progs/%.v, $(SINGLE_C_FILES)): progs/%.v: progs/%.c
	$(CLIGHTGEN) ${CGFLAGS} -normalize $^
endif

version.v:  VERSION $(MSL_FILES:%=msl/%) $(SEPCOMP_FILES:%=sepcomp/%) $(VERIC_FILES:%=veric/%) $(FLOYD_FILES:%=floyd/%)
	sh util/make_version

_CoqProject _CoqProject-export .loadpath .loadpath-export: Makefile util/coqflags 
	echo $(COQFLAGS) > .loadpath
	util/coqflags > .loadpath-export
	cp .loadpath-export _CoqProject-export
	cp .loadpath _CoqProject

floyd/floyd.coq: floyd/proofauto.vo
	coqtop $(COQFLAGS) -load-vernac-object floyd/proofauto -outputstate floyd/floyd -batch

.depend depend:
#	$(COQDEP) $(filter $(wildcard *.v */*.v */*/*.v),$(FILES))  > .depend
	@echo 'coqdep ... >.depend'
#	$(COQDEP) >.depend `find compcert $(filter $(wildcard *), $(DIRS)) -name "*.v"`
	@$(COQDEP) 2>&1 >.depend `find compcert $(filter $(wildcard *), $(DIRS)) -name "*.v"` | grep -v 'Warning:.*found in the loadpath' || true

depend-paco:
	$(COQDEP) > .depend-paco $(PACO_FILES:%.v=concurrency/paco/src/%.v)

clean:
	rm -f version.vo .version.vo.aux version.glob .lia.cache .nia.cache floyd/floyd.coq .loadpath .depend _CoqProject $(wildcard */.*.aux)  $(wildcard */*.glob) $(wildcard */*.vo) compcert/*/*.vo compcert/*/*/*.vo
	rm -fr doc/html

clean-concur:
	rm -f $(CONCUR_FILES:%.v=%.vo) $(CONCUR_FILES:%.v=%.glob)

clean-linking:
	rm -f $(LINKING_FILES:%.v=linking/%.vo) $(LINKING_FILES:%.v=linking/%.glob)

count:
	wc $(FILES)

count-linking:
	wc $(LINKING_FILES:%.v=linking/%.v)

util/calibrate: util/calibrate.ml
	cd util; ocamlopt.opt calibrate.ml -o calibrate

calibrate: util/calibrate
	-/usr/bin/time -f 'TIMINGS %e real, %U user, %S sys %M kbytes: CALIBRATE' util/calibrate

# $(CC_TARGET): compcert/make
#	(cd compcert; ./make)

# The .depend file is divided into two parts, .depend and .depend-concur,
# in order to work around a limitation in Cygwin about how long one
# command line can be.  (Or at least, it seems to be a solution to some
# such problem, not sure exactly.  -- Andrew)
include .depend
-include .depend-concur
