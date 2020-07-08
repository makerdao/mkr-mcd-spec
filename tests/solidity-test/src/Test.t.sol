pragma solidity ^0.5.12;

import "./MkrMcdSpecSolTests.t.sol";

contract TestExample is MkrMcdSpecSolTestsTest {


    function test0() public {

        // Test Run
    
        admin.vat_rely(address(pot));
        admin.vat_rely(address(end));
        admin.vat_rely(address(spotter));
        admin.pot_rely(address(end));
        admin.vow_rely(address(pot));
        admin.vow_rely(address(end));
        admin.cat_rely(address(end));
        admin.flap_rely(address(vow));
        admin.flop_rely(address(vow));
        admin.pot_file("vow", address(vow));
        // vow.vat_hope(address(flap));
        admin.vat_file("Line", 1000000000000000000000000000000000000000000000000000000000);
        admin.vow_file("bump", 1000000000000000000000000000000000000000000000000000000);
        admin.vow_file("hump", 0);
        admin.vow_file("sump", 50000000000000000000000000000000000000000000000);
        admin.vow_file("dump", 30000000000000000000);
        admin.flop_file("tau", 3600);
        admin.vat_rely(address(goldJoin));
        admin.spotter_setPrice("gold", 3000000000000000000000000000);
        admin.spotter_file("mat", "gold", 1000000000000000000000000000);
        admin.spotter_file("par", 1000000000000000000000000000);
        admin.goldFlip_rely(address(end));
        admin.vat_file("line", "gold", 1000000000000000000000000000000000000000000000000000000000);
        // UNIMPLEMENTED << assertEvent( Poke( "gold" , FInt( 3000000000000000000000000000 , 1000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) )); >>
        admin.Gem_gold_mint(address(alice), 20000000000000000000);
        admin.Gem_gold_mint(address(bobby), 20000000000000000000);
        alice.vat_hope(address(pot));
        alice.vat_hope(address(goldFlip));
        alice.vat_hope(address(end));
        alice.vat_hope(address(flop));
        bobby.vat_hope(address(pot));
        bobby.vat_hope(address(goldFlip));
        bobby.vat_hope(address(end));
        bobby.vat_hope(address(flop));
        alice.goldJoin_join(address(alice), 10000000000000000000);
        bobby.goldJoin_join(address(bobby), 10000000000000000000);
        alice.vat_frob("gold", address(alice), address(alice), address(alice), 10000000000000000000, 10000000000000000000);
        bobby.vat_frob("gold", address(bobby), address(bobby), address(bobby), 10000000000000000000, 10000000000000000000);
        admin.pot_file("dsr", 1000000000000000000000000000);
        // anyone.end_pack(0);
        admin.end_cage();
        anyone.end_cage("gold");
        anyone.end_skim("gold", address(end));
        alice.goldJoin_join(address(alice), 3000000000000000000);
        // flap.vat_hope(address(alice));
        hevm.warp(1);
        anyone.end_skim("gold", address(bobby));
        anyone.end_thaw();
        anyone.pot_drip();
        anyone.end_flow("gold");
        alice.pot_join(4000000000000000000);
        alice.pot_exit(4000000000000000000);
        hevm.warp(2);
        hevm.warp(2);
        anyone.pot_drip();
        bobby.pot_exit(0);
    
        // Assertions
    
        assertTrue( cat.live() == 0 );
        assertTrue( end.live() == 0 );
        assertTrue( end.debt() == 20000000000000000000000000000000000000000000000 );
        // UNIMPLEMENTED << assertTrue( end.tag() == "gold" |-> FInt( 333333333333333333 , 1000000000000000000000000000 ) ); >>
        // UNIMPLEMENTED << assertTrue( end.art() == "gold" |-> FInt( 20000000000000000000 , 1000000000000000000 ) ); >>
        // UNIMPLEMENTED << assertTrue( end.fix() == "gold" |-> FInt( 0 , 1000000000000000000000000000 ) ); >>
        assertTrue( flap.live() == 0 );
        assertTrue( flop.live() == 0 );
        // UNIMPLEMENTED << assertTrue( Gems.cell() == GemCellMapItem( <gem-id>
        //  "gold"
        //</gem-id> , <gem>
        //  <gem-id>
        //    "gold"
        //  </gem-id>
        //  <gem-wards>
        //    .Set
        //  </gem-wards>
        //  <gem-balances>
        //    "bobby" |-> FInt( 10000000000000000000 , 1000000000000000000 )
        //    GemJoin "gold" |-> FInt( 23000000000000000000 , 1000000000000000000 )
        //    "alice" |-> FInt( 7000000000000000000 , 1000000000000000000 )
        //  </gem-balances>
        //</gem> ) GemCellMapItem( <gem-id>
        //  "MKR"
        //</gem-id> , <gem>
        //  <gem-id>
        //    "MKR"
        //  </gem-id>
        //  <gem-wards>
        //    .Set
        //  </gem-wards>
        //  <gem-balances>
        //    flap |-> FInt( 0 , 1000000000000000000 )
        //    GemJoin "MKR" |-> FInt( 0 , 1000000000000000000 )
        //    "bobby" |-> FInt( 0 , 1000000000000000000 )
        //    "alice" |-> FInt( 0 , 1000000000000000000 )
        //    vow |-> FInt( 0 , 1000000000000000000 )
        //  </gem-balances>
        //</gem> ) ); >>
        // assertTrue( pot.chi() == 1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 );
        // UNIMPLEMENTED << assertTrue( pot.rho() == 5 ); >>
        assertTrue( pot.live() == 0 );
        // UNIMPLEMENTED << assertTrue( vat.can(address(flap)) == SetItem( "alice" ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.can(address(pot)) == .Set ); >>
        // UNIMPLEMENTED << assertTrue( vat.can(address(end)) == .Set ); >>
        assertTrue( vat.can(address(bobby), address(pot)) != 0 );
        assertTrue( vat.can(address(bobby), address(flop)) != 0 );
        assertTrue( vat.can(address(bobby), address(goldFlip)) != 0 );
        assertTrue( vat.can(address(bobby), address(end)) != 0 );
        assertTrue( vat.can(address(alice), address(pot)) != 0 );
        assertTrue( vat.can(address(alice), address(flop)) != 0 );
        assertTrue( vat.can(address(alice), address(goldFlip)) != 0 );
        assertTrue( vat.can(address(alice), address(end)) != 0 );
        // UNIMPLEMENTED << assertTrue( vat.can(address(vow)) == SetItem( flap ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.ilks() == "gold" |-> Ilk( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 1000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 1000000000000000000000000000000000000000000000000000000000 , 1000000000000000000000000000000000000000000000 ) , FInt( 0 , 1000000000000000000000000000000000000000000000 ) ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(end)) == Urn( FInt( 0 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(alice)) == Urn( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 10000000000000000000 , 1000000000000000000 ) ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(bobby)) == Urn( FInt( 9999999996666666667 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
        assertTrue( vat.gem("gold", address(end)) == 3333333333 );
        assertTrue( vat.gem("gold", address(alice)) == 3000000000000000000 );
        assertTrue( vat.gem("gold", address(goldFlip)) == 0 );
        assertTrue( vat.gem("gold", address(bobby)) == 0 );
        assertTrue( vat.sin(address(flap)) == 0 );
        assertTrue( vat.sin(address(pot)) == 0 );
        assertTrue( vat.sin(address(end)) == 0 );
        assertTrue( vat.sin(address(bobby)) == 0 );
        assertTrue( vat.sin(address(alice)) == 0 );
        assertTrue( vat.sin(address(vow)) == 10000000000000000000000000000000000000000000000 );
        assertTrue( vat.vice() == 10000000000000000000000000000000000000000000000 );
        assertTrue( vat.live() == 0 );
        assertTrue( vow.live() == 0 );
    
    }
    
    function test1() public {
    
        // Test Run
    
        admin.vat_rely(address(pot));
        admin.vat_rely(address(end));
        admin.vat_rely(address(spotter));
        admin.pot_rely(address(end));
        admin.vow_rely(address(pot));
        admin.vow_rely(address(end));
        admin.cat_rely(address(end));
        admin.flap_rely(address(vow));
        admin.flop_rely(address(vow));
        admin.pot_file("vow", address(vow));
        // vow.vat_hope(address(flap));
        admin.vat_file("Line", 1000000000000000000000000000000000000000000000000000000000);
        admin.vow_file("bump", 1000000000000000000000000000000000000000000000000000000);
        admin.vow_file("hump", 0);
        admin.vow_file("sump", 50000000000000000000000000000000000000000000000);
        admin.vow_file("dump", 30000000000000000000);
        admin.flop_file("tau", 3600);
        admin.vat_rely(address(goldJoin));
        admin.spotter_setPrice("gold", 3000000000000000000000000000);
        admin.spotter_file("mat", "gold", 1000000000000000000000000000);
        admin.spotter_file("par", 1000000000000000000000000000);
        admin.goldFlip_rely(address(end));
        admin.vat_file("line", "gold", 1000000000000000000000000000000000000000000000000000000000);
        // UNIMPLEMENTED << assertEvent( Poke( "gold" , FInt( 3000000000000000000000000000 , 1000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) )); >>
        admin.Gem_gold_mint(address(alice), 20000000000000000000);
        admin.Gem_gold_mint(address(bobby), 20000000000000000000);
        alice.vat_hope(address(pot));
        alice.vat_hope(address(goldFlip));
        alice.vat_hope(address(end));
        alice.vat_hope(address(flop));
        bobby.vat_hope(address(pot));
        bobby.vat_hope(address(goldFlip));
        bobby.vat_hope(address(end));
        bobby.vat_hope(address(flop));
        alice.goldJoin_join(address(alice), 10000000000000000000);
        bobby.goldJoin_join(address(bobby), 10000000000000000000);
        alice.vat_frob("gold", address(alice), address(alice), address(alice), 10000000000000000000, 10000000000000000000);
        bobby.vat_frob("gold", address(bobby), address(bobby), address(bobby), 10000000000000000000, 10000000000000000000);
        // end.vat_move(address(end), address(bobby), 0);
        admin.end_cage();
        hevm.warp(2);
        anyone.pot_drip();
        anyone.end_cage("gold");
        bobby.pot_exit(0);
        anyone.end_skim("gold", address(bobby));
        anyone.end_skim("gold", address(bobby));
        anyone.end_thaw();
        anyone.end_flow("gold");
        hevm.warp(2);
        // flap.vat_hope(address(vow));
        hevm.warp(2);
        anyone.pot_drip();
        alice.pot_exit(0);
    
        // Assertions
    
        assertTrue( cat.live() == 0 );
        assertTrue( end.live() == 0 );
        assertTrue( end.debt() == 20000000000000000000000000000000000000000000000 );
        // UNIMPLEMENTED << assertTrue( end.tag() == "gold" |-> FInt( 333333333333333333 , 1000000000000000000000000000 ) ); >>
        // UNIMPLEMENTED << assertTrue( end.art() == "gold" |-> FInt( 20000000000000000000 , 1000000000000000000 ) ); >>
        // UNIMPLEMENTED << assertTrue( end.fix() == "gold" |-> FInt( 0 , 1000000000000000000000000000 ) ); >>
        assertTrue( flap.live() == 0 );
        assertTrue( flop.live() == 0 );
        // assertTrue( pot.chi() == 1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 );
        // UNIMPLEMENTED << assertTrue( pot.rho() == 6 ); >>
        assertTrue( pot.live() == 0 );
        // UNIMPLEMENTED << assertTrue( vat.can(address(flap)) == SetItem( vow ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.can(address(pot)) == .Set ); >>
        // UNIMPLEMENTED << assertTrue( vat.can(address(end)) == .Set ); >>
        assertTrue( vat.can(address(bobby), address(pot)) != 0 );
        assertTrue( vat.can(address(bobby), address(flop)) != 0 );
        assertTrue( vat.can(address(bobby), address(goldFlip)) != 0 );
        assertTrue( vat.can(address(bobby), address(end)) != 0 );
        assertTrue( vat.can(address(alice), address(pot)) != 0 );
        assertTrue( vat.can(address(alice), address(flop)) != 0 );
        assertTrue( vat.can(address(alice), address(goldFlip)) != 0 );
        assertTrue( vat.can(address(alice), address(end)) != 0 );
        // UNIMPLEMENTED << assertTrue( vat.can(address(vow)) == SetItem( flap ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.ilks() == "gold" |-> Ilk( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 1000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 1000000000000000000000000000000000000000000000000000000000 , 1000000000000000000000000000000000000000000000 ) , FInt( 0 , 1000000000000000000000000000000000000000000000 ) ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(end)) == Urn( FInt( 0 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(alice)) == Urn( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 10000000000000000000 , 1000000000000000000 ) ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(bobby)) == Urn( FInt( 9999999996666666667 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
        assertTrue( vat.gem("gold", address(end)) == 3333333333 );
        assertTrue( vat.gem("gold", address(alice)) == 0 );
        assertTrue( vat.gem("gold", address(goldFlip)) == 0 );
        assertTrue( vat.gem("gold", address(bobby)) == 0 );
        assertTrue( vat.sin(address(flap)) == 0 );
        assertTrue( vat.sin(address(pot)) == 0 );
        assertTrue( vat.sin(address(end)) == 0 );
        assertTrue( vat.sin(address(bobby)) == 0 );
        assertTrue( vat.sin(address(alice)) == 0 );
        assertTrue( vat.sin(address(vow)) == 10000000000000000000000000000000000000000000000 );
        assertTrue( vat.vice() == 10000000000000000000000000000000000000000000000 );
        assertTrue( vat.live() == 0 );
        assertTrue( vow.live() == 0 );
    
    }
    
    function test2() public {
    
        // Test Run
    
        admin.vat_rely(address(pot));
        admin.vat_rely(address(end));
        admin.vat_rely(address(spotter));
        admin.pot_rely(address(end));
        admin.vow_rely(address(pot));
        admin.vow_rely(address(end));
        admin.cat_rely(address(end));
        admin.flap_rely(address(vow));
        admin.flop_rely(address(vow));
        admin.pot_file("vow", address(vow));
        // vow.vat_hope(address(flap));
        admin.vat_file("Line", 1000000000000000000000000000000000000000000000000000000000);
        admin.vow_file("bump", 1000000000000000000000000000000000000000000000000000000);
        admin.vow_file("hump", 0);
        admin.vow_file("sump", 50000000000000000000000000000000000000000000000);
        admin.vow_file("dump", 30000000000000000000);
        admin.flop_file("tau", 3600);
        admin.vat_rely(address(goldJoin));
        admin.spotter_setPrice("gold", 3000000000000000000000000000);
        admin.spotter_file("mat", "gold", 1000000000000000000000000000);
        admin.spotter_file("par", 1000000000000000000000000000);
        admin.goldFlip_rely(address(end));
        admin.vat_file("line", "gold", 1000000000000000000000000000000000000000000000000000000000);
        // UNIMPLEMENTED << assertEvent( Poke( "gold" , FInt( 3000000000000000000000000000 , 1000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) )); >>
        admin.Gem_gold_mint(address(alice), 20000000000000000000);
        admin.Gem_gold_mint(address(bobby), 20000000000000000000);
        alice.vat_hope(address(pot));
        alice.vat_hope(address(goldFlip));
        alice.vat_hope(address(end));
        alice.vat_hope(address(flop));
        bobby.vat_hope(address(pot));
        bobby.vat_hope(address(goldFlip));
        bobby.vat_hope(address(end));
        bobby.vat_hope(address(flop));
        alice.goldJoin_join(address(alice), 10000000000000000000);
        bobby.goldJoin_join(address(bobby), 10000000000000000000);
        alice.vat_frob("gold", address(alice), address(alice), address(alice), 10000000000000000000, 10000000000000000000);
        bobby.vat_frob("gold", address(bobby), address(bobby), address(bobby), 10000000000000000000, 10000000000000000000);
        // pot.vat_move(address(pot), address(end), 0);
        admin.pot_file("dsr", 1000000000000000000000000000);
        hevm.warp(1);
        alice.goldJoin_join(address(alice), 5000000000000000000);
        admin.end_cage();
        bobby.vat_hope(address(bobby));
        anyone.end_cage("gold");
        hevm.warp(2);
        anyone.end_thaw();
        anyone.pot_drip();
        anyone.end_flow("gold");
        alice.pot_exit(0);
        anyone.end_skim("gold", address(end));
        anyone.end_skim("gold", address(alice));
        bobby.pot_join(0);
        hevm.warp(1);
        anyone.pot_drip();
        alice.pot_exit(0);
    
        // Assertions
    
        assertTrue( cat.live() == 0 );
        assertTrue( end.live() == 0 );
        // UNIMPLEMENTED << assertTrue( end.when() == 1 ); >>
        assertTrue( end.debt() == 20000000000000000000000000000000000000000000000 );
        // UNIMPLEMENTED << assertTrue( end.tag() == "gold" |-> FInt( 333333333333333333 , 1000000000000000000000000000 ) ); >>
        // UNIMPLEMENTED << assertTrue( end.art() == "gold" |-> FInt( 20000000000000000000 , 1000000000000000000 ) ); >>
        // UNIMPLEMENTED << assertTrue( end.fix() == "gold" |-> FInt( 0 , 1000000000000000000000000000 ) ); >>
        assertTrue( flap.live() == 0 );
        assertTrue( flop.live() == 0 );
        // UNIMPLEMENTED << assertTrue( Gems.cell() == GemCellMapItem( <gem-id>
        //  "gold"
        //</gem-id> , <gem>
        //  <gem-id>
        //    "gold"
        //  </gem-id>
        //  <gem-wards>
        //    .Set
        //  </gem-wards>
        //  <gem-balances>
        //    "bobby" |-> FInt( 10000000000000000000 , 1000000000000000000 )
        //    GemJoin "gold" |-> FInt( 25000000000000000000 , 1000000000000000000 )
        //    "alice" |-> FInt( 5000000000000000000 , 1000000000000000000 )
        //  </gem-balances>
        //</gem> ) GemCellMapItem( <gem-id>
        //  "MKR"
        //</gem-id> , <gem>
        //  <gem-id>
        //    "MKR"
        //  </gem-id>
        //  <gem-wards>
        //    .Set
        //  </gem-wards>
        //  <gem-balances>
        //    flap |-> FInt( 0 , 1000000000000000000 )
        //    GemJoin "MKR" |-> FInt( 0 , 1000000000000000000 )
        //    "bobby" |-> FInt( 0 , 1000000000000000000 )
        //    "alice" |-> FInt( 0 , 1000000000000000000 )
        //    vow |-> FInt( 0 , 1000000000000000000 )
        //  </gem-balances>
        //</gem> ) ); >>
        // assertTrue( pot.chi() == 1000000000000000000000000000000000000000000000000000000000000000000000000000000000 );
        // UNIMPLEMENTED << assertTrue( pot.rho() == 4 ); >>
        assertTrue( pot.live() == 0 );
        // UNIMPLEMENTED << assertTrue( vat.can(address(flap)) == .Set ); >>
        // UNIMPLEMENTED << assertTrue( vat.can(address(pot)) == .Set ); >>
        // UNIMPLEMENTED << assertTrue( vat.can(address(end)) == .Set ); >>
        assertTrue( vat.can(address(bobby), address(pot)) != 0 );
        assertTrue( vat.can(address(bobby), address(bobby)) != 0 );
        assertTrue( vat.can(address(bobby), address(flop)) != 0 );
        assertTrue( vat.can(address(bobby), address(goldFlip)) != 0 );
        assertTrue( vat.can(address(bobby), address(end)) != 0 );
        assertTrue( vat.can(address(alice), address(pot)) != 0 );
        assertTrue( vat.can(address(alice), address(flop)) != 0 );
        assertTrue( vat.can(address(alice), address(goldFlip)) != 0 );
        assertTrue( vat.can(address(alice), address(end)) != 0 );
        // UNIMPLEMENTED << assertTrue( vat.can(address(vow)) == SetItem( flap ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.ilks() == "gold" |-> Ilk( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 1000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 1000000000000000000000000000000000000000000000000000000000 , 1000000000000000000000000000000000000000000000 ) , FInt( 0 , 1000000000000000000000000000000000000000000000 ) ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(end)) == Urn( FInt( 0 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(alice)) == Urn( FInt( 9999999996666666667 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
        // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(bobby)) == Urn( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 10000000000000000000 , 1000000000000000000 ) ) ); >>
        assertTrue( vat.gem("gold", address(end)) == 3333333333 );
        assertTrue( vat.gem("gold", address(alice)) == 5000000000000000000 );
        assertTrue( vat.gem("gold", address(goldFlip)) == 0 );
        assertTrue( vat.gem("gold", address(bobby)) == 0 );
        assertTrue( vat.sin(address(flap)) == 0 );
        assertTrue( vat.sin(address(pot)) == 0 );
        assertTrue( vat.sin(address(end)) == 0 );
        assertTrue( vat.sin(address(bobby)) == 0 );
        assertTrue( vat.sin(address(alice)) == 0 );
        assertTrue( vat.sin(address(vow)) == 10000000000000000000000000000000000000000000000 );
        assertTrue( vat.vice() == 10000000000000000000000000000000000000000000000 );
        assertTrue( vat.live() == 0 );
        assertTrue( vow.live() == 0 );
    
    }
    
//     function test3() public {
    
//         // Test Run
    
//         admin.vat_rely(address(pot));
//         admin.vat_rely(address(end));
//         admin.vat_rely(address(spotter));
//         admin.pot_rely(address(end));
//         admin.vow_rely(address(pot));
//         admin.vow_rely(address(end));
//         admin.cat_rely(address(end));
//         admin.flap_rely(address(vow));
//         admin.flop_rely(address(vow));
//         admin.pot_file("vow", address(vow));
//         // vow.vat_hope(address(flap));
//         admin.vat_file("Line", 1000000000000000000000000000000000000000000000000000000000);
//         admin.vow_file("bump", 1000000000000000000000000000000000000000000000000000000);
//         admin.vow_file("hump", 0);
//         admin.vow_file("sump", 50000000000000000000000000000000000000000000000);
//         admin.vow_file("dump", 30000000000000000000);
//         admin.flop_file("tau", 3600);
//         admin.vat_rely(address(goldJoin));
//         admin.spotter_setPrice("gold", 3000000000000000000000000000);
//         admin.spotter_file("mat", "gold", 1000000000000000000000000000);
//         admin.spotter_file("par", 1000000000000000000000000000);
//         admin.goldFlip_rely(address(end));
//         admin.vat_file("Line", "gold", 1000000000000000000000000000000000000000000000000000000000);
//         // UNIMPLEMENTED << assertEvent( Poke( "gold" , FInt( 3000000000000000000000000000 , 1000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) )); >>
//         admin.Gem_gold_mint(address(alice), 20000000000000000000);
//         admin.Gem_gold_mint(address(bobby), 20000000000000000000);
//         alice.vat_hope(address(pot));
//         alice.vat_hope(address(goldFlip));
//         alice.vat_hope(address(end));
//         alice.vat_hope(address(flop));
//         bobby.vat_hope(address(pot));
//         bobby.vat_hope(address(goldFlip));
//         bobby.vat_hope(address(end));
//         bobby.vat_hope(address(flop));
//         alice.goldJoin_join(address(alice), 10000000000000000000);
//         bobby.goldJoin_join(address(bobby), 10000000000000000000);
//         alice.vat_frob("gold", address(alice), address(alice), address(alice), 10000000000000000000, 10000000000000000000);
//         bobby.vat_frob("gold", address(bobby), address(bobby), address(bobby), 10000000000000000000, 10000000000000000000);
//         admin.end_cage();
//         // vow.vat_move(address(vow), address(pot), 0);
//         hevm.warp(1);
//         // end.vat_hope(address(vow));
//         anyone.pot_drip();
//         anyone.end_cage("gold");
//         bobby.pot_exit(0);
//         anyone.end_skim("gold", address(end));
//         hevm.warp(2);
//         anyone.end_thaw();
//         anyone.end_skim("gold", address(bobby));
//         anyone.end_flow("gold");
//         hevm.warp(1);
//         anyone.pot_drip();
//         bobby.pot_exit(0);
    
//         // Assertions
    
//         assertTrue( cat.live() == 0 );
//         assertTrue( end.live() == 0 );
//         assertTrue( end.debt() == 20000000000000000000000000000000000000000000000 );
//         // UNIMPLEMENTED << assertTrue( end.tag() == "gold" |-> FInt( 333333333333333333 , 1000000000000000000000000000 ) ); >>
//         // UNIMPLEMENTED << assertTrue( end.art() == "gold" |-> FInt( 20000000000000000000 , 1000000000000000000 ) ); >>
//         // UNIMPLEMENTED << assertTrue( end.fix() == "gold" |-> FInt( 0 , 1000000000000000000000000000 ) ); >>
//         assertTrue( flap.live() == 0 );
//         assertTrue( flop.live() == 0 );
//         // assertTrue( pot.chi() == 1000000000000000000000000000000000000000000000000000000000000000000000000000000000 );
//         // UNIMPLEMENTED << assertTrue( pot.rho() == 4 ); >>
//         assertTrue( pot.live() == 0 );
//         // UNIMPLEMENTED << assertTrue( vat.can(address(flap)) == .Set ); >>
//         // UNIMPLEMENTED << assertTrue( vat.can(address(pot)) == .Set ); >>
//         // UNIMPLEMENTED << assertTrue( vat.can(address(end)) == SetItem( vow ) ); >>
//         assertTrue( vat.can(address(bobby), address(pot)) != 0 );
//         assertTrue( vat.can(address(bobby), address(flop)) != 0 );
//         assertTrue( vat.can(address(bobby), address(goldFlip)) != 0 );
//         assertTrue( vat.can(address(bobby), address(end)) != 0 );
//         assertTrue( vat.can(address(alice), address(pot)) != 0 );
//         assertTrue( vat.can(address(alice), address(flop)) != 0 );
//         assertTrue( vat.can(address(alice), address(goldFlip)) != 0 );
//         assertTrue( vat.can(address(alice), address(end)) != 0 );
//         // UNIMPLEMENTED << assertTrue( vat.can(address(vow)) == SetItem( flap ) ); >>
//         // UNIMPLEMENTED << assertTrue( vat.ilks() == "gold" |-> Ilk( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 1000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 1000000000000000000000000000000000000000000000000000000000 , 1000000000000000000000000000000000000000000000 ) , FInt( 0 , 1000000000000000000000000000000000000000000000 ) ) ); >>
//         // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(end)) == Urn( FInt( 0 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
//         // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(alice)) == Urn( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 10000000000000000000 , 1000000000000000000 ) ) ); >>
//         // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(bobby)) == Urn( FInt( 9999999996666666667 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
//         assertTrue( vat.gem("gold", address(end)) == 3333333333 );
//         assertTrue( vat.gem("gold", address(alice)) == 0 );
//         assertTrue( vat.gem("gold", address(goldFlip)) == 0 );
//         assertTrue( vat.gem("gold", address(bobby)) == 0 );
//         assertTrue( vat.sin(address(flap)) == 0 );
//         assertTrue( vat.sin(address(pot)) == 0 );
//         assertTrue( vat.sin(address(end)) == 0 );
//         assertTrue( vat.sin(address(bobby)) == 0 );
//         assertTrue( vat.sin(address(alice)) == 0 );
//         assertTrue( vat.sin(address(vow)) == 10000000000000000000000000000000000000000000000 );
//         assertTrue( vat.vice() == 10000000000000000000000000000000000000000000000 );
//         assertTrue( vat.live() == 0 );
//         assertTrue( vow.live() == 0 );
    
//     }
    
//     function test4() public {
    
//         // Test Run
    
//         admin.vat_rely(address(pot));
//         admin.vat_rely(address(end));
//         admin.vat_rely(address(spotter));
//         admin.pot_rely(address(end));
//         admin.vow_rely(address(pot));
//         admin.vow_rely(address(end));
//         admin.cat_rely(address(end));
//         admin.flap_rely(address(vow));
//         admin.flop_rely(address(vow));
//         admin.pot_file("vow", address(vow));
//         // vow.vat_hope(address(flap));
//         admin.vat_file("Line", 1000000000000000000000000000000000000000000000000000000000);
//         admin.vow_file("bump", 1000000000000000000000000000000000000000000000000000000);
//         admin.vow_file("hump", 0);
//         admin.vow_file("sump", 50000000000000000000000000000000000000000000000);
//         admin.vow_file("dump", 30000000000000000000);
//         admin.flop_file("tau", 3600);
//         admin.vat_rely(address(goldJoin));
//         admin.spotter_setPrice("gold", 3000000000000000000000000000);
//         admin.spotter_file("mat", "gold", 1000000000000000000000000000);
//         admin.spotter_file("par", 1000000000000000000000000000);
//         admin.goldFlip_rely(address(end));
//         admin.vat_file("Line", "gold", 1000000000000000000000000000000000000000000000000000000000);
//         // UNIMPLEMENTED << assertEvent( Poke( "gold" , FInt( 3000000000000000000000000000 , 1000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) )); >>
//         admin.Gem_gold_mint(address(alice), 20000000000000000000);
//         admin.Gem_gold_mint(address(bobby), 20000000000000000000);
//         alice.vat_hope(address(pot));
//         alice.vat_hope(address(goldFlip));
//         alice.vat_hope(address(end));
//         alice.vat_hope(address(flop));
//         bobby.vat_hope(address(pot));
//         bobby.vat_hope(address(goldFlip));
//         bobby.vat_hope(address(end));
//         bobby.vat_hope(address(flop));
//         alice.goldJoin_join(address(alice), 10000000000000000000);
//         bobby.goldJoin_join(address(bobby), 10000000000000000000);
//         alice.vat_frob("gold", address(alice), address(alice), address(alice), 10000000000000000000, 10000000000000000000);
//         bobby.vat_frob("gold", address(bobby), address(bobby), address(bobby), 10000000000000000000, 10000000000000000000);
//         admin.end_cage();
//         bobby.vat_move(address(bobby), address(alice), 3000000000000000000000000000000000000000000000);
//         alice.goldJoin_join(address(alice), 0);
//         anyone.end_cage("gold");
//         anyone.end_skim("gold", address(bobby));
//         // flap.vat_hope(address(alice));
//         hevm.warp(1);
//         anyone.pot_drip();
//         anyone.end_skim("gold", address(end));
//         hevm.warp(1);
//         bobby.pot_exit(0);
//         anyone.end_thaw();
//         anyone.end_flow("gold");
//         hevm.warp(2);
//         anyone.pot_drip();
//         bobby.pot_exit(0);
    
//         // Assertions
    
//         assertTrue( cat.live() == 0 );
//         assertTrue( end.live() == 0 );
//         assertTrue( end.debt() == 20000000000000000000000000000000000000000000000 );
//         // UNIMPLEMENTED << assertTrue( end.tag() == "gold" |-> FInt( 333333333333333333 , 1000000000000000000000000000 ) ); >>
//         // UNIMPLEMENTED << assertTrue( end.art() == "gold" |-> FInt( 20000000000000000000 , 1000000000000000000 ) ); >>
//         // UNIMPLEMENTED << assertTrue( end.fix() == "gold" |-> FInt( 0 , 1000000000000000000000000000 ) ); >>
//         assertTrue( flap.live() == 0 );
//         assertTrue( flop.live() == 0 );
//         // assertTrue( pot.chi() == 1000000000000000000000000000000000000000000000000000000000000000000000000000000000 );
//         // UNIMPLEMENTED << assertTrue( pot.rho() == 4 ); >>
//         assertTrue( pot.live() == 0 );
//         // UNIMPLEMENTED << assertTrue( vat.can(address(flap)) == SetItem( "alice" ) ); >>
//         // UNIMPLEMENTED << assertTrue( vat.can(address(pot)) == .Set ); >>
//         // UNIMPLEMENTED << assertTrue( vat.can(address(end)) == .Set ); >>
//         assertTrue( vat.can(address(bobby), address(pot)) != 0 );
//         assertTrue( vat.can(address(bobby), address(flop)) != 0 );
//         assertTrue( vat.can(address(bobby), address(goldFlip)) != 0 );
//         assertTrue( vat.can(address(bobby), address(end)) != 0 );
//         assertTrue( vat.can(address(alice), address(pot)) != 0 );
//         assertTrue( vat.can(address(alice), address(flop)) != 0 );
//         assertTrue( vat.can(address(alice), address(goldFlip)) != 0 );
//         assertTrue( vat.can(address(alice), address(end)) != 0 );
//         // UNIMPLEMENTED << assertTrue( vat.can(address(vow)) == SetItem( flap ) ); >>
//         // UNIMPLEMENTED << assertTrue( vat.ilks() == "gold" |-> Ilk( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 1000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 3000000000000000000000000000000000000 , 1000000000000000000000000000 ) , FInt( 1000000000000000000000000000000000000000000000000000000000 , 1000000000000000000000000000000000000000000000 ) , FInt( 0 , 1000000000000000000000000000000000000000000000 ) ) ); >>
//         // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(end)) == Urn( FInt( 0 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
//         // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(alice)) == Urn( FInt( 10000000000000000000 , 1000000000000000000 ) , FInt( 10000000000000000000 , 1000000000000000000 ) ) ); >>
//         // UNIMPLEMENTED << assertTrue( vat.urns("gold", address(bobby)) == Urn( FInt( 9999999996666666667 , 1000000000000000000 ) , FInt( 0 , 1000000000000000000 ) ) ); >>
//         assertTrue( vat.gem("gold", address(end)) == 3333333333 );
//         assertTrue( vat.gem("gold", address(alice)) == 0 );
//         assertTrue( vat.gem("gold", address(goldFlip)) == 0 );
//         assertTrue( vat.gem("gold", address(bobby)) == 0 );
//         assertTrue( vat.dai(address(flap)) == 0 );
//         assertTrue( vat.dai(address(pot)) == 0 );
//         assertTrue( vat.dai(address(end)) == 0 );
//         assertTrue( vat.dai(address(bobby)) == 7000000000000000000000000000000000000000000000 );
//         assertTrue( vat.dai(address(alice)) == 13000000000000000000000000000000000000000000000 );
//         assertTrue( vat.dai(address(vow)) == 0 );
//         assertTrue( vat.sin(address(flap)) == 0 );
//         assertTrue( vat.sin(address(pot)) == 0 );
//         assertTrue( vat.sin(address(end)) == 0 );
//         assertTrue( vat.sin(address(bobby)) == 0 );
//         assertTrue( vat.sin(address(alice)) == 0 );
//         assertTrue( vat.sin(address(vow)) == 10000000000000000000000000000000000000000000000 );
//         assertTrue( vat.vice() == 10000000000000000000000000000000000000000000000 );
//         assertTrue( vat.live() == 0 );
//         assertTrue( vow.live() == 0 );
    
//     }

}
