import React, { useMemo } from "react";
import { PiSeatbeltFill } from "react-icons/pi";

interface SeatbeltIndicatorProps extends React.HTMLAttributes<HTMLDivElement> {
  isSeatbeltOn: boolean;
  iconSize?: string;
  iconSpacing?: string;
}

export const SeatbeltIndicator = React.memo(({ 
  isSeatbeltOn, 
  iconSize = "1.25vw", 
  iconSpacing = "12px", 
  ...props 
}: SeatbeltIndicatorProps) => {
  const getColor = useMemo(() => {
    return isSeatbeltOn ? "#22C55E" : "#EF4444"; // Green when on, red when off
  }, [isSeatbeltOn]);

  const getIconColor = useMemo(() => {
    return 'rgba(255, 255, 255, 0.87)'; // Keep icon white
  }, []);

  return (
    <div className={"flex flex-col items-center justify-center w-[clamp(40px,2.5vw,60px)] h-[clamp(60px,4vh,80px)]"} {...props}>
      <div
        className="flex items-center justify-center"
        style={{
          height: iconSpacing,
          fontSize: `clamp(12px,${iconSize},16px)`,
          marginBottom: iconSpacing,
          color: getIconColor,
        }}
      >
        <PiSeatbeltFill />
      </div>
      <div className={"relative w-[80%] bg-black/20 shadow h-[clamp(3px,0.4vh,6px)] rounded-full drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)]"}>
        <div
          className="absolute max-w-full transition-all rounded-full shadow left-0 h-full z-20"
          style={{
            width: "100%", // Always full width
            backgroundColor: getColor,
            boxShadow: `0 0 5px ${getColor}, 0 0 10px ${getColor}, 0 0 15px ${getColor}`,
          }}
        ></div>
      </div>
    </div>
  );
}); 