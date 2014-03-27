test "leafJs should be loaded",()->
    console.assert Leaf
    console.assert Leaf.Widget
    console.assert Leaf.EventEmitter
    ok !!Leaf
    