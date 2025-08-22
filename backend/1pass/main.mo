import RegionList "../lib/RegionList";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import SBuffer "../lib/StableBuffer";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat16 "mo:base/Nat16";
import Nat "mo:base/Nat";
import T "../Types";
import TT "./Types";
import archive "./archive";
import U "../utils";
import IC "../IC";

shared (installer) actor class Main(adminPrincipal : Principal) {
  private let MainActor : T.MainActor = actor (Principal.toText(installer.caller));
  type AccountActor = actor {
    getDAppAcctInfo : query (T.IdentityToken, T.AppId) -> async T.DAppAcctInfo;
  };
  type ArchiveData = {
    /// The reference to the archive canister
    Actor : archive.Main;
    start : Nat;
    var end : Nat;
    var fulled : Bool;
  };

  type UserBase = {
    passTip : Text;
    indexs : [T.Index];
  };

  let appId : T.AppId = 6;
  let MB = 1024 * 1024;
  let KiB8 = 8192;

  let blobify : RegionList.Blobify<UserBase> = {
    to_blob = func(indexs : UserBase) : Blob { to_candid (indexs) };
    from_blob = func(blob : Blob) : UserBase = switch (from_candid (blob) : ?UserBase) {
      case (?indexs) indexs;
      case (null) Debug.trap("Failed to decode UserBase");
    };
  };

  stable let index_store = RegionList.new<UserBase>(#nat16(65535), true); // Nat16.maximumValue; => 65535
  let UserBaseList = RegionList.RList<UserBase>(index_store, blobify);

  stable let archives = SBuffer.init<ArchiveData>(1);
  let Archives = SBuffer.Use<ArchiveData>(archives);

  stable var ArchiveCreateTimestamp = 0;

  public shared func addItem(_item : TT.Item, appIdentityToken : T.AppIdentityTokenArgs) : async Bool {
    let (acct, identityToken) = buildAcctClient(appIdentityToken);
    let authInfo : T.DAppAcctInfo = await acct.getDAppAcctInfo(identityToken, appId);

    if (_item.title.size() > 64 or _item.title.size() < 1) throw Error.reject("The title size cannot be larger than 64 bytes");
    if (_item.body.size() >= KiB8 or _item.body.size() < 1) throw Error.reject("The body size cannot be larger than 8KiB");
    let now = U.now('s');
    if (ArchiveCreateTimestamp + 7 > now) throw Error.reject("assetApplicationIsInProgressTip");
    let item = {
      _item with created = now;
      updated = now;
    };
    switch (UserBaseList.getOpt(authInfo.uid)) {
      case (?base) {
        if (base.indexs.size() > 9) throw Error.reject("Currently only 10 storage items are open");
        let index = await addToArchive(item);
        let indexs = U.add2Array<T.Index>(base.indexs, index);
        let base_new : UserBase = {
          base with indexs;
        };
        UserBaseList.put(authInfo.uid, base_new);
      };
      case (null) throw Error.reject("Please set the passphrase first !");
    };
    true;
  };

  public shared func updateItem(index : T.Index, item : TT.Item, update : TT.Update, appIdentityToken : T.AppIdentityTokenArgs) : async Bool {
    let (acct, identityToken) = buildAcctClient(appIdentityToken);
    let authInfo : T.DAppAcctInfo = await acct.getDAppAcctInfo(identityToken, appId);
    if (item.title.size() > 64 or item.title.size() < 1) throw Error.reject("The title size cannot be larger than 64 bytes");
    switch (update) {
      case (#andBody) {
        if (item.body.size() >= KiB8 or item.body.size() < 1) throw Error.reject("The body size cannot be larger than 8KiB");
      };
      case (_) {};
    };

    let ?base = UserBaseList.getOpt(authInfo.uid) else throw Error.reject("parameterException");
    if (Array.indexOf<T.Index>(index, base.indexs, Nat.equal) == null) throw Error.reject("parametersA_exception|index");
    let archiveData = matchArchiveData(index);
    archiveData.Actor.update(index, item, update);
    true;
  };

  public shared func setPassTip(passTip : Text, appIdentityToken : T.AppIdentityTokenArgs) : async Bool {
    let (acct, identityToken) = buildAcctClient(appIdentityToken);
    let authInfo : T.DAppAcctInfo = await acct.getDAppAcctInfo(identityToken, appId);
    switch (UserBaseList.getOpt(authInfo.uid)) {
      case (?userBase) throw Error.reject("Passphrase prompt summary already exists");
      case (null) {
        // Example  "aaa8bbb";
        if (passTip.size() != 7) throw Error.reject("Passphrase prompts that the summary length is incorrect");
        let userBase : UserBase = {
          passTip = passTip;
          indexs = [];
        };
        UserBaseList.put(authInfo.uid, userBase);
      };
    };
    true;
  };

  public composite query func getPassTip(appIdentityToken : T.AppIdentityTokenArgs) : async Text {
    let (acct, identityToken) = buildAcctClient(appIdentityToken);
    let authInfo : T.DAppAcctInfo = await acct.getDAppAcctInfo(identityToken, appId);
    let ?userBase = UserBaseList.getOpt(authInfo.uid) else return "";
    userBase.passTip;
  };

  public composite query func listHead(appIdentityToken : T.AppIdentityTokenArgs) : async [(T.Index, TT.Head)] {
    let (acct, identityToken) = buildAcctClient(appIdentityToken);
    let authInfo : T.DAppAcctInfo = await acct.getDAppAcctInfo(identityToken, appId);
    let ?userBase = UserBaseList.getOpt(authInfo.uid) else return [];

    let GroupArchive = groupArchiveData(userBase.indexs);
    let IndexAndHeadHeads = Buffer.Buffer<(T.Index, TT.Head)>(userBase.indexs.size());
    for ((archive, ids) in GroupArchive.vals()) {
      let indexAndHeads = await archive.Actor.listHead(ids);
      for (item in indexAndHeads.vals()) IndexAndHeadHeads.add(item);
    };
    Buffer.toArray(IndexAndHeadHeads);
  };

  public composite query func getBody(index : T.Index, appIdentityToken : T.AppIdentityTokenArgs) : async Blob {
    let (acct, identityToken) = buildAcctClient(appIdentityToken);
    let authInfo : T.DAppAcctInfo = await acct.getDAppAcctInfo(identityToken, appId);
    let ?userBase = UserBaseList.getOpt(authInfo.uid) else throw Error.reject("parametersA_exception|uid");
    if (Array.indexOf<T.Index>(index, userBase.indexs, Nat.equal) == null) throw Error.reject("parametersA_exception|index");
    let archiveData = matchArchiveData(index);
    await archiveData.Actor.getBody(index);
  };

  public query func count() : async (Nat, Nat) {
    let countItmes = if (Archives.size() == 0) 0 else SBuffer.last(Archives).end + 1;
    (UserBaseList.size(), countItmes);
  };

  public query func rts_info() : async [(Text, Nat)] { U.rts_info() };

  public query func showState() : async RegionList.State {
    UserBaseList.showState();
  };

  public shared (msg) func upgradeArchive(wasm_module : Blob) : async Bool {
    if (installer.caller != msg.caller) throw Error.reject("thisfunctionNotSupportExternalCalls");
    let ic : IC.ICActor = actor ("aaaaa-aa");
    for (item in Archives.vals()) {
      let canister_id = Principal.fromActor(item.Actor);
      let installCodeParams : IC.InstallCodeParams = {
        mode = #upgrade;
        canister_id;
        wasm_module;
        arg = to_candid (item.start);
      };
      await ic.install_code(installCodeParams);
    };
    true;
  };

  func addToArchive(item : TT.Item) : async Nat {
    let archiveData = if (Archives.size() == 0 or SBuffer.last(Archives).fulled) {
      ArchiveCreateTimestamp := U.now('s');
      let start = if (Archives.size() == 0) 0 else {
        var old_archiveData = SBuffer.last(Archives);
        old_archiveData.end + 1;
      };
      Cycles.add<system>(T.Trillion_1);
      let archiveActor = await archive.Main(start);
      let new_archiveData : ArchiveData = {
        Actor = archiveActor;
        start;
        var end = start;
        var fulled = false;
      };
      MainActor.receiveUpdates(#OnePassArchiveCanId(U.toCanisterId(archiveActor)));
      Archives.add(new_archiveData);
      let ic : IC.ICActor = actor ("aaaaa-aa");
      ignore await IC.update_controllers(ic, Principal.fromActor(new_archiveData.Actor), [adminPrincipal, installer.caller]);
      ArchiveCreateTimestamp := 0;
      new_archiveData;
    } else SBuffer.last(Archives);

    let (index, fulled) = await archiveData.Actor.append(item);
    archiveData.end := index;
    archiveData.fulled := fulled;
    return archiveData.end;
  };

  func matchArchiveData(index : T.Index) : ArchiveData {
    var i = 0;
    for (archive in Archives.vals()) {
      if (index >= archive.start and index <= archive.end) return archive;
    };
    Debug.trap("item index id out of bounds!!!");
  };

  func groupArchiveData(indexs : [T.Index]) : [(ArchiveData, [T.Index])] {
    let result = Buffer.Buffer<(ArchiveData, [T.Index])>(Archives.size());
    for (archive in Archives.vals()) {
      let buffer = Buffer.Buffer<T.Index>(indexs.size());
      for (index in indexs.vals()) {
        if (index >= archive.start and index <= archive.end) buffer.add(index);
      };
      if (buffer.size() > 0) result.add((archive, Buffer.toArray(buffer)));
    };
    return Buffer.toArray(result);
  };

  func buildAcctClient(appIdentityToken : T.AppIdentityTokenArgs) : (acct : AccountActor, identityToken : T.IdentityToken) {
    let acct : AccountActor = actor (appIdentityToken.accCanisterId);
    return (acct, appIdentityToken.dAppIdentToken);
  };

};
