import { usePlayerState } from "@/states/player";
import React from "preact/compat";
import { FaCompass, FaLocationDot, FaMap } from "react-icons/fa6";
import IconLabelBox from "./ui/icon-label-box";
import { useCompassLocation, useCompassAlways } from "@/states/compass-location";

const Compass = () => {
  const playerState = usePlayerState();
  const compassLocation = useCompassLocation();
  const compassAlways = useCompassAlways();

  if (!compassAlways && !playerState.isInVehicle) {
    return null;
  }
  return (
    <div className={compassLocation === "bottom" ? "flex absolute bottom-[clamp(2px,0.2vh,8px)] w-full h-fit items-center justify-center" : "flex w-full h-[clamp(60px,10vh,120px)] items-center justify-center"}>
      <div className={"flex gap-[clamp(8px,0.8vw,24px)] items-center justify-center w-[clamp(300px,50%,800px)]"}>
        <IconLabelBox label={playerState.heading} Icon={FaCompass} iconColor="#228BE6" />
        <IconLabelBox label={playerState.streetLabel} className="min-w-[clamp(120px,20%,200px)]" Icon={FaLocationDot} iconColor="#228BE6" />
        <IconLabelBox className="px-[clamp(8px,0.8vw,16px)]" label={playerState.areaLabel} Icon={FaMap} iconColor="#228BE6" />
      </div>
    </div>
  );
};

export default React.memo(Compass);

