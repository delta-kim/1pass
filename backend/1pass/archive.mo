import RegionList "../lib/RegionList";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Nat16 "mo:base/Nat16";
import U "../utils";
import T "../Types";
import TT "./Types";

shared (installer) actor class Main(start : T.Index) {

  let blobifyHead : RegionList.Blobify<TT.Head> = {
    from_blob = func(blob : Blob) : TT.Head = switch (from_candid (blob) : ?TT.Head) {
      case (?data) data;
      case (null) Debug.trap("Failed to decode TT.Head");
    };
    to_blob = func(data : TT.Head) : Blob {
      to_candid (data);
    };
  };
  let blobifyBoby : RegionList.Blobify<Blob> = {
    from_blob = func(blob : Blob) : Blob = blob;
    to_blob = func(data : Blob) = data;
  };

  stable let head_store = RegionList.new<TT.Head>(#nat16(65535), false); // Nat16.maximumValue; => 65535
  let HeadList = RegionList.RList<TT.Head>(head_store, blobifyHead);

  stable let body_store = RegionList.new<Blob>(#nat16(65535), false); // Nat16.maximumValue; => 65535
  let BodyList = RegionList.RList<Blob>(body_store, blobifyBoby);

  public shared (msg) func append(item : TT.Item) : async (Nat, Bool) {
    if (installer.caller != msg.caller) throw Error.reject("thisfunctionNotSupportExternalCalls");
    let i = HeadList.add({
      title = item.title;
      created = item.created;
      updated = item.updated;
      compress = item.compress;
    });
    ignore BodyList.add(item.body);
    let fulled = if (i < 65536 * 10) false else true; // default --max-stable-pages = 65536, 10 elements per page
    return (i + start, fulled);
  };

  public shared (msg) func update(index : Nat, item : TT.Item, update : TT.Update) {
    if (installer.caller != msg.caller) throw Error.reject("thisfunctionNotSupportExternalCalls");
    let now = U.now('s');
    let i : Nat = index - start;
    let head = HeadList.get(i);
    switch (update) {
      case (#head) {
        HeadList.put(
          i,
          {
            head with
            title = item.title;
            updated = now;
          },
        );
      };
      case (#andBody) {
        HeadList.put(
          i,
          {
            head with
            title = item.title;
            updated = now;
            compress = item.compress;
          },
        );
        BodyList.put(i, item.body);
      };
    };
  };

  public query func listHead(indexs : [Nat]) : async [(Nat, TT.Head)] {
    let buffer = Buffer.Buffer<(Nat, TT.Head)>(indexs.size());
    for (index in indexs.vals()) {
      let i : Nat = index - start;
      let head = HeadList.get(i);
      buffer.add((index, head));
    };
    Buffer.toArray(buffer);
  };

  public query func getBody(index : Nat) : async Blob {
    let i : Nat = index - start;
    BodyList.get(i);
  };

  public query func showHeadState() : async RegionList.State {
    HeadList.showState();
  };
  public query func showBodyState() : async RegionList.State {
    BodyList.showState();
  };
  public query func rts_info() : async [(Text, Nat)] { U.rts_info() };
};
