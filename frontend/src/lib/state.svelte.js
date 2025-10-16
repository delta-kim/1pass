import { createActor } from "../declarations/index";
import { idlFactory as deltaFactory } from "../declarations/delta/delta.did.js";
import { idlFactory as onePassFactory } from "../declarations/1pass/1pass.did.js";


const ic_host = "https://icp0.io";

export const userState = $state({
    name: 'name abc',
    /* ... */
});

export const ic_delta = createActor("ojpsk-siaaa-aaaam-adtea-cai", deltaFactory, {
    agentOptions: { host: ic_host },
});

export const ic_1pass = createActor("f7oom-hiaaa-aaaam-aenkq-cai", onePassFactory, {
    agentOptions: { host: ic_host },
});

//export const  deltaFactory;