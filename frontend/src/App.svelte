<script>
	// @ts-nocheck
	import { setContext, onMount } from "svelte";
	import {
		Button,
		Cell,
		Icon,
		Calendar,
		Popup,
		NavBar,
		Skeleton,
		Input,
		Toast,
		Badge,
		Modal,
		Loading,
	} from "stdf";
	//import { fade, scale } from "svelte/transition";
	//import { quintOut } from "svelte/easing";
	import { STDFTheme, switchTheme, darkMode } from "stdf/theme";
	//import { en_US, zh_CN } from "stdf/lang";
	import { ic_delta, ic_1pass } from "./lib/state.svelte";
	import util from "./lib/util";
	import { t, isLoading } from "svelte-i18n";
	//import * as aesjs from "aes-js";
	import { CTR } from "aes-js";
	//import hash from "js-crypto-hash";
	import { createHash } from "sha256-uint8array";

	//解决 ios 不支持按钮:active 伪类
	// Solve the problem that ios does not support the button: active pseudo class
	document.body.addEventListener("touchstart", function () {
		//...空函数即可
		// ... Empty function is OK
	});
	let textDecoder = new TextDecoder();
	let textEncoder = new TextEncoder();
	let NumberFormat = Intl.NumberFormat("en-US", { maximumFractionDigits: 3 });
	let firstPopup = $state(true);
	let userNum = $state("…");
	let itemNum = $state("…");
	let identityToken = null;
	let loadingState = $state(2);
	let headList = $state([]);
	let viewOf = $state("list"); // list , detail
	let detailMode = $state("view"); // view edit
	let toastVisible = $state(false);
	let toastMsg = "";
	let loadingModal = $state(false);
	let loadingMsg = $state("");
	let viewSourceData = $state(false);
	let showPassphrase = $state(false);
	ic_1pass.count().then((/** @type {any} */ counts) => {
		console.log("ic_1pass then");
		let [users, items] = counts;
		userNum = NumberFormat.format(users);
		itemNum = NumberFormat.format(items);
	});

	let thisItme = $state({
		index: 0,
		title: "",
		body: [],
		bodyText: "",
		created: 1753411683,
		updated: 0,
		compress: false,
	});
	let thisOriginalBodyText = $state("");
	let thisOriginalBodyBytes = $state([]);
	let thisOriginalTitle = $state("");
	let ciphertextSize = $state(0);
	let compressedSize = $state(0);

	let demoData = {
		title: "Address and private key (Demo Example)",
		body: [
			126, 107, 141, 93, 194, 204, 179, 32, 126, 201, 70, 67, 156, 186,
			201, 199, 232, 70, 197, 234, 27, 92, 213, 60, 93, 208, 110, 66, 80,
			255, 89, 11, 75, 85, 126, 182, 101, 232, 162, 166, 157, 152, 21, 32,
			94, 131, 238, 19, 0, 33, 229, 88, 91, 228, 240, 202, 201, 218, 164,
			19, 198, 79, 53, 251, 125, 92, 229, 31, 102, 68, 57, 142, 221, 52,
			202, 54, 38, 206, 23, 166, 105, 203, 197, 148, 204, 42, 139, 149,
			145, 221, 157, 50, 245, 206, 233, 152, 52, 25, 180, 196, 54, 67,
			221, 174, 128, 83, 237, 48, 46, 67, 88, 36, 217, 9, 135, 146, 197,
			78, 209, 4, 157, 56, 116, 123, 90, 219, 22, 171, 43, 163, 248, 196,
			146, 216, 64, 55, 186, 232, 94, 180, 5, 82, 206, 34, 57, 166, 188,
			15, 219, 163, 145, 82, 211, 119, 191, 26, 85, 48, 164, 154, 241,
			196, 195, 85, 134, 134, 81, 154, 34, 82, 214, 33, 17, 159, 248, 142,
			210, 226, 188, 46, 78, 233, 99, 191, 130, 100, 226, 138, 252, 10,
			192, 96, 201, 132, 5, 30, 237, 60, 214, 86, 117, 213, 0, 177, 203,
			181, 232, 112, 47, 251, 221, 180, 151, 252, 232, 115, 207, 143, 126,
			211, 180, 187, 96, 131, 78, 46, 89, 71, 182, 206, 76, 89, 152, 59,
			117, 227, 105, 30, 129, 188, 216, 158, 71, 34, 144, 255, 169, 124,
			195, 235, 152, 163, 225, 254, 63, 152, 15, 21, 35, 97, 123, 49, 97,
			172, 151, 110, 38, 225, 14, 188, 217, 17, 21, 222, 58, 101, 44, 193,
			244, 197, 59, 136, 248, 145, 141, 125, 130, 15, 196,
		],
		created: 1753411683,
		updated: parseInt(Date.now() / 1000),
		compress: true,
	};
	let passTip = $state("");
	let isShaking = $state(false);
	let inputPassword = $state("password");
	let passphrase = localStorage.getItem("passphrase");
	let domo1pass = "Demonstration phrases";

	let inputPassphrase = $state("");
	let re_inputPassphrase = $state("");

	//let demobody =	"Bitcoin:\n1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa\n5Kb8kLf9zgWQnogidDA76MzPL6TsZZY36hWXMssSzNydYXYB9KF\n\nEthereum:\n0x742d35Cc6634C0532925a3b844Bc454e4438f44e\n0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d\n\nICP:\nxlmdg-vqaaa-aaaam-qaava-cai\npuzzle winner forest amazing ocean ribbon spatial gesture april mouse theory sweet";

	function shakPassphraseButton() {
		toast($t("passphraseNotSet"));
		isShaking = true;
		setTimeout(() => (isShaking = false), 2000);
	}
	function showPassword() {
		inputPassword = "text";
		console.log(inputPassword);
		setTimeout(() => (inputPassword = "password"), 2000);
	}
	onMount(async () => {
		console.log("onMount");
		//console.log("aes", aes);

		if (identityToken != null) {
			getPassTip();
		}
		//console.log("demobody.length", demobody.length);
		// An example 128-bit key (16 bytes * 8 bits/byte = 128 bits)
		//var key = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

		// let key1 = await hash.compute(textEncoder.encode(domo1pass), "SHA-256");
		// let key2 = createHash().update(textEncoder.encode(domo1pass)).digest();
		// console.log("key1", key1);
		// console.log("key2", key2);

		// Convert text to bytes
		// var textBytes = textEncoder.encode(textTest);
		// console.log("原来.length", textBytes.length);

		// let gzipd = await util.gzipBuffer(textBytes);
		// console.log("gzipd.length", gzipd.byteLength);

		// let unzip = util.unGzipBuffer(gzipd);

		// let gzipdu8 = new Uint8Array(gzipd);
		// console.log("原来gzipdu8", gzipdu8);
		// var encryptedBytes = (await aesCtr("demo")).encrypt(
		// 	new Uint8Array([]),
		// );

		// console.log("加密后", encryptedBytes.toString());
		// The counter mode of operation maintains internal state, so to
		// decrypt a new instance must be instantiated.
		//var aesCtr = new aesjs.ModeOfOperation.ctr(key, new aesjs.Counter(3));
		// var decryptedBytes = (await aesCtr("demo")).decrypt(
		// 	new Uint8Array(demoData.body),
		// );
		// console.log("解密后", decryptedBytes);
		// try {
		// 	let ungzdec = await util.unGzipBuffer(decryptedBytes);
		// 	let ungzipu8 = new Uint8Array(ungzdec);
		// 	console.log("解压后", ungzipu8);
		// 	console.log("decryptedText ungzdec", textDecoder.decode(ungzipu8));
		// } catch (error) {
		// 	console.log("error", error);
		// }
	});

	async function startUsing() {
		identityToken = await util.getAppIdentityToken();
		//console.log("token", JSON.stringify(identityToken));
		if (identityToken != null) {
			firstPopup = false;
			loadingState = 1;
			await listHead();
			getPassTip();
		}
	}
	async function getPassTip() {
		if (passTip != "") return passTip;
		try {
			showLoading($t("loadingData"));
			passTip = await ic_1pass.getPassTip(identityToken);
		} catch (error) {
			let rejectText = parseRejectText(error.message);
			alert(await window.delta.langText(rejectText));
		} finally {
			closeLoading();
		}
		return passTip;
	}
	async function listHead() {
		try {
			headList = await ic_1pass.listHead(identityToken);
			headList.reverse();
			loadingState = 2;
		} catch (error) {
			let rejectText = parseRejectText(error.message);
			alert(await window.delta.langText(rejectText));
			if (
				rejectText == "authenticationTokenIsInvalid" ||
				rejectText == "authorizationHasExpired"
			) {
				localStorage.removeItem("identToken");
				startUsing();
			}
		}
		// console.log("listHead", typeof listHead, listHead);
	}

	async function getBody(index) {
		try {
			showLoading($t("loadingData"));
			let body = await ic_1pass.getBody(index, identityToken);
			return body;
		} catch (error) {
			let rejectText = parseRejectText(error.message);
			alert(await window.delta.langText(rejectText));
		} finally {
			closeLoading();
		}
	}
	const aesCtrKey = {};
	async function aesCtr(type) {
		if (type == "demo") {
			//if (aesCtrinstance["demo"]) return aesCtrinstance["demo"];
			let key;
			if (aesCtrKey["demo"]) {
				key = aesCtrKey["demo"];
			} else {
				let key_ = createHash()
					.update(textEncoder.encode(domo1pass))
					.digest();
				aesCtrKey["demo"] = key_;
				key = aesCtrKey["demo"];
			}
			return new CTR(key, 3);
			//return new aesjs.ModeOfOperation.ctr(key, new aesjs.Counter(3));
		}
		let key;
		let uid;
		if (aesCtrKey["user"]) {
			key = aesCtrKey["user"];
			uid = aesCtrKey["uid"];
		} else {
			if (identityToken == null)
				identityToken = await util.getAppIdentityToken();
			let uid_ = util.parseDID(identityToken["dAppIdentToken"]["did"]);
			let key_ = createHash()
				.update(textEncoder.encode(passphrase))
				.digest();
			aesCtrKey["user"] = key_;
			aesCtrKey["uid"] = uid_;
			key = aesCtrKey["user"];
			uid = aesCtrKey["uid"];
		}
		console.log("passphrase", passphrase, "uid", uid);
		return new CTR(key, uid);
		//return new aesjs.ModeOfOperation.ctr(key, new aesjs.Counter(uid));
	}

	function switchToList() {
		viewOf = "list";
		detailMode = "view";
		thisItme.title = "";
		thisItme.body = [];
		thisItme.bodyText = "";
		thisOriginalBodyText = "";
		thisOriginalTitle = "";
		ciphertextSize = 0;
		compressedSize = 0;
	}

	async function openDetail(index, item) {
		thisItme.index = index;
		thisItme.title = item.title;
		thisItme.created = item.created;
		thisItme.updated = item.updated;
		thisItme.compress = item.compress;
		viewOf = "detail";
		let passchannel = "";
		let phraseTip = "";
		showLoading($t("loadingData"));
		if (index == -1) {
			await Promise.all([util.wait(600)]);
			thisItme.body = item.body;
			passchannel = "demo";
		} else {
			if (passTip == "" || passphrase == null) {
				alert($t("passphraseNotExist_pleaseSet"));
				switchToList();
				closeLoading();
				return shakPassphraseButton();
			}
			phraseTip = `${passTipPrefix1}[${passTipHide1}]${passTipSuffix1}`;
			let [body] = await Promise.all([getBody(index), util.wait(500)]);
			thisItme.body = body;
			passchannel = "user";
		}
		let uint8Array = new Uint8Array(thisItme.body);
		showLoading(
			$t("decryptingDataUsingTip", {
				values: { tip: phraseTip },
			}),
		);
		ciphertextSize = uint8Array.byteLength;
		let AesCtr = await aesCtr(passchannel);
		let [decBytes] = await Promise.all([
			AesCtr.decrypt(uint8Array),
			util.wait(900),
		]);
		console.log(
			"decBytes.byteLength",
			decBytes.byteLength,
			decBytes.slice(0, 10).toString(),
		);
		let bodyText;
		let bodyBytes;
		if (thisItme.compress) {
			showLoading($t("unpackingData"));
			compressedSize = decBytes.byteLength;
			let [ungzBytes] = await Promise.all([
				util.unGzipBuffer(decBytes),
				util.wait(600),
			]);
			bodyBytes = new Uint8Array(ungzBytes);
			bodyText = textDecoder.decode(bodyBytes);
		} else {
			bodyBytes = decBytes;
			bodyText = textDecoder.decode(bodyBytes);
		}

		thisOriginalTitle = thisItme.title;
		thisOriginalBodyText = bodyText;
		thisOriginalBodyBytes = bodyBytes;
		thisItme.bodyText = bodyText;
		closeLoading();
		// console.log(
		// 	"thisOriginalBodyText.length",
		// 	NumberFormat.format(thisOriginalBodyText.length / 1000),
		// );
		//console.log(thisItme.bodyText);
	}
	async function openCreate() {
		if (passTip == "") return shakPassphraseButton();
		if (headList.length > 9) return alert($t("limitedSpace_maximumOf10"));

		thisItme.index = -2;
		viewOf = "detail";
		detailMode = "create";
	}
	async function saveDetail() {
		if (
			thisOriginalBodyText == thisItme.bodyText &&
			thisOriginalTitle == thisItme.title
		)
			return alert($t("dataHasNotChanged"));

		let updateMode = {};
		let bodyArrayU8 = [];
		let compress = false;
		if (thisOriginalTitle != thisItme.title) {
			if (thisItme.title.length < 2 || thisItme.title.length > 64)
				return alert($t("titleLengthMustBeBetween2and64"));
			updateMode = { head: null };
		}
		if (thisOriginalBodyText != thisItme.bodyText) {
			if (thisItme.bodyText.length == 0)
				return alert($t("contentCannotBeEmpty"));
			updateMode = { andBody: null };
			let passchannel = "";
			if (thisItme.index == -1) {
				passchannel = "demo";
			} else {
				if (passphrase == null)
					return alert($t("passphraseNotExist_pleaseSet"));
				passchannel = "user";
			}
			let bodyBytes = textEncoder.encode(thisItme.bodyText);
			if (bodyBytes.length > 800) {
				showLoading($t("compressingData"));
				let [arrayBuffer] = await Promise.all([
					util.gzipBuffer(bodyBytes),
					util.wait(600),
				]);
				bodyBytes = new Uint8Array(arrayBuffer);
				compress = true;
			}
			showLoading(
				$t("encryptingDataUsingTip", {
					values: {
						tip: `${passTipPrefix1}[${passTipHide1}]${passTipSuffix1}`,
					},
				}),
			);
			let [arrayU8] = await Promise.all([
				(await aesCtr(passchannel)).encrypt(bodyBytes),
				util.wait(900),
			]);

			if (arrayU8.byteLength > 8192) {
				closeLoading();
				return alert("Content size cannot exceed 8kib");
			}
			bodyArrayU8 = arrayU8;
		}
		showLoading($t("uploadingData"));
		try {
			if (thisItme.index == -1) {
				await Promise.all([util.wait(500)]);
				if (bodyArrayU8.length > 0) demoData.body = bodyArrayU8;
				demoData.title = thisItme.title;
				demoData.compress = compress;
			} else if (thisItme.index == -2) {
				let item = {
					title: thisItme.title,
					created: 0,
					updated: 0,
					compress,
					body: bodyArrayU8,
				};
				await ic_1pass.addItem(item, identityToken);
				setTimeout(listHead, 1000);
				switchToList();
			} else {
				let item = {
					title: thisItme.title,
					created: 0,
					updated: 0,
					compress,
					body: bodyArrayU8,
				};
				await ic_1pass.updateItem(
					thisItme.index,
					item,
					updateMode,
					identityToken,
				);
				setTimeout(listHead, 1000);
			}
			thisOriginalBodyText = thisItme.bodyText;
			thisOriginalTitle = thisItme.title;
			toast($t("savedSuccessfully"));
		} catch (error) {
			let rejectText = parseRejectText(error.message);
			alert(await window.delta.langText(rejectText));
		} finally {
			closeLoading();
		}
	}
	function parseRejectText(errorMsg) {
		let messages = errorMsg.split("Reject text:");
		if (messages[1]) {
			return messages[1].split("Error code:")[0].trim();
		}
		return errorMsg;
	}
	function toast(msg) {
		toastMsg = msg;
		toastVisible = true;
	}
	function showLoading(msg) {
		loadingMsg = msg;
		loadingModal = true;
	}
	function closeLoading() {
		loadingMsg = "";
		loadingModal = false;
	}
	function copyText(id) {
		const textArea = document.createElement("textarea");
		textArea.value = document.querySelector(id).textContent;
		document.body.appendChild(textArea);
		textArea.select();
		try {
			document.execCommand("copy");
			toast($t("copySuccessful"));
		} catch (err) {
			toast($t("copyFailedToExecute_pleaseManually"));
			console.error("Copy failed:", err);
		}
		document.body.removeChild(textArea);
	}
	async function popupPassphrase() {
		showPassphrase = true;
		//tryGetPassTip();
	}
	let passTipPrefix = $derived(
		inputPassphrase.length < 8 ? "" : inputPassphrase.slice(0, 3),
	);
	let passTipHide = $derived(
		inputPassphrase.length < 8 ? "-" : String(inputPassphrase.length - 6),
	);
	let passTipSuffix = $derived(
		inputPassphrase.length < 8 ? "" : inputPassphrase.slice(-3),
	);

	let passTipPrefix1 = $derived(passTip == "" ? "" : passTip.slice(0, 3));
	let passTipHide1 = $derived(passTip == "" ? "-" : passTip.charAt(3));
	let passTipSuffix1 = $derived(passTip == "" ? "" : passTip.slice(-3));

	async function setPassphrase() {
		if (inputPassphrase.length < 8 || inputPassphrase.length > 32)
			return alert($t("lengthMustBeBetween8and32"));
		if (inputPassphrase.trim().length != inputPassphrase.length)
			return alert($t("cannotContainWhitespaceAtBothEnds"));
		if (inputPassphrase != re_inputPassphrase)
			return alert($t("twoPassphrasesEnteredNotMatch"));
		let passTip_this = passTipPrefix + passTipHide + passTipSuffix;
		try {
			showLoading($t("writingContract"));
			let bool = await ic_1pass.setPassTip(passTip_this, identityToken);
			passTip = passTip_this;
			showPassphrase = false;
			passphrase = inputPassphrase;
			localStorage.setItem("passphrase", passphrase);
			inputPassphrase = "";
			toast($t("setupSuccessful"));
		} catch (error) {
			let rejectText = parseRejectText(error.message);
			alert(await window.delta.langText(rejectText));
		} finally {
			closeLoading();
		}
	}
	function savePassphrase() {
		if (
			inputPassphrase.startsWith(passTipPrefix1) == false ||
			inputPassphrase.endsWith(passTipSuffix1) == false ||
			inputPassphrase.length != parseInt(passTipHide1) + 6
		)
			return alert($t("passphraseEnteredNotMatchDigestFormat"));
		localStorage.setItem("passphrase", inputPassphrase);
		passphrase = inputPassphrase;
		showPassphrase = false;
		toast($t("savedSuccessfully"));
	}
