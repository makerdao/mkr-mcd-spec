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

    function vat_file(bytes32 what, uint256 data) external {
        vat.file(what, data);
    }

    function vat_file(bytes32 what, bytes32 ilk, uint256 data) external {
        vat.file(ilk, what, data);
    }

    function vat_hope(address usr) external {
        vat.hope(usr);
    }

    function vat_move(address src, address dst, uint256 rad) external {
        vat.move(src, dst, rad);
    }

    function vat_rely(address usr) external {
        vat.rely(usr);
    }

    function vat_frob(bytes32 ilk, address u, address v, address w, int256 dink, int256 dart) external {
        vat.frob(ilk, u, v, w, dink, dart);
    }

    function vat_init(bytes32 ilk) external {
        vat.init(ilk);
    }

    function vow_file(bytes32 what, uint256 data) external {
        vow.file(what, data);
    }

    function vow_rely(address usr) external {
        vow.rely(usr);
    }

    function cat_rely(address usr) external {
        cat.rely(usr);
    }

    function pot_file(bytes32 what, uint256 data) external {
        pot.file(what, data);
    }

    function pot_file(bytes32 what, address data) external {
        pot.file(what, data);
    }

    function pot_rely(address usr) external {
        pot.rely(usr);
    }

    function pot_drip() external {
        pot.drip();
    }

    function pot_join(uint wad) external {
        pot.join(wad);
    }

    function pot_exit(uint wad) external {
        pot.exit(wad);
    }

    function flap_rely(address usr) external {
        flap.rely(usr);
    }

    function flop_rely(address usr) external {
        flop.rely(usr);
    }

    function flop_file(bytes32 what, uint data) external {
        flop.file(what, data);
    }

    function spotter_setPrice(bytes32 ilk, uint256 price) external {
        if (ilk == "gold") {
            pipGold.poke(bytes32(price));
        }
        spotter.poke(ilk);
    }

    function spotter_file(bytes32 what, bytes32 ilk, uint256 data) external {
        spotter.file(ilk, what, data);
    }

    function spotter_file(bytes32 what, uint256 data) external {
        spotter.file(what, data);
    }

    function end_cage() external {
        end.cage();
    }

    function end_cage(bytes32 ilk) external {
        end.cage(ilk);
    }

    function end_flow(bytes32 ilk) external {
        end.flow(ilk);
    }

    function end_thaw() external {
        end.thaw();
    }

    function end_pack(uint256 wad) external {
        end.pack(wad);
    }

    function end_skim(bytes32 ilk, address urn) external {
        end.skim(ilk, urn);
    }

    function goldFlip_rely(address usr) external {
        goldFlip.rely(usr);
    }

    function Gem_MKR_mint(address usr, uint256 wad) external {
        gov.mint(usr, wad);
    }

    function Gem_gold_mint(address usr, uint256 wad) external {
        gold.mint(usr, wad);
    }

    function goldJoin_join(address usr, uint256 wad) external {
        goldJoin.join(usr, wad);
    }

    function Gem_gold_approve(address usr) external {
        gold.approve(usr);
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

        admin.vat_init("gold");
        admin.vat_rely(address(goldJoin));
        admin.spotter_file("par", 1000000000000000000000000000);
        admin.spotter_file("mat", "gold", 1000000000000000000000000000);
        admin.spotter_setPrice("gold", 3000000000000000000000000000);
        admin.goldFlip_rely(address(end));
        admin.vat_file("Line", 1000000000000);
        admin.vat_file("spot", "gold", 3000000000);
        admin.vat_file("line", "gold", 1000000000000);
        admin.vow_file("bump", 1000000000);
        admin.vow_file("hump", 0);

        alice.Gem_gold_approve(address(goldJoin));
        bobby.Gem_gold_approve(address(goldJoin));
    }
}
