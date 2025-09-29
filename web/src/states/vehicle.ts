import { atom, useAtom, useAtomValue, useSetAtom } from "jotai";

export interface VehicleStateInterface {
    speed: number;
    rpm: number;
    engineState: boolean;
    engineHealth: number;
    gears: number;
    currentGear: string;
    fuel: number;
    nos: number;
    speedUnit: "MPH" | "KPH";
    headlights: number;
}

const mockVehicleState: VehicleStateInterface = {
    speed: 222,
    rpm: 50,
    engineState: true,
    engineHealth: 50,
    gears: 6,
    currentGear: "N",
    fuel: 50,
    nos: 40,
    speedUnit: "KPH",
    headlights: 50
};

const vehicleState = atom<VehicleStateInterface>(mockVehicleState);

export const useVehicleState = () => useAtomValue(vehicleState);
export const useSetVehicleState = () => useSetAtom(vehicleState);
export const useVehicleStateStore = () => useAtom(vehicleState);