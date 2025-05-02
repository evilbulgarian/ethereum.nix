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

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "quick-protobuf-0.8.1" = "sha256-dgePLYCeoEZz5DGaLifhf3gEIPaL7XB0QT9wRKY8LJg=";
      "libmdbx-0.1.4" = "sha256-ONp4uPkVCN84MObjXorCZuSjnM6uFSMXK1vdJiX074o=";
      "lmdb-rkv-0.14.0" = "sha256-sxmguwqqcyOlfXOZogVz1OLxfJPo+Q0+UjkROkbbOCk=";
      "xdelta3-0.1.5" = "sha256-aewSexOZCrQoKZQa+SGP8i6JKXstaxF3W2LVEhCSmPs=";
    };
  };

  enableParallelBuilding = true;

  cargoBuildFlags = [ "--package lighthouse" ];

  nativeBuildInputs = [ cmake clang ];
  buildInputs = [ openssl protobuf sqlite rust-jemalloc-sys ];

  buildNoDefaultFeatures = true;
  buildFeatures = [ "modern" "slasher-lmdb" ];

  # Needed to get openssl-sys to use pkg-config.
  OPENSSL_NO_VENDOR = 1;
  OPENSSL_LIB_DIR = "${lib.getLib openssl}/lib";
  OPENSSL_DIR = "${lib.getDev openssl}";

  # Needed to get prost-build to use protobuf
  PROTOC = "${protobuf}/bin/protoc";

  # Needed by libmdx
  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

  # common crate tries to fetch the compiled version from an URL
  # see: https://github.com/sigp/lighthouse/blob/stable/common/deposit_contract/build.rs#L30
  LIGHTHOUSE_DEPOSIT_CONTRACT_SPEC_URL = "file:${slasherContractSrc}";

  # common crate tries to fetch the compiled version from an URL
  # see: https://github.com/sigp/lighthouse/blob/stable/common/deposit_contract/build.rs#L33
  LIGHTHOUSE_DEPOSIT_CONTRACT_TESTNET_URL = "file:${slasherContractTestnetSrc}";

  # This is needed by the unit tests.
  FORK_NAME = "pectra";

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
    "--exclude lighthouse_metrics"
    "--exclude invalid_attestation_delayed_slot"
    "--exclude can_read_finalized_block"
    "--exclude invalid_attestation_future_block"
    "--exclude invalid_attestation_empty_bitfield"
    "--exclude invalid_attestation_inconsistent_ffg_vote"
    "--exclude invalid_attestation_past_epoch"
    "--exclude invalid_attestation_future_epoch"
    "--exclude invalid_attestation_target_epoch"
    "--exclude invalid_block_finalized_slot"
    "--exclude invalid_block_finalized_descendant"
    "--exclude invalid_attestation_unknown_target_root"
    "--exclude invalid_attestation_unknown_beacon_block_root"
    "--exclude invalid_block_unknown_parent"
    "--exclude justified_balances"
    "--exclude justified_and_finalized_blocks"
    "--exclude invalid_block_future_slot"
    "--exclude progressive_balances_cache_attester_slashing"
    "--exclude justified_checkpoint_updates_with_descendent_first_justification"
    "--exclude justified_checkpoint_updates_with_descendent"
    "--exclude justified_checkpoint_updates_with_non_descendent"
    "--exclude valid_attestation"
    "--exclude valid_attestation_skip_across_epoch"
    "--exclude weak_subjectivity_check_epoch_boundary_is_skip_slot"
    "--exclude progressive_balances_cache_proposer_slashing"
    "--exclude weak_subjectivity_check_fails_late_epoch"
    "--exclude weak_subjectivity_check_fails_early_epoch"
    "--exclude weak_subjectivity_check_fails_incorrect_root"
    "--exclude weak_subjectivity_check_epoch_boundary_is_skip_slot_failure"
    "--exclude weak_subjectivity_check_passes"
    "--exclude weak_subjectivity_fail_on_startup"
    "--exclude weak_subjectivity_pass_on_startup"
  ];

  nativeCheckInputs = [
    postgresql
    foundry
  ];

  checkFeatures = [ ];

  # All of these tests require network access
  checkFlags = [
    "--skip service::tests::tests::test_dht_persistence"
    "--skip time::test::test_reinsertion_updates_timeout"
    "--skip tests::broadcast_should_send_to_all_bns"
    "--skip tests::check_candidate_order"
    "--skip tests::first_success_should_try_nodes_in_order"
    "--skip tests::update_all_candidates_should_update_sync_status"
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
  ];

  meta = {
    description = "Ethereum consensus client in Rust";
    homepage = "https://github.com/sigp/lighthouse";
    mainProgram = "lighthouse";
    platforms = [ "x86_64-linux" ];
  };
}
