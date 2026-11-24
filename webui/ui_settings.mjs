import { CONSTANTS } from "./arrow.mjs";

export const QUIVER_PACKAGE_VERSIONS = new Map([
    ["1.7.0", "1.7.0 (latest)"],
    ["1.6.0", "1.6.0 (TeX Live 2026)"],
    ["1.2.0", "1.2.0 (TeX Live 2024–2025)"],
]);
const DEFAULT_QUIVER_PACKAGE_VERSION = QUIVER_PACKAGE_VERSIONS.keys().next().value;

class Settings {
    constructor() {
        this.data = {
            // Whether to wrap the `tikz-cd` output in `\[ \]`.
            "export.centre_diagram": true,
            // Whether to use `\&` instead of `&` for column separators in `tikz-cd` output.
            "export.ampersand_replacement": false,
            // Whether to export diagrams with the `cramped` option.
            "export.cramped": false,
            // Whether to wrap the `tikz-cd` output in a standalone LaTeX document.
            "export.standalone": false,
            "quiver.package_version": DEFAULT_QUIVER_PACKAGE_VERSION,
            // Whether to use a fixed size for the embedded `<iframe>`, or compute the size based on
            // the diagram.
            "export.embed.fixed_size": false,
            // The width of an HTML embedded diagram in pixels.
            "export.embed.width": CONSTANTS.DEFAULT_EMBED_SIZE.WIDTH,
            // The height of an HTML embedded diagram in pixels.
            "export.embed.height": CONSTANTS.DEFAULT_EMBED_SIZE.HEIGHT,
            // Which variant of the corner to use for pullbacks/pushouts.
            "diagram.var_corner": false,
            // Whether to use KaTeX or Typst rendering.
            "quiver.renderer": CONSTANTS.DEFAULT_RENDERER,
        };
        try {
            // Try to update the default values with the saved settings.
            this.data = Object.assign(
                this.data,
                JSON.parse(window.localStorage.getItem("settings"))
            );
        } catch (_) {
            // The JSON stored in `settings` was malformed.
        }
        if (!QUIVER_PACKAGE_VERSIONS.has(this.data["quiver.package_version"])) {
            this.data["quiver.package_version"] = DEFAULT_QUIVER_PACKAGE_VERSION;
        }
    }

    /// Returns a saved user setting, or the default value if a setting has not been modified yet.
    get(setting) {
        return this.data[setting];
    }

    /// Saves a user setting.
    set(setting, value) {
        this.data[setting] = value;
        window.localStorage.setItem("settings", JSON.stringify(this.data));
    }
}

export { Settings };
