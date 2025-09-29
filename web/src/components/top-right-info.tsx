import React, { useState, useEffect } from "react";
import { usePlayerState } from "@/states/player";
import { useSkewedStyle, useSkewAmount } from "@/states/skewed-style";
import { IconId, IconClockFilled } from "@tabler/icons-react";
import { useLogoUrl } from "@/states/logo";

const TopRightInfo = React.memo(function TopRightInfo() {
  const playerState = usePlayerState();
  const skewedStyle = useSkewedStyle();
  const skewedAmount = useSkewAmount();
  const [currentTime, setCurrentTime] = useState(new Date());
  const logoUrl = useLogoUrl();

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getPlayerId = () => {
    return playerState.playerId || "N/A";
  };

  return (
    <div
      className="absolute top-[clamp(20px,3.5vh,60px)] right-[clamp(20px,1vw,40px)] flex items-center gap-[clamp(12px,0.8vw,24px)] z-50"
      style={skewedStyle ? {
        transform: `perspective(1000px) rotateY(-${skewedAmount}deg)`,
        backfaceVisibility: "hidden",
        transformStyle: "preserve-3d",
        willChange: "transform",
      } : undefined}
    >
      {/* ID and Time Stack */}
      <div className="flex flex-col gap-[clamp(4px,0.5vh,12px)]">
        {/* Player ID Block */}
        <div className="flex items-center justify-center rounded-md pl-[clamp(4px,0.3vw,10px)] pr-[clamp(8px,0.6vw,16px)] py-[clamp(4px,0.4vh,10px)] w-[clamp(70px,4.5vw,110px)] h-[clamp(24px,2.2vh,44px)] bg-black/40 min-w-[60px] min-h-[28px]">
          <div className="flex items-center gap-[clamp(3px,0.2vw,8px)] w-full">
            <IconId className="w-[clamp(12px,0.9vw,20px)] h-[clamp(12px,0.9vw,20px)] min-w-[12px] min-h-[12px] flex-shrink-0" style={{ color: '#228BE6' }} />
            <span 
              className="text-white/90 font-medium text-[clamp(9px,0.8vw,16px)]"
              style={{
                textShadow: `0 0 2px #fff, 0 0 5px #fff, 0 0 5px #fff`,
              }}
            >
              {getPlayerId()}
            </span>
          </div>
        </div>

        {/* Time Block */}
        <div className="flex items-center justify-center rounded-md pl-[clamp(4px,0.3vw,10px)] pr-[clamp(8px,0.6vw,16px)] py-[clamp(4px,0.4vh,10px)] w-[clamp(70px,4.5vw,110px)] h-[clamp(24px,2.2vh,44px)] bg-black/40 min-w-[60px] min-h-[28px]">
          <div className="flex items-center gap-[clamp(3px,0.2vw,8px)] w-full">
            <IconClockFilled className="w-[clamp(12px,0.9vw,20px)] h-[clamp(12px,0.9vw,20px)] min-w-[12px] min-h-[12px] flex-shrink-0" style={{ color: '#228BE6' }} />
            <span 
              className="text-white/90 font-mono text-[clamp(9px,0.8vw,16px)] tracking-wider"
              style={{
                textShadow: `0 0 2px #fff, 0 0 5px #fff, 0 0 5px #fff`,
              }}
            >
              {formatTime(currentTime)}
            </span>
          </div>
        </div>
      </div>

      {/* Logo - Right side - Responsive sizing for ultrawide monitors */}
      <div className="flex items-center justify-center w-[clamp(65px,5vw,85px)] h-[clamp(65px,5vw,85px)] min-w-[60px] min-h-[60px]">
        <img
          src={logoUrl}
          alt="HUD Logo"
          className="w-full h-full object-contain"
          onError={(e) => {
            console.error('Logo failed to load:', e);
            console.error('Attempted src:', e.currentTarget.src);
            console.error('Current location:', window.location.href);
            e.currentTarget.style.display = 'none';
            const parent = e.currentTarget.parentElement;
            if (parent) {
              parent.innerHTML = '<div class="text-red-500 text-xs">LOGO ERROR<br/>Check console</div>';
            }
          }}
          onLoad={() => {
            console.log('Logo loaded successfully from:', window.location.href);
          }}
        />
      </div>
    </div>
  );
});

export default TopRightInfo; 