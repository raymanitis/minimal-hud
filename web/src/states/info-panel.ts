import { atom, useAtomValue, useSetAtom, useAtom } from "jotai";

const showInfoPanelState = atom<boolean>(true);

export const useShowInfoPanel = () => useAtomValue(showInfoPanelState);
export const useSetShowInfoPanel = () => useSetAtom(showInfoPanelState);
export const useShowInfoPanelStore = () => useAtom(showInfoPanelState);
