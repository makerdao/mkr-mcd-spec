pragma solidity ^0.5.12;

import {
    DssDeployTestBase,
    Vat,
    Vow,
    Cat,
    Pot,
    Flapper,
    Flopper,
    Spotter,
    End,
    DSToken,
    DSValue,
    GemJoin,
    Flipper
} from "dss-deploy/DssDeploy.t.base.sol";

contract UserLike {
    Vat vat;
    Vow vow;
    Cat cat;
    Pot pot;
    Flapper flap;
    Flopper flop;
    Spotter spotter;
    End end;
    DSToken gov;
    DSToken gold;
    DSValue pipGold;
    GemJoin goldJoin;
    Flipper goldFlip;

    constructor(
        Vat vat_,
        Vow vow_,
        Cat cat_,
        Pot pot_,
        Flapper flap_,
        Flopper flop_,
        Spotter spotter_,
        End end_,
        DSToken gov_,
        DSToken gold_,
        DSValue pipGold_,
        GemJoin goldJoin_,
        Flipper goldFlip_
    ) public {
        vat = vat_;
        vow = vow_;
        cat = cat_;
        pot = pot_;
        flap = flap_;
        flop = flop_;
        spotter = spotter_;
        end = end_;
        gov = gov_;
        gold = gold_;
        pipGold = pipGold_;
        goldJoin = goldJoin_;
        goldFlip = goldFlip_;
    }

    function vat_file(bytes32 what, uint256 data) external returns (bool ok) {
        (ok,) = address(vat).call(abi.encodeWithSignature("file(bytes32,uint256)", what, data));
    }

    function vat_file(bytes32 what, bytes32 ilk, uint256 data) external returns (bool ok) {
        (ok,) = address(vat).call(abi.encodeWithSignature("file(bytes32,bytes32,uint256)", ilk, what, data));
    }

    function vat_hope(address usr) external returns (bool ok) {
        (ok,) = address(vat).call(abi.encodeWithSignature("hope(address)", usr));
    }

    function vat_move(address src, address dst, uint256 rad) external returns (bool ok) {
        (ok,) = address(vat).call(abi.encodeWithSignature("move(address,address,uint256)", src, dst, rad));
    }

    function vat_rely(address usr) external returns (bool ok) {
        (ok,) = address(vat).call(abi.encodeWithSignature("rely(address)", usr));
    }

    function vat_frob(bytes32 ilk, address u, address v, address w, int256 dink, int256 dart) external returns (bool ok) {
        (ok,) = address(vat).call(abi.encodeWithSignature("frob(bytes32,address,address,address,int256,int256)", ilk, u, v, w, dink, dart));
    }

    function vat_init(bytes32 ilk) external returns (bool ok) {
        (ok,) = address(vat).call(abi.encodeWithSignature("init(bytes32)", ilk));
    }

    function vow_file(bytes32 what, uint256 data) external returns (bool ok) {
        (ok,) = address(vow).call(abi.encodeWithSignature("file(bytes32,uint256)", what, data));
    }

    function vow_rely(address usr) external returns (bool ok) {
        (ok,) = address(vow).call(abi.encodeWithSignature("rely(address)", usr));
    }

    function cat_rely(address usr) external returns (bool ok) {
        (ok,) = address(cat).call(abi.encodeWithSignature("rely(address)", usr));
    }

    function pot_file(bytes32 what, uint256 data) external returns (bool ok) {
        (ok,) = address(pot).call(abi.encodeWithSignature("file(bytes32,uint256)", what, data));
    }

    function pot_file(bytes32 what, address data) external returns (bool ok) {
        (ok,) = address(pot).call(abi.encodeWithSignature("file(bytes32,address)", what, data));
    }

    function pot_rely(address usr) external returns (bool ok) {
        (ok,) = address(pot).call(abi.encodeWithSignature("rely(address)", usr));
    }

    function pot_drip() external returns (bool ok) {
        (ok,) = address(pot).call(abi.encodeWithSignature("drip()"));
    }

    function pot_join(uint256 wad) external returns (bool ok) {
        (ok,) = address(pot).call(abi.encodeWithSignature("join(uint256)", wad));
    }

    function pot_exit(uint256 wad) external returns (bool ok) {
        (ok,) = address(pot).call(abi.encodeWithSignature("exit(uint256)", wad));
    }

    function flap_rely(address usr) external returns (bool ok) {
        (ok,) = address(flap).call(abi.encodeWithSignature("rely(address)", usr));
    }

    function flop_rely(address usr) external returns (bool ok) {
        (ok,) = address(flop).call(abi.encodeWithSignature("rely(address)", usr));
    }

    function flop_file(bytes32 what, uint256 data) external returns (bool ok) {
        (ok,) = address(flop).call(abi.encodeWithSignature("file(bytes32,uint256)", what, data));
    }

    function spotter_setPrice(bytes32 ilk, uint256 price) external returns (bool ok) {
        if (ilk == "gold") {
            (ok,) = address(pipGold).call(abi.encodeWithSignature("poke(bytes32)", bytes32(price)));
            if (!ok) return false;
        }
        (ok,) = address(spotter).call(abi.encodeWithSignature("poke(bytes32)", ilk));
    }

    function spotter_file(bytes32 what, bytes32 ilk, uint256 data) external returns (bool ok) {
        (ok,) = address(spotter).call(abi.encodeWithSignature("file(bytes32,bytes32,uint256)", ilk, what, data));
    }

    function spotter_file(bytes32 what, uint256 data) external returns (bool ok) {
        (ok,) = address(spotter).call(abi.encodeWithSignature("file(bytes32,uint256)", what, data));
    }

    function end_cage() external returns (bool ok) {
        (ok,) = address(end).call(abi.encodeWithSignature("cage()"));
    }

    function end_cage(bytes32 ilk) external returns (bool ok) {
        (ok,) = address(end).call(abi.encodeWithSignature("cage(bytes32)", ilk));
    }

    function end_flow(bytes32 ilk) external returns (bool ok) {
        (ok,) = address(end).call(abi.encodeWithSignature("flow(bytes32)", ilk));
    }

    function end_thaw() external returns (bool ok) {
        (ok,) = address(end).call(abi.encodeWithSignature("thaw()"));
    }

    function end_pack(uint256 wad) external returns (bool ok) {
        (ok,) = address(end).call(abi.encodeWithSignature("pack(uint256)", wad));
    }

    function end_skim(bytes32 ilk, address urn) external returns (bool ok) {
        (ok,) = address(end).call(abi.encodeWithSignature("skim(bytes32,address)", ilk, urn));
    }

    function goldFlip_rely(address usr) external returns (bool ok) {
        (ok,) = address(goldFlip).call(abi.encodeWithSignature("rely(address)", usr));
    }

    function Gem_MKR_mint(address usr, uint256 wad) external returns (bool ok) {
        (ok,) = address(gov).call(abi.encodeWithSignature("mint(address,uint256)", usr, wad));
    }

    function Gem_gold_mint(address usr, uint256 wad) external returns (bool ok) {
        (ok,) = address(gold).call(abi.encodeWithSignature("mint(address,uint256)", usr, wad));
    }

    function goldJoin_join(address usr, uint256 wad) external returns (bool ok) {
        (ok,) = address(goldJoin).call(abi.encodeWithSignature("join(address,uint256)", usr, wad));
    }

    function Gem_gold_approve(address usr) external returns (bool ok) {
        (ok,) = address(gold).call(abi.encodeWithSignature("approve(address)", usr));
    }
}

