import React from "react";
import { FaCompass } from "react-icons/fa";
import { twMerge } from "tailwind-merge";

interface IconLabelBoxProps extends React.HTMLAttributes<HTMLDivElement> {
  Icon?: React.ComponentType<{ className?: string }>;
  label?: string;
  className?: string;
  textClassName?: string;
  iconClassName?: string;
  iconColor?: string;
}

const IconLabelBox: React.FC<IconLabelBoxProps> = ({ Icon: Icon = FaCompass, label = "NW", className = "", textClassName = "", iconClassName = "", iconColor, ...props }) => {
  return (
    <div className={twMerge(`inline-flex items-center justify-center text-y_white bg-black/30 rounded-[8px] px-[clamp(8px,0.8vw,16px)] py-[clamp(4px,0.6vh,12px)]`, className)} {...props}>
      <Icon className={twMerge("mr-[clamp(4px,0.4vw,8px)] text-[clamp(12px,1vw,16px)]", iconClassName)} color={iconColor} />
      <p
        className={twMerge(`text-center text-y_white font-bold text-[clamp(10px,0.9vw,14px)]`, textClassName)}
        style={{
          whiteSpace: "nowrap",
          overflow: "visible",
          color: "#ffffff",
          textShadow: `0 0 2px #fff, 0 0 5px #fff, 0 0 5px #fff`,
        }}
      >
        {label}
      </p>
    </div>
  );
};

export default IconLabelBox;
