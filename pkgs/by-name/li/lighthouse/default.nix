{ clang
, cmake
, fetchFromGitHub
, fetchurl
, lib
, llvmPackages
, openssl
, sqlite
, rust-jemalloc-sys
, protobuf
, rustPlatform
, postgresql
, foundry
, pkg-config
,
}:
let
  slasherContractVersion = "0.12.1";
  slasherContractSrc = fetchurl {
    url = "https://raw.githubusercontent.com/ethereum/eth2.0-specs/v${slasherContractVersion}/deposit_contract/contracts/validator_registration.json";
    sha256 = "sha256-ZslAe1wkmkg8Tua/AmmEfBmjqMVcGIiYHwi+WssEwa8=";
  };

  slasherContractTestVersion = "0.9.2.1";
  slasherContractTestnetSrc = fetchurl {
    url = "https://raw.githubusercontent.com/sigp/unsafe-eth2-deposit-contract/v${slasherContractTestVersion}/unsafe_validator_registration.json";
    sha256 = "sha256-aeTeHRT3QtxBRSNMCITIWmx89vGtox2OzSff8vZ+RYY=";
  };
in
rustPlatform.buildRustPackage rec {
  pname = "lighthouse";
  version = "7.0.1";

  src = fetchFromGitHub {
    owner = "sigp";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-0nClqRSLwKnTNAMsvX5zzN2PbVJ51xtQv48cHSqHLAY=";
  };

  patches = [
    ./use-system-sqlite.patch
  ];

  cargoHash = "sha256-tQVZXZzcit4seBgmW4WEyNOkLzswX/I36DphORb7w30=";
  useFetchCargoVendor = true;

  enableParallelBuilding = true;

  cargoBuildFlags = [ "--package lighthouse" ];

  nativeBuildInputs = [
    rustPlatform.bindgenHook
    cmake
    pkg-config
    protobuf
  ];

  buildInputs = [ rust-jemalloc-sys sqlite ];

  buildFeatures = [ "modern" "slasher-lmdb" ];

  # Needed to get openssl-sys to use pkg-config.
  OPENSSL_NO_VENDOR = true;
  OPENSSL_DIR = "${lib.getDev openssl}";
  OPENSSL_LIB_DIR = "${lib.getLib openssl}/lib";

  # common crate tries to fetch the compiled version from an URL
  # see: https://github.com/sigp/lighthouse/blob/stable/common/deposit_contract/build.rs#L30
  LIGHTHOUSE_DEPOSIT_CONTRACT_SPEC_URL = "file:${slasherContractSrc}";

  # common crate tries to fetch the compiled version from an URL
  # see: https://github.com/sigp/lighthouse/blob/stable/common/deposit_contract/build.rs#L33
  LIGHTHOUSE_DEPOSIT_CONTRACT_TESTNET_URL = "file:${slasherContractTestnetSrc}";

  # This is needed by the unit tests.
  FORK_NAME = "capella";

  cargoTestFlags = [
    "--workspace"
    "--exclude beacon_chain"
    "--exclude beacon_node"
    "--exclude http_api"
    "--exclude lighthouse"
    "--exclude lighthouse_network"
    "--exclude network"
    "--exclude slashing_protection"
    "--exclude watch"
    "--exclude web3signer_tests"
  ];

  checkFeatures = [ ];

  # All of these tests require network access
  checkFlags = [
    "--skip basic"
    "--skip deposit_tree::cache_consistency"
    "--skip deposit_tree::double_update"
    "--skip deposit_tree::updating"
    "--skip eth1_cache::big_skip"
    "--skip eth1_cache::double_update"
    "--skip eth1_cache::pruning"
    "--skip eth1_cache::simple_scenario"
    "--skip fast::deposit_cache_query"
    "--skip http::incrementing_deposits"
    "--skip persist::test_persist_caches"
    "--skip service::tests::tests::test_dht_persistence"
    "--skip time::test::test_reinsertion_updates_timeout"
    "--skip tests::broadcast_should_send_to_all_bns"
    "--skip tests::check_candidate_order"
    "--skip tests::first_success_should_try_nodes_in_order"
    "--skip tests::update_all_candidates_should_update_sync_status"
    "--skip engine_api::http::test::forkchoice_updated_v1_request"
    "--skip engine_api::http::test::forkchoice_updated_v1_with_payload_attributes_request"
    "--skip engine_api::http::test::get_block_by_hash_request"
    "--skip engine_api::http::test::get_block_by_number_request"
    "--skip engine_api::http::test::get_payload_v1_request"
    "--skip engine_api::http::test::geth_test_vectors"
    "--skip engine_api::http::test::new_payload_v1_request"
    "--skip test::finds_valid_terminal_block_hash"
    "--skip test::produce_three_valid_pos_execution_blocks"
    "--skip test::rejects_invalid_terminal_block_hash"
    "--skip test::rejects_terminal_block_with_equal_timestamp"
    "--skip test::rejects_unknown_terminal_block_hash"
    "--skip test::test_forked_terminal_block"
    "--skip test::verifies_valid_terminal_block_hash"
    "--skip invalid_attestation_unknown_target_root"
    "--skip invalid_attestation_unknown_beacon_block_root"
    "--skip invalid_block_unknown_parent"
    "--skip justified_balances"
    "--skip justified_and_finalized_blocks"
    "--skip invalid_block_future_slot"
    "--skip progressive_balances_cache_attester_slashing"
    "--skip justified_checkpoint_updates_with_descendent_first_justification"
    "--skip justified_checkpoint_updates_with_descendent"
    "--skip justified_checkpoint_updates_with_non_descendent"
    "--skip valid_attestation"
    "--skip valid_attestation_skip_across_epoch"
    "--skip weak_subjectivity_check_epoch_boundary_is_skip_slot"
    "--skip progressive_balances_cache_proposer_slashing"
    "--skip weak_subjectivity_check_fails_late_epoch"
    "--skip weak_subjectivity_check_fails_early_epoch"
    "--skip weak_subjectivity_check_fails_incorrect_root"
    "--skip weak_subjectivity_check_epoch_boundary_is_skip_slot_failure"
    "--skip weak_subjectivity_check_passes"
    "--skip weak_subjectivity_fail_on_startup"
    "--skip weak_subjectivity_pass_on_startup"
    "--skip can_read_finalized_block"
    "--skip invalid_block_finalized_descendant"
    "--skip invalid_block_finalized_slot"
    "--skip returns_200_ok"
    "--skip release_tests::attestation_aggregation_insert_get_prune"
    "--skip release_tests::attestation_duplicate"
    "--skip release_tests::attestation_get_max"
    "--skip release_tests::attestation_pairwise_overlapping"
    "--skip release_tests::attestation_rewards"
    "--skip release_tests::cross_fork_attester_slashings"
    "--skip release_tests::cross_fork_exits"
    "--skip release_tests::cross_fork_proposer_slashings"
    "--skip release_tests::duplicate_proposer_slashing"
    "--skip release_tests::max_coverage_attester_proposer_slashings"
    "--skip release_tests::max_coverage_different_indices_set"
    "--skip release_tests::max_coverage_effective_balances"
    "--skip release_tests::overlapping_max_cover_attester_slashing"
    "--skip release_tests::prune_attester_slashing_noop"
    "--skip release_tests::prune_proposer_slashing_noop"
    "--skip release_tests::simple_max_cover_attester_slashing"
    "--skip release_tests::sync_contribution_aggregation_insert_get_prune"
    "--skip release_tests::sync_contribution_duplicate"
    "--skip release_tests::sync_contribution_with_fewer_bits"
    "--skip release_tests::sync_contribution_with_more_bits"
    "--skip release_tests::test_earliest_attestation"
    "--skip per_block_processing::tests::invalid_bad_proposal_2_signature"
    "--skip per_block_processing::tests::invalid_block_header_state_slot"
    "--skip per_block_processing::tests::invalid_block_signature"
    "--skip per_block_processing::tests::invalid_deposit_bad_merkle_proof"
    "--skip per_block_processing::tests::invalid_deposit_count_too_small"
    "--skip per_block_processing::tests::invalid_deposit_deposit_count_too_big"
    "--skip per_block_processing::tests::invalid_deposit_invalid_pub_key"
    "--skip per_block_processing::tests::invalid_deposit_wrong_sig"
    "--skip per_block_processing::tests::invalid_parent_block_root"
    "--skip per_block_processing::tests::invalid_proposer_slashing_duplicate_slashing"
    "--skip per_block_processing::tests::invalid_proposer_slashing_proposal_epoch_mismatch"
    "--skip per_block_processing::tests::invalid_proposer_slashing_proposals_identical"
    "--skip per_block_processing::tests::invalid_proposer_slashing_proposer_unknown"
    "--skip per_block_processing::tests::invalid_randao_reveal_signature"
    "--skip per_block_processing::tests::valid_4_deposits"
    "--skip per_block_processing::tests::valid_block_ok"
    "--skip per_block_processing::tests::valid_insert_attester_slashing"
    "--skip per_block_processing::tests::valid_insert_proposer_slashing"
    "--skip per_epoch_processing::tests::release_tests::altair_state_on_base_fork"
    "--skip per_epoch_processing::tests::release_tests::base_state_on_altair_fork"
    "--skip per_epoch_processing::tests::runs_without_error"
    "--skip per_block_processing::tests::block_replayer_peeking_state_roots"
    "--skip per_block_processing::tests::fork_spanning_exit"
    "--skip per_block_processing::tests::invalid_attester_slashing_1_invalid"
    "--skip per_block_processing::tests::invalid_attester_slashing_2_invalid"
    "--skip per_block_processing::tests::invalid_attester_slashing_not_slashable"
    "--skip per_block_processing::tests::invalid_bad_proposal_1_signature"
  ];

  meta = {
    description = "Ethereum consensus client in Rust";
    homepage = "https://github.com/sigp/lighthouse";
    mainProgram = "lighthouse";
    platforms = [ "x86_64-linux" ];
  };
}
