import { Actor, HttpAgent } from "@dfinity/agent";

/* CANISTER_ID is replaced by webpack based on node environment
 * Note: canister environment variable will be standardized as
 * process.env.CANISTER_ID_<CANISTER_NAME_UPPERCASE>
 * beginning in dfx 0.15.0
 */
// export const canisterId =
//   process.env.CANISTER_ID_DELTA;

export const createActor = (canisterId, idlFactory, options = {}) => {
  const agent = options.agent || HttpAgent.createSync({ ...options.agentOptions });

  if (options.agent && options.agentOptions) {
    console.warn(
      "Detected both agent and agentOptions passed to createActor. Ignoring agentOptions and proceeding with the provided agent."
    );
  }

  // Fetch root key for certificate validation during development
  //if (process.env.DFX_NETWORK !== "ic") {
  if (options.agentOptions.host.startsWith("http://")) {
    console.log("fetchRootKey start");
    //await agent.fetchRootKey();
    //console.log("fetchRootKey end");
  }

  // Creates an actor with using the candid interface and the HttpAgent
  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
    ...options.actorOptions,
  });
};

//export const delta = canisterId ? createActor(canisterId) : undefined;
