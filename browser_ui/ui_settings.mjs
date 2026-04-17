import { CONSTANTS } from "./arrow.mjs";

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
