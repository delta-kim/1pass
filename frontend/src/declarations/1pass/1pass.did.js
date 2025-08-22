export const idlFactory = ({ IDL }) => {
  const Item = IDL.Record({
    'title' : IDL.Text,
    'created' : IDL.Nat,
    'body' : IDL.Vec(IDL.Nat8),
    'compress' : IDL.Bool,
    'updated' : IDL.Nat,
  });
  const DID = IDL.Text;
  const Token = IDL.Text;
  const IdentityToken = IDL.Record({ 'did' : DID, 'token' : Token });
  const CanisterId = IDL.Text;
  const AppIdentityTokenArgs = IDL.Record({
    'dAppIdentToken' : IdentityToken,
    'accCanisterId' : CanisterId,
  });
  const Index = IDL.Nat;
  const Head = IDL.Record({
    'title' : IDL.Text,
    'created' : IDL.Nat,
    'compress' : IDL.Bool,
    'updated' : IDL.Nat,
  });
  const Update = IDL.Variant({ 'head' : IDL.Null, 'andBody' : IDL.Null });
  const Main = IDL.Service({
    'addItem' : IDL.Func([Item, AppIdentityTokenArgs], [IDL.Bool], []),
    'count' : IDL.Func([], [IDL.Nat, IDL.Nat], ['query']),
    'getBody' : IDL.Func(
        [Index, AppIdentityTokenArgs],
        [IDL.Vec(IDL.Nat8)],
        ['composite_query'],
      ),
    'getPassTip' : IDL.Func(
        [AppIdentityTokenArgs],
        [IDL.Text],
        ['composite_query'],
      ),
    'listHead' : IDL.Func(
        [AppIdentityTokenArgs],
        [IDL.Vec(IDL.Tuple(Index, Head))],
        ['composite_query'],
      ),
    'rts_info' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Nat))],
        ['query'],
      ),
    'setPassTip' : IDL.Func([IDL.Text, AppIdentityTokenArgs], [IDL.Bool], []),
    'updateItem' : IDL.Func(
        [Index, Item, Update, AppIdentityTokenArgs],
        [IDL.Bool],
        [],
      ),
    'upgradeArchive' : IDL.Func([], [], ['oneway']),
  });
  return Main;
};
export const init = ({ IDL }) => { return [IDL.Principal]; };
