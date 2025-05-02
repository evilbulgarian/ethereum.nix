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

  OPENSSL_NO_VENDOR = true;

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
  ];

  meta = {
    description = "Ethereum consensus client in Rust";
    homepage = "https://github.com/sigp/lighthouse";
    mainProgram = "lighthouse";
    platforms = [ "x86_64-linux" ];
  };
}
