import React, { useCallback, useMemo } from "react";
import { useNuiEvent } from "@/hooks/useNuiEvent";
import { usePlayerState } from "@/states/player";
import { useVehicleStateStore, type VehicleStateInterface } from "@/states/vehicle";
import { debug } from "@/utils/debug";
import Speedometer from "./ui/speedometer";
import { TextProgressBar } from "./ui/text-progress-bar";
import { SeatbeltIndicator } from "./ui/seatbelt-indicator";
import { FaGasPump } from 'react-icons/fa';
import { PiEngineFill } from "react-icons/pi";
import { useSkewedStyle, useSkewAmount } from "@/states/skewed-style";

const CarHud = React.memo(function CarHud() {
  const [vehicleState, setVehicleState] = useVehicleStateStore();
  const playerState = usePlayerState();
  const skewedStyle = useSkewedStyle();
  const skewedAmount = useSkewAmount();

  const handleVehicleStateUpdate = useCallback(
    (newState: VehicleStateInterface) => {
      setVehicleState((prevState) => {
        // Only update if critical values have changed
        if (
          prevState.speed !== newState.speed ||
          prevState.rpm !== newState.rpm ||
          prevState.engineState !== newState.engineState ||
          prevState.engineHealth !== newState.engineHealth ||
          prevState.gears !== newState.gears ||
          prevState.currentGear !== newState.currentGear ||
          prevState.fuel !== newState.fuel ||
          prevState.speedUnit !== newState.speedUnit
        ) {
          return newState;
        }
        return prevState;
      });
    },
    [setVehicleState],
  );

  useNuiEvent<VehicleStateInterface>("state::vehicle::set", handleVehicleStateUpdate);

  const renderProgressBars = useCallback(() => {
    return (
      <>
        <TextProgressBar icon={<FaGasPump />} value={vehicleState.fuel} iconSize="1.2vw" />
        <TextProgressBar icon={<PiEngineFill />} value={vehicleState.engineHealth} iconSize="1.2vw" />
        <SeatbeltIndicator isSeatbeltOn={playerState.isSeatbeltOn} iconSize="1.2vw" />
      </>
    );
  }, [vehicleState.fuel, vehicleState.engineHealth, playerState.isSeatbeltOn]);

  const content = useMemo(() => {
    if (!playerState.isInVehicle) {
      debug("(CarHud) Returning with no children since the player is not in a vehicle.");
      return null;
    }

    return (
      <div
        className={"absolute bottom-[clamp(20px,3.5vh,60px)] right-[clamp(5px,0.1vw,20px)] w-fit h-fit flex-col items-center flex justify-center gap-[clamp(4px,0.5vh,12px)] ultrawide-optimized"}
        style={skewedStyle ? {
          transform: `perspective(1000px) rotateY(-${skewedAmount}deg)`,
          backfaceVisibility: "hidden",
          transformStyle: "preserve-3d",
          willChange: "transform",
        } : undefined}
      >
        <Speedometer
          speed={vehicleState.speed}
          maxRpm={100}
          rpm={vehicleState.rpm}
          gears={vehicleState.gears}
          currentGear={vehicleState.currentGear}
          engineHealth={vehicleState.engineHealth}
          speedUnit={vehicleState.speedUnit}
        />
        <div className={"flex gap-[clamp(8px,0.5vw,16px)] items-center -mt-[clamp(8px,1vh,20px)] ml-[clamp(8px,0.5vw,16px)]"}>
          {renderProgressBars()}
        </div>
      </div>
    );
  }, [playerState.isInVehicle, vehicleState, playerState.isSeatbeltOn, skewedStyle]);

  return content;
});

export default CarHud;
