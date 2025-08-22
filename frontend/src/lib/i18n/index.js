import { register, init, getLocaleFromNavigator } from 'svelte-i18n';

// import en from './en.json';
// import zhCN from './zh-CN.json'
// addMessages('en', en);
// addMessages('zh-CN', zhCN);

register('bg', () => import('./bg.json'));
register('ckb', () => import('./ckb.json'));
register('de', () => import('./de.json'));
register('el', () => import('./el.json'));
register('en', () => import('./en.json'));
register('es', () => import('./es.json'));
register('fr', () => import('./fr.json'));
register('hi', () => import('./hi.json'));
register('it', () => import('./it.json'));
register('ja', () => import('./ja.json'));
register('ko', () => import('./ko.json'));
register('nl', () => import('./nl.json'));
register('pl', () => import('./pl.json'));
register('pt', () => import('./pt.json'));
register('ro', () => import('./ro.json'));
register('ru', () => import('./ru.json'));
register('sw', () => import('./sw.json'));
register('th', () => import('./th.json'));
register('tr', () => import('./tr.json'));
register('uk', () => import('./uk.json'));
register('ur', () => import('./ur.json'));
register('vi', () => import('./vi.json'));
register('ur', () => import('./ur.json'));
register('zh-CN', () => import('./zh-CN.json'));
register('zh-TW', () => import('./zh-TW.json'));


init({
    fallbackLocale: 'en',
    initialLocale: getLocaleFromNavigator(),
});