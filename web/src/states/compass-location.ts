import { atom, useAtom, useAtomValue, useSetAtom } from "jotai";

const compassLocationState = atom<"bottom" | "top" | "hidden">("top");
const compassAlwaysState = atom<boolean>(false);

export const useCompassLocation = () => useAtomValue(compassLocationState);
export const useSetCompassLocation = () => useSetAtom(compassLocationState);
export const useCompassLocationStore = () => useAtom(compassLocationState);

export const useCompassAlways = () => useAtomValue(compassAlwaysState);
export const useSetCompassAlways = () => useSetAtom(compassAlwaysState);
export const useCompassAlwaysStore = () => useAtom(compassAlwaysState);