export const KWIVER_BRIDGE_UNAVAILABLE_DISPLAY_ERROR =
  "Kwiver runtime unavailable. Please verify server root and build artifacts.";

export function kwiver_bridge_unavailable_details(bridgeStatus) {
  const candidate = typeof bridgeStatus?.loaded_candidate === "string"
    ? bridgeStatus.loaded_candidate
    : "none";
  const firstError = Array.isArray(bridgeStatus?.load_errors)
      && bridgeStatus.load_errors.length > 0
    ? String(bridgeStatus.load_errors[0])
    : "n/a";
  return { candidate, first_error: firstError };
}

export function kwiver_bridge_unavailable_error(bridgeStatus) {
  const details = kwiver_bridge_unavailable_details(bridgeStatus);
  return [
    "[kwiver-only] ui.bootstrap: bridge unavailable (candidate=",
    details.candidate,
    ", error=",
    details.first_error,
    ")",
  ].join("");
}
