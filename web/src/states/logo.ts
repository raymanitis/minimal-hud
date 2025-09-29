import { atom, useAtom, useAtomValue, useSetAtom } from "jotai";

const defaultLogoUrl = "https://r2.fivemanage.com/43z7Bt109UNYve2xRiuvK/LogotypeAtleastRP500x500PNG.png";

const logoUrlState = atom<string>(defaultLogoUrl);

export const useLogoUrl = () => useAtomValue(logoUrlState);
export const useSetLogoUrl = () => useSetAtom(logoUrlState);
export const useLogoUrlStore = () => useAtom(logoUrlState);


