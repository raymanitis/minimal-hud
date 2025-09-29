import React, { useCallback, useEffect, useMemo, useRef } from "react";

interface SpeedometerProps {
  speed: number;
  maxRpm: number;
  rpm: number;
  gears: number;
  currentGear: string;
  engineHealth: number;
  speedUnit: "MPH" | "KPH";
}

const Speedometer: React.FC<SpeedometerProps> = React.memo(function Speedometer({ speed = 50, maxRpm = 100, rpm = 20, gears = 8, currentGear, speedUnit /* engineHealth = 50 */ }) {
  const percentage = useMemo(() => (rpm / maxRpm) * 100, [rpm, maxRpm]);
  const activeArcRef = useRef<SVGPathElement>(null);
  const dashLengthRef = useRef<number>(0);

  // Memoize polarToCartesian function to prevent recreation on every render
  const polarToCartesian = useCallback((centerX: number, centerY: number, radius: number, angleInDegrees: number) => {
    const angleInRadians = ((angleInDegrees - 90) * Math.PI) / 180.0;
    return {
      x: centerX + radius * Math.cos(angleInRadians),
      y: centerY + radius * Math.sin(angleInRadians),
    };
  }, []);

  const createArc = useMemo(
    () => (x: number, y: number, radius: number, startAngle: number, endAngle: number) => {
      const start = polarToCartesian(x, y, radius, startAngle);
      const end = polarToCartesian(x, y, radius, endAngle);
      const largeArcFlag = endAngle - startAngle <= 180 ? "0" : "1";
      return ["M", start.x, start.y, "A", radius, radius, 0, largeArcFlag, 1, end.x, end.y].join(" ");
    },
    [polarToCartesian],
  );

  const createGearLine = useMemo(
    () => (centerX: number, centerY: number, innerRadius: number, outerRadius: number, angle: number) => {
      const inner = polarToCartesian(centerX, centerY, innerRadius, angle);
      const outer = polarToCartesian(centerX, centerY, outerRadius, angle);
      return `M ${inner.x} ${inner.y} L ${outer.x} ${outer.y}`;
    },
    [polarToCartesian],
  );

  const arcColor = useMemo(() => (
    percentage >= 90 ? "#fe2436" : percentage >= 85 ? "#FB8607" : "#228BE6"
  ), [percentage]);

  // Compute and cache path length once
  useEffect(() => {
    const el = activeArcRef.current;
    if (!el) return;
    if (!dashLengthRef.current) {
      const length = el.getTotalLength();
      dashLengthRef.current = length;
      el.style.strokeDasharray = `${length} ${length}`;
      // Initialize to current percentage
      const initialOffset = length * (1 - percentage / 100);
      el.style.strokeDashoffset = `${initialOffset}`;
    }
  }, []);

  // On percentage change, set new offset and let CSS transition smooth it
  useEffect(() => {
    const el = activeArcRef.current;
    if (!el) return;
    const length = dashLengthRef.current || el.getTotalLength();
    dashLengthRef.current = length;
    const offset = length * (1 - percentage / 100);
    el.style.strokeDashoffset = `${offset}`;
  }, [percentage]);

  const gearLines = useMemo(
    () => {
      if (gears <= 0) return null;
      
      return [...Array(gears)].map((_, i) => {
        const angle = -120 + (i * 240) / Math.max(gears - 1, 1);
        const textPosition = polarToCartesian(0, 0, 30, angle);
        return (
          <g key={`gear-${i}`}>
            <path d={createGearLine(0, 0, 38, 42, angle)} stroke="#dee2e6" strokeWidth="1.3" opacity="100" strokeLinecap="round" />
            <text
              x={textPosition.x}
              y={textPosition.y}
              textAnchor="middle"
              alignmentBaseline="middle"
              fill="white"
              fontSize="5"
              fontWeight="bold"
              style={{
                filter: "drop-shadow(0 0 2px #ffffff) drop-shadow(0 0 4px #ffffff) drop-shadow(0 0 6px #ffffff)",
              }}
            >
              {i + 1}
            </text>
          </g>
        );
      });
    },
    [gears, createGearLine, polarToCartesian],
  );

  return (
    <div className="w-[15vw] h-[20vh] min-w-[200px] min-h-[160px] max-w-[300px] max-h-[240px] relative flex items-center justify-center -mb-[5vh] z-0">
      <svg viewBox="-50 -50 100 100" preserveAspectRatio="xMidYMid meet" className="w-full h-full">
        <defs>
          <filter id="glow">
            <feGaussianBlur stdDeviation="2.5" result="coloredBlur" />
            <feMerge>
              <feMergeNode in="coloredBlur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>
        <g>
          <path d={createArc(0, 0, 40, -120, 120)} fill="none" stroke="#11181a27" strokeWidth="4" />
        </g>
        <path
          ref={activeArcRef}
          d={createArc(0, 0, 40, -120, 120)}
          fill="none"
          strokeWidth="4"
          className="transition-all duration-250 ease-out"
          style={{
            stroke: arcColor,
            filter: `drop-shadow(0 0 2px ${arcColor}) drop-shadow(0 0 4px ${arcColor})`,
          }}
        />

        {gearLines}
      </svg>
      <div className="absolute inset-0 flex items-center justify-center">
        <div className="text-center flex flex-col">
          <span
            className="absolute -mt-[0.7vh] left-1/2 transform -translate-x-1/2 text-[clamp(14px,1.5vw,20px)] font-semibold text-white tabular-nums drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)]"
            style={{
              textShadow: "0 0 5px #ffffff, 0 0 10px #ffffff, 0 0 15px #ffffff",
            }}
          >
            {currentGear}
          </span>
          <span
            className="text-[clamp(24px,3vw,36px)] font-bold text-white tabular-nums drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)] mt-[1.4vh]"
            style={{
              textShadow: "0 0 5px #ffffff, 0 0 10px #ffffff, 0 0 15px #ffffff",
            }}
          >
            {speed}
          </span>
          <span
            className="text-[clamp(12px,1.5vw,18px)] mt-[0.1vh] font-semibold text-white drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)] uppercase"
            style={{
              textShadow: "0 0 5px #ffffff, 0 0 10px #ffffff, 0 0 15px #ffffff",
            }}
          >
            {speedUnit}
          </span>
          {/* Leftover from the original speedometer */}
          {/* {engineHealth < 30 && (
            <div className={"flex items-center justify-center *:drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,1)] *:size-[0.9vw] *:text-red-600 mt-1"}>
              <PiEngineFill />
            </div>
          )} */}
        </div>
      </div>
    </div>
  );
});

export default Speedometer;