</script>

{#if location.host == ""}
	<div class="text-center">
		<p>
			The Delta main application version is too low to support this app.
			Please upgrade!
		</p>
		<Button
			onclick={() => {
				window.delta.openUrl("https://www.delta.kim/auto/download");
			}}
		>
			Upgrade now!
		</Button>
	</div>
{:else if $isLoading}
	Please wait...
{:else}
	<Toast bind:visible={toastVisible} message={toastMsg} duration={1200} />
	<Popup
		bind:visible={loadingModal}
		size={0}
		position="center"
		radiusPosition="all"
		radius="xl"
		px="8"
		maskClosable={false}
		zIndex={800}
	>
		<div class="flex flex-col items-center py-4 bg-black/70 text-white">
			<Loading type="1_26" theme inverse />
			<div>{loadingMsg}</div>
		</div>
	</Popup>
	<Popup
		bind:visible={showPassphrase}
		size={0}
		position="center"
		radiusPosition="all"
		radius="xl"
		px="8"
		maskClosable={false}
	>
		<div class="flex flex-col h-full py-4 px-2">
			{#if passphrase == null}
				{#if passTip != ""}
					<h3 class="text-center font-semibold">
						{$t("enterPassphrase")}
					</h3>
					<Input
						title="Passphrase"
						bind:value={inputPassphrase}
						maxlength={32}
						tip={$t("enterYourPassphraseToEncryptAndDecrypt")}
						data1={$t("tipSummary")}
					>
						{#snippet data2Child()}
							<div class="flex pl-1 text-base">
								<span class="text-red-600 whitespace-pre"
									>{passTipPrefix1}</span
								>
								<span class="text-blue-600"
									>[{passTipHide1}]</span
								>
								<span class="text-red-600 whitespace-pre"
									>{passTipSuffix1}</span
								>
							</div>
						{/snippet}
					</Input>
					<div
						class="bg-white px-3 dark:bg-gray-800 active:bg-gray-100 dark:active:bg-gray-600 my-4 mx-2 rounded-md border border-red-500"
					>
						<div class="-mt-2 text-xs">
							<div
								class="bg-white inline-block px-1 text-gray-600"
							>
								{$t("notice")}
							</div>
						</div>
						<div
							class="shadow-xs dark:shadow-white/5 text-orange-500 text-sm"
						>
							{$t(
								"enteringIncorrectPassphraseWillDecryptionFailure",
							)}
						</div>
					</div>
				{:else}
					<h3 class="text-center font-semibold">
						{$t("setPassphrase")}
					</h3>
					<Input
						title="Passphrase"
						bind:value={inputPassphrase}
						maxlength={32}
						tip={$t("lengthRangeIs8to32_example", {
							values: { example: "I love delta" },
						})}
						data1={$t("tipSummary")}
						clear
					>
						{#snippet data2Child()}
							<div class="flex pl-1 text-base">
								<span class="text-red-600 whitespace-pre"
									>{passTipPrefix}</span
								>
								<span class="text-blue-600"
									>[{passTipHide}]</span
								>
								<span class="text-red-600 whitespace-pre"
									>{passTipSuffix}
								</span>
							</div>
						{/snippet}
					</Input>
					<Input
						title={$t("repeatPassphrase")}
						bind:value={re_inputPassphrase}
						maxlength={32}
						clear
					/>
					<div
						class="bg-white px-3 dark:bg-gray-800 active:bg-gray-100 dark:active:bg-gray-600 my-4 mx-2 rounded-md border border-red-500"
					>
						<div class="-mt-2 text-xs">
							<div
								class="bg-white inline-block px-1 text-gray-600"
							>
								{$t("notice")}
							</div>
						</div>
						<div
							class="shadow-xs dark:shadow-white/5 text-orange-500 text-sm"
						>
							{$t("passphraseNotice1")}
							<!-- 通行短语主要用于保证系统维护人员无法查看您的机密资料。 -->
						</div>
					</div>
				{/if}
			{:else}
				<h3 class="text-center font-semibold">
					{$t("viewPassphrase")}
				</h3>
				{#if inputPassword == "password"}
					<Input
						type="password"
						title="Passphrase"
						value={passphrase}
					>
						{#snippet label4Child()}
							<button onclick={showPassword}>
								<img src="./see.svg" alt="see" />
							</button>
						{/snippet}
					</Input>
				{:else}
					<Input title="Passphrase" value={passphrase} />
				{/if}

				<div class="flex pl-1 text-lg">
					{$t("tipSummary")}
					<span class="text-red-600 whitespace-pre"
						>{passTipPrefix1}</span
					>
					<span class="text-blue-600">[{passTipHide1}]</span>
					<span class="text-red-600 whitespace-pre"
						>{passTipSuffix1}
					</span>
				</div>
			{/if}

			<div class="flex justify-evenly">
				<Button
					size="full"
					heightIn="1"
					injClass="px-4"
					fill="line"
					onclick={() => (showPassphrase = false)}
					>{$t("close")}</Button
				>
				{#if passphrase == null}
					{#if passTip != ""}
						<Button
							size="full"
							heightIn="1"
							injClass="px-4"
							onclick={savePassphrase}>{$t("save")}</Button
						>
					{:else}
						<Button
							size="full"
							heightIn="1"
							injClass="px-4"
							onclick={setPassphrase}>{$t("submit")}</Button
						>
					{/if}
				{/if}
			</div>
		</div>
	</Popup>
	{#if viewOf == "list"}
		<section>
			<Popup
				bind:visible={firstPopup}
				size={0}
				position="center"
				radiusPosition="all"
				radius="xl"
				px="8"
				maskClosable={false}
			>
				<div class="flex h-full flex-col items-center pt-4">
					<img src="./logo.png" width="64" alt="Vite Logo" />
					<h3 class="text-2xl font-medium pb-2">1Pass</h3>
					<div class="w-full flex flex-row justify-evenly pb-8">
						<div class="bg-emerald-500 text-white px-1">
							{$t("safe")}
						</div>
						<div class="bg-sky-500 text-white px-1">
							{$t("easy")}
						</div>
						<div class="bg-amber-400 text-gray-900 px-1">
							{$t("free")}
						</div>
						<div class="bg-violet-500 text-white px-1">
							{$t("openSource")}
						</div>
					</div>
					<p class="px-8">
						{@html $t("alreadyXusersAndYConfidentialData", {
							values: {
								userNum: `<span class="text-red-600">${userNum}</span><sup
						class="text-green-500">↑</sup>`,
								itemNum: `<span class="text-red-600">${itemNum}</span><sup class="text-green-500">↑</sup>`,
							},
						})}
					</p>
					<p class="pb-3 text-green-500">{$t("beingProtected")}</p>
					<Button size="auto" onclick={startUsing}
						><div class="px-2">{$t("getStarted")}</div></Button
					>
				</div>
			</Popup>
			<NavBar title="">
				{#snippet leftChild()}
					<div
						class="h-full w-20 flex flex-row items-center bg-white leading-8 dark:bg-black/50"
					>
						<button
							onclick={() => {
								window.delta.openUrl(
									"https://github.com/delta-kim/1pass",
								);
							}}
						>
							<img
								class="mx-2 max-h-6"
								src="./folder-type-github.png"
								alt="github"
							/>
						</button>
						<button
							onclick={() => {
								window.delta.openUrl(
									"https://github.com/delta-kim/1pass/whitepaper",
								);
							}}
						>
							<img
								class="max-h-5"
								src="./whitepaper.svg"
								alt="whitepaper"
							/>
						</button>
					</div>
				{/snippet}
				{#snippet rightChild()}
					<!-- <div
					class="pr-8 h-full w-18 flex flex-row items-center bg-white dark:bg-black/50"
				>
					<img class="max-h-6 pr-2" src="./1pass.svg" alt="one pass" />
					<img class="max-h-5"  src="./add-item.svg" alt="add item" />
				</div> -->
					<button
						class:shaking={isShaking}
						class="inline-flex items-center justify-center truncate active:opacity-80 py-3 px-1 w-full text-white dark:text-black border-solid rounded-sm false border border-black/20 dark:border-white/30 !text-black dark:!text-white h-7 mt-3"
						onclick={popupPassphrase}
						><span style="color: rgb(21, 83, 134);">Pass</span><span
							style="color: rgb(231,112,46);">phrase</span
						>
					</button>

					<Button
						injClass="mx-2"
						fill="textTheme"
						customSize
						customWidth={24}
						customHeight={24}
						onclick={openCreate}
					>
						<img src="./add-item.svg" alt="add item" />
					</Button>
				{/snippet}
			</NavBar>
			{#if loadingState == 0}
				<div class="h-14"></div>
				<Skeleton width="full" type="code" />
			{:else if loadingState == 1}
				<Skeleton type="p" />
				<div class="h-4"></div>
				<Skeleton type="p" />
			{:else if loadingState == 2}
				{#each headList as [index, item]}
					<Cell
						title={item.title}
						subTitle="{$t('timestamp') +
							util.formatDate(item.created)} - {util.formatDate(
							item.updated,
						)}"
						onclick={() => openDetail(index, item)}
					/>
				{/each}
				<Cell
					title={demoData.title}
					subTitle="{$t('timestamp') +
						util.formatDate(demoData.created)} - {util.formatDate(
						demoData.updated,
					)}"
					onclick={() => openDetail(-1, demoData)}
				/>
			{/if}
		</section>
	{:else}
		<!-- detail -->
		<section class="flex flex-col h-screen">
			<Popup
				bind:visible={viewSourceData}
				size={80}
				position="center"
				radiusPosition="all"
				radius="xl"
				px="8"
				maskClosable={false}
			>
				<div class="flex flex-col h-full">
					<h3 class="pt-4 text-center font-semibold">
						View source data
					</h3>
					<textarea class="flex-1 p-1 m-2 bg-black text-yellow-500"
						>{thisItme.body.toString()}</textarea
					>
					<Button fill="line" onclick={() => (viewSourceData = false)}
						>{$t("close")}</Button
					>
				</div>
			</Popup>
			<NavBar title={$t(detailMode)} onclickLeft={switchToList}>
				{#snippet rightChild()}
					<Button
						disabled={detailMode == "create"}
						injClass="mr-2"
						fill="textTheme"
						customSize
						customWidth={24}
						customHeight={24}
						onclick={() => {
							viewSourceData = true;
						}}
					>
						<img
							class="text-yellow-500"
							src="./cipher.svg"
							alt="cipher"
							title="Cipher"
						/>
					</Button>
					{#if thisOriginalBodyText != thisItme.bodyText || thisOriginalTitle != thisItme.title}
						<Button
							injClass="mr-2"
							fill="textTheme"
							customSize
							customWidth={24}
							customHeight={24}
							onclick={saveDetail}
						>
							<img
								src="./submit.svg"
								alt="submit"
								title="Submit"
							/>
						</Button>
					{/if}
					<Button
						disabled={detailMode == "create"}
						injClass="mr-2"
						fill="textTheme"
						customSize
						customWidth={24}
						customHeight={24}
						onclick={() => {
							if (detailMode == "view") {
								detailMode = "edit";
							} else {
								detailMode = "view";
							}
						}}
					>
						{#if detailMode == "view"}
							<img src="./edit.svg" alt="edit" />
						{:else if detailMode == "edit"}
							<img src="./view.svg" alt="view" />
						{/if}
					</Button>
				{/snippet}
			</NavBar>
			<Input
				bind:value={thisItme.title}
				placeholder={$t("title")}
				maxlength={42}
				disabled={detailMode == "view"}
			/>
			{#if detailMode == "view"}
				{#if thisItme.bodyText.length > 0}
					<div class="flex-1">
						{#each thisItme.bodyText.split("\n") as line, index}
							<div
								class="flex justify-between items-center border-b border-dashed mx-1"
							>
								<div
									id="line_{index}"
									class="min-h-4 flex-grow"
									style="word-break: break-word"
								>
									{line}
								</div>
								<div>
									{#if line.length > 0}
										<Button
											fill="textTheme"
											customSize
											customWidth={24}
											customHeight={24}
											heightIn="0"
											onclick={() =>
												copyText(`#line_${index}`)}
										>
											<img src="./copy.svg" alt="copy" />
										</Button>
									{/if}
								</div>
							</div>
						{/each}
					</div>
				{/if}
			{:else}
				<textarea
					placeholder={$t("content")}
					bind:value={thisItme.bodyText}
					class="flex-1 p-1 m-2 bg-black/5 dark:bg-white/5"
				></textarea>
			{/if}
			<div
				class="flex justify-around flex-wrap text-white bg-slate-950 text-xs"
			>
				<span class="flex items-center"
					>Encrypt: <Badge
						text="AES"
						injClass="bg-yellow-600"
						radius="sm"
						isInner
					/></span
				>
				{#if detailMode == "create"}
					<span
						>Plaintext:
						<span class="text-green-500"
							>{NumberFormat.format(
								thisItme.bodyText.length / 1000,
							)}kB</span
						>
					</span>
				{:else}
					<span class="flex items-center"
						>Compress: <Badge
							text={thisItme.compress ? "gzip" : "none"}
							injClass="bg-blue-700"
							radius="sm"
							isInner
						/></span
					>
					<span
						>Original:
						{#if thisOriginalBodyText.length == thisItme.bodyText.length}
							<span class="text-green-500"
								>{NumberFormat.format(
									thisOriginalBodyBytes.length / 1000,
								)}kB</span
							>
						{:else}
							<span class="line-through"
								>{NumberFormat.format(
									thisOriginalBodyBytes.length / 1000,
								)}</span
							>
							<span class="text-green-500"
								>{NumberFormat.format(
									textEncoder.encode(thisItme.bodyText)
										.length / 1000,
								)}kB</span
							>
						{/if}
					</span>
					<span
						>Ciphertext: <span class="text-green-500"
							>{NumberFormat.format(
								ciphertextSize / 1000,
							)}kB</span
						></span
					>
				{/if}
				{#if compressedSize > 0}
					<span
						>Compressed: <span class="text-green-500"
							>{NumberFormat.format(
								compressedSize / 1000,
							)}kB</span
						></span
					>
				{/if}
			</div>
		</section>
	{/if}
{/if}

<style>
	@keyframes shake {
		0%,
		100% {
			transform: translateX(0);
		}
		25% {
			transform: translateX(-5px);
		}
		75% {
			transform: translateX(5px);
		}
	}
	.shaking {
		animation: shake 0.2s ease-in-out infinite;
	}
</style>
