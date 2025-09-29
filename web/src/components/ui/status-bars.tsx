import { useMemo } from "react";
import { TiHeartFullOutline } from "react-icons/ti";

interface StatBarProps extends React.HTMLAttributes<HTMLDivElement> {
  Icon?: React.ComponentType<{ className?: string }>;
  value?: number;
  maxValue?: number;
  color?: string;
  vertical?: boolean;
  iconColor?: string;
}

export const StatBar = ({ Icon = TiHeartFullOutline, value = 20, maxValue = 100, color = "#F2F2F2", vertical = false,  iconColor = "text-y_white", ...props }: StatBarProps) => {
  const percentage = useMemo(() => (value / maxValue) * 100, [value, maxValue]);
  return (
    <div className={`flex ${vertical ? "h-[3vh]" : "w-full"} items-center gap-[0.2vw]`} {...props}>
      {!vertical && <Icon className={`${iconColor} text-[clamp(12px,1.2vw,16px)] drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)]`} />}
      {!vertical && (
        <div className="min-w-[clamp(24px,2.5vw,32px)] flex justify-center">
          <p
            className="text-[clamp(10px,0.8vw,14px)] drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)] text-center font-bold"
            style={{
              color: "#ffffff",
              textShadow: `0 0 5px #ffffff, 0 0 10px #ffffff, 0 0 15px #ffffff`,
            }}
          >
            {value}
          </p>
        </div>
      )}
      <div className={`relative drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)] ${vertical ? "h-full w-[clamp(3px,0.4vw,6px)] rounded-full" : "w-full h-[0.4vw] rounded-full" } bg-black/30`}>
        <div
          className={`absolute ${vertical ? "bottom-0 w-full" : "left-0 h-full"} transition-all bg-red-500 rounded-[1px] ease-in-out`}
          style={{
            backgroundColor: color,
            [vertical ? "height" : "width"]: `${percentage}%`,
            [vertical ? "maxHeight" : "maxWidth"]: `100%`,
            borderRadius: percentage < 100 ? "50px" : "9999px",
            overflow: "hidden",
            boxShadow: `0 0 5px 1px ${color}`,
          }}
        />
      </div>
      {vertical && <Icon className={`${iconColor} drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)] text-[clamp(10px,1vw,14px)]`} />}
    </div>
  );
};

interface StatBarSegmentedProps extends React.HTMLAttributes<HTMLDivElement> {
  Icon?: React.ComponentType<{ className?: string }>;
  value?: number;
  color?: string;
}

export const StatBarSegmented = ({ Icon = TiHeartFullOutline, value = 20, color = "#F2F2F2", ...props }: StatBarSegmentedProps) => {
  const segments = 3;
  const segmentWidth = 100 / segments;

  const segmentFills = useMemo(
    () =>
      Array.from({ length: segments }, (_, i) => {
        const segmentMaxValue = ((i + 1) * 100) / segments;
        if (value >= segmentMaxValue) {
          return 100;
        } else if (value > (i * 100) / segments) {
          return ((value - (i * 100) / segments) / segmentWidth) * 100;
        } else {
          return 0;
        }
      }),
    [value, segments, segmentWidth],
  );

  return (
    <div className="flex items-center gap-[0.2vw] w-full" {...props}>
      <Icon className="text-y_white text-[clamp(12px,1.2vw,16px)] drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)]" />
      <div className="min-w-[clamp(24px,2.5vw,32px)] flex justify-center">
        <p 
          className="text-[clamp(10px,0.8vw,14px)] drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)] text-center font-bold" 
          style={{ 
            color: "#ffffff",
            textShadow: `0 0 5px #ffffff, 0 0 10px #ffffff, 0 0 15px #ffffff`,
          }}
        >
          {value}
        </p>
      </div>
      <div className="relative flex gap-[clamp(1px,0.1vw,2px)] *:drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)] w-full h-[0.4vw] rounded-full">
        {segmentFills.map((fill, index) => (
          <div 
            key={index} 
            className="relative w-full h-full rounded-full bg-black/30"
          >
            <div 
              className="absolute left-0 h-full transition-all" 
              style={{
                backgroundColor: color,
                width: `${fill}%`,
                borderRadius: fill < 100 ? "50px" : "9999px",
                boxShadow: fill > 0 ? `0 0 5px 1px ${color}` : 'none',
              }}
            />
          </div>
        ))}
      </div>
    </div>
  );
};
