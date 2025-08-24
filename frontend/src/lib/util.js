import { t } from "svelte-i18n";
import { get } from 'svelte/store';
const $t = get(t);
const util = {
    formatDate(time) {
        return new Date(Number(time) * 1000).toLocaleString();
    },

    async getAppIdentityToken() {
        let appIdentityToken = sessionStorage.getItem("identToken");
        if (appIdentityToken == null) {
            // @ts-ignore
            if (window.delta) {
                return await authByIdentToken(""); // $t("notAuthorizedYet")
            } else {
                window.alert($t("notAuthorizedYet"));
                return null;
            }
        }
        let identityToken = JSON.parse(appIdentityToken);
        if (identityToken.expiration < Date.now() / 1000) {
            // @ts-ignore
            let authorizationHasExpired = window.delta ? await window.delta.langText("authorizationHasExpired") : "Authorization has expired !"
            return await authByIdentToken(authorizationHasExpired);
        }
        delete identityToken.expiration;
        return identityToken;
    },
    async gzipBuffer(u8a) {
        // 创建可读流
        if (CompressionStream == undefined)
            return alert("The browser version is too low and does not support the compression function.")
        const byteStream = new Blob([u8a]).stream();
        const compressionStream = new CompressionStream('gzip');
        const compressedStream = byteStream.pipeThrough(compressionStream);
        const compressedBlob = await new Response(compressedStream).blob();
        return await compressedBlob.arrayBuffer();
    },
    async unGzipBuffer(u8a) {
        if (DecompressionStream == undefined)
            return alert("The browser version is too low and does not support the decompression function.")
        const byteStream = new Blob([u8a]).stream();
        const decompressionStream = new DecompressionStream('gzip');
        const decompressedStream = byteStream.pipeThrough(decompressionStream);
        const decompressedBlob = await new Response(decompressedStream).blob();
        return await decompressedBlob.arrayBuffer();
    },

    wait(time = 10) {
        return new Promise((resolve) => setTimeout(resolve, time));
    },
    /**
     * @param {string} did
     */
    parseDID(did) {
        if (did.length !== 13) {
            throw new Error("DID length is incorrect");
        }

        //let sumMaskLast = did.substring(0, 1);
        let id32 = did.substring(1);

        let id = _base32ToNat(id32);
        let _id = id;
        let sum = 0;

        while (_id > 0) {
            sum += _id % 10;
            _id = Math.floor(_id / 10);
        }
        // var sumMask = toBase32(sum);
        // if (!sumMask.endsWith(sumMaskLast)) {
        //   throw ("2.DID format is invalid");
        // }

        let idStr = id.toString();

        if (idStr.length < 15) {
            idStr = idStr.padStart(15, '0');
        }

        let indexStr = idStr.substring(0, 13);
        let len = parseInt(idStr.substring(13, 15));

        let index = parseInt(indexStr);

        return Math.floor(index / Math.pow(10, len));
    }
}
export default util;

async function authByIdentToken(title) {
    // @ts-ignore
    if (window.delta) {
        let bool = true;
        if (title != "") {
            // @ts-ignore
            bool = await window.delta.showConfirm(await window.delta.langText("authorizeDappAppToLogin"), title);
        }
        if (bool) {
            // @ts-ignore
            let res = await window.delta.authByIdentToken();
            if (res == null) return null;
            sessionStorage.setItem("identToken", JSON.stringify(res));
            return {
                accCanisterId: res.accCanisterId,
                dAppIdentToken: res.dAppIdentToken
            };
        }
    } else {
        window.alert(title);
        return null;
    }
}

function _base32ToNat(base32Str) {
    const chars32 = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "T", "U", "V", "W", "X", "Y"];
    const carry = 32;
    let i = base32Str.length;
    let nat = 0;

    for (let char of base32Str) {
        i -= 1;
        let locate = chars32.indexOf(char);
        if (locate === -1) {
            throw new Error(`Invalid base32 character: ${char}`);
        }
        nat += locate * Math.pow(carry, i);
    }
    return nat;
}