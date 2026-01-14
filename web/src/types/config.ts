export interface ConfigInterface {
  debug: boolean;
  useBuiltInSeatbeltLogic: boolean;
  compassLocation: "top" | "bottom";
  compassAlways: boolean;
  useSkewedStyle: boolean;
  skewAmount: number;
  showInfoPanel: boolean;
  hudLogo?: string;
}