contract MkrMcdSpecSolTestsTest is DssDeployTestBase {
    DSToken gold;
    DSValue pipGold;
    GemJoin goldJoin;
    Flipper goldFlip;
    UserLike alice;
    UserLike bobby;
    UserLike admin;
    UserLike anyone;

    function rely(address who, address to) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("rely(address,address)", who, to);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function file(address who, bytes32 ilk, bytes32 what, address data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("file(address,bytes32,bytes32,address)", who, ilk, what, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function warpForward(uint256 time) external {
        hevm.warp(now + time);
    }

    function assertTrue(bool condition, bytes32 message) internal {
        if (!condition) {
            emit log_bytes32(message);
            fail();
        }
    }

    function setUp() public {
        super.setUp();
        deploy();

        // Create gold contracts
        gold = new DSToken("gold");
        pipGold = new DSValue();
        goldJoin = new GemJoin(address(vat), "gold", address(gold));
        goldFlip = flipFab.newFlip(address(vat), "gold");
        this.file(address(spotter), "gold", "pip", address(pipGold));

        // Create users
        alice = new UserLike(vat, vow, cat, pot, flap, flop, spotter, end, gov, gold, pipGold, goldJoin, goldFlip);
        bobby = new UserLike(vat, vow, cat, pot, flap, flop, spotter, end, gov, gold, pipGold, goldJoin, goldFlip);
        admin = new UserLike(vat, vow, cat, pot, flap, flop, spotter, end, gov, gold, pipGold, goldJoin, goldFlip);
        anyone = new UserLike(vat, vow, cat, pot, flap, flop, spotter, end, gov, gold, pipGold, goldJoin, goldFlip);

        // Give full rights to admin
        this.rely(address(vat), address(admin));
        this.rely(address(vow), address(admin));
        this.rely(address(cat), address(admin));
        this.rely(address(pot), address(admin));
        this.rely(address(flap), address(admin));
        this.rely(address(flop), address(admin));
        this.rely(address(spotter), address(admin));
        this.rely(address(end), address(admin));
        goldJoin.rely(address(admin));
        goldFlip.rely(address(admin));
        gov.setOwner(address(admin));
        gold.setOwner(address(admin));
        pipGold.setOwner(address(admin));

        assertTrue(admin.vat_init("gold"), "errorX");
        assertTrue(admin.vat_rely(address(goldJoin)), "errorX");
        assertTrue(admin.spotter_file("par", 1000000000000000000000000000), "errorX");
        assertTrue(admin.spotter_file("mat", "gold", 1000000000000000000000000000), "errorX");
        assertTrue(admin.spotter_setPrice("gold", 3000000000000000000000000000), "errorX");
        assertTrue(admin.goldFlip_rely(address(end)), "errorX");
        assertTrue(admin.vat_file("Line", 1000000000000), "errorX");
        assertTrue(admin.vat_file("spot", "gold", 3000000000), "errorX");
        assertTrue(admin.vat_file("line", "gold", 1000000000000), "errorX");
        assertTrue(admin.vow_file("bump", 1000000000), "errorX");
        assertTrue(admin.vow_file("hump", 0), "errorX");

        assertTrue(alice.Gem_gold_approve(address(goldJoin)), "errorX");
        assertTrue(bobby.Gem_gold_approve(address(goldJoin)), "errorX");
    }
}
