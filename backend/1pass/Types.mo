import Blob "mo:base/Blob";
module {

  //   public type Item = {
  //     title : Text;
  //     body : [Nat8];
  //     created : Nat;
  //     updated : Nat;
  //     compress : Bool;
  //   };

  public type Head = {
    title : Text;
    created : Nat;
    updated : Nat;
    compress : Bool;
  };

  public type Body = {
    body : Blob; //  [Nat8]
  };

  public type Item = Head and Body;

  public type Update = {
    #head;
    #andBody;
  }

  // public type ArchiveActor = actor {
  //     append : shared (Item) -> async (Nat, Bool);
  //     put : shared (Nat, Item) -> ();
  //     get : query (Nat) -> async Item;
  //     list : query [Nat] -> async [(Nat, Item)];
  // };

};
