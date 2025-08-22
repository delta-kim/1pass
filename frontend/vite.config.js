import tailwindcss from '@tailwindcss/vite';
import svgSprite from 'rollup-plugin-stdf-icon';
import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

export default defineConfig({
	base: './',
	server: {
		host: '0.0.0.0'
	},
	define: {
		'global': 'window', // 替换 global 为 window
		'process.env': {}, // 替换 process.env
		'process.browser': true, // 告诉库当前是浏览器环境
	},

	plugins: [
		svelte(),
		tailwindcss(),
		// 一般来说，一个应用的的 svg 不多时都放在一个文件夹下，合并为一个 symbol 即可。此处演示了不同文件夹下的图标如何合并为不同的 symbol。
		// Generally speaking, when the svg of an application is not much, it is placed in a folder and merged into one symbol. This example shows how the icons in different folders are merged into different symbols.
		// svgSprite([
		// 	{ inFile: 'src/lib/svgs/Heroicons', outFile: 'public/symbols' },
		// 	{ inFile: 'src/lib/svgs/IconPark', outFile: 'public/symbols' },
		// 	{ inFile: 'src/lib/svgs/Remix', outFile: 'public/symbols' },
		// 	{ inFile: 'src/lib/svgs/iconify', outFile: 'public/symbols', simple: false }
		// ])
	]
});
