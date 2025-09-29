import { atom, useAtom, useAtomValue, useSetAtom } from "jotai";

const skewedStyleState = atom<boolean>(false);
const skewAmountState = atom<number>(20);

export const useSkewedStyle = () => useAtomValue(skewedStyleState);
export const useSetSkewedStyle = () => useSetAtom(skewedStyleState);
export const useSkewedStyleStore = () => useAtom(skewedStyleState);

export const useSkewAmount = () => useAtomValue(skewAmountState);
export const useSetSkewAmount = () => useSetAtom(skewAmountState);
export const useSkewAmountStore = () => useAtom(skewAmountState);