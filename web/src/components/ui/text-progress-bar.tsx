import React, { useMemo } from "react";

interface TextProgressBarProps extends React.HTMLAttributes<HTMLDivElement> {
  value?: number;
  icon?: React.ReactNode;
  color?: string;
  iconSize?: string;
  iconSpacing?: string;
}

export const TextProgressBar = React.memo(({ value = 50, icon, color = "#228BE6", iconSize = "1.2vw", iconSpacing = "12px", ...props }: TextProgressBarProps) => {
  const getColor = useMemo(() => {
    if (value <= 20) return "#FE2436";
    if (value <= 50) return "#FB8607";
    return color;
  }, [color, value]);

  return (
    <div className={"flex flex-col items-center justify-center w-[clamp(40px,2.5vw,60px)] h-[clamp(60px,4vh,80px)]"} {...props}>
      <div
        className="flex items-center justify-center"
        style={{
          height: iconSpacing,
          fontSize: `clamp(12px,${iconSize},16px)`,
          marginBottom: iconSpacing,
          color: 'rgba(255, 255, 255, 0.87)',
        }}
      >
        {icon}
      </div>
      <div className={"relative w-[80%] bg-black/20 shadow h-[clamp(3px,0.4vh,6px)] rounded-full drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)]"}>
        <div
          className="absolute max-w-full transition-all rounded-full shadow left-0 h-full z-20"
          style={{
            width: `${value}%`,
            backgroundColor: getColor,
            boxShadow: `0 0 5px ${getColor}, 0 0 10px ${getColor}, 0 0 15px ${getColor}`,
          }}
        ></div>
      </div>
    </div>
  );
});
