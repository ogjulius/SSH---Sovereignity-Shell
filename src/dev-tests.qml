// Headless unit tests for SSH's pure-JS core, run inside Quickshell's own
// QML/JS engine (the engine the shell actually uses):
//
//   QT_QPA_PLATFORM=offscreen qs -p src/dev-tests.qml
//
// Prints "RESULT <n> passed, <m> failed"; scripts/test.sh turns that into an exit code.
import QtQuick
import Quickshell
import "configuration/Schema.js" as Schema
import "utilities/Fuzzy.js" as Fuzzy
import "utilities/AtlasModel.js" as M
import "utilities/Fmt.js" as Fmt
import "themes/Palettes.js" as P
import "themes/Icons.js" as Icons
import "modules/settings/Keybinds.js" as KB
import "modules/lens/Intents.js" as Intents

ShellRoot {
    id: root
    property int passed: 0
    property var failures: []

    function eq(name, got, want) {
        const g = JSON.stringify(got), w = JSON.stringify(want);
        if (g === w) passed++;
        else failures.push(name + "\n      got:  " + g + "\n      want: " + w);
    }
    function ok(name, cond) { eq(name, !!cond, true); }

    function testSchema() {
        const d = Schema.defaults();
        eq("defaults: meridian height", d.meridian.height, 34);
        eq("defaults: rounded island shape", d.appearance.shape, "round");
        eq("defaults: top-edge shine on", d.appearance.shine, true);
        eq("defaults: meridian is an island", d.meridian.style, "island");
        eq("defaults: ruler ticks belong to the flush strip", d.meridian.showTicks, false);
        eq("defaults: readable default text scale", d.appearance.fontScale, 1.08);
        eq("defaults: app icons disabled for lean rendering", d.appearance.appIcons, false);
        eq("defaults: lock argv", d.commands.lock, ["loginctl", "lock-session"]);

        let r = Schema.merge({ appearance: { appIcons: true } });
        eq("app icons can be enabled", r.value.appearance.appIcons, true);
        eq("app icon override has no warning", r.warnings, []);

        r = Schema.merge({});
        eq("merge empty: no warnings", r.warnings, []);
        eq("merge empty: equals defaults", r.value, d);

        r = Schema.merge({ meridian: { height: 40 } });
        eq("merge valid override", r.value.meridian.height, 40);
        eq("merge valid override keeps siblings", r.value.meridian.showMinimap, true);

        r = Schema.merge({ meridian: { height: 9000 }, appearance: { mode: "neon" } });
        eq("merge out of range -> default", r.value.meridian.height, 34);
        eq("merge bad enum -> default", r.value.appearance.mode, "dark");
        eq("merge reports both", r.warnings.length, 2);

        r = Schema.merge({ bogus: 1, meridian: { nope: true } });
        eq("unknown keys reported", r.warnings.length, 2);
        ok("unknown keys dropped", r.value.bogus === undefined);

        r = Schema.merge({ meridian: "tall" });
        eq("non-object section -> defaults", r.value.meridian.height, 34);
        ok("non-object section warned", r.warnings.length === 1);

        r = Schema.merge({ commands: { lock: ["sh", "-c", ""] } });
        eq("argv with empty part rejected", r.value.commands.lock, ["loginctl", "lock-session"]);
        r = Schema.merge({ commands: { lock: "swaylock" } });
        eq("argv as string rejected", r.value.commands.lock, ["loginctl", "lock-session"]);

        r = Schema.merge({ appearance: { customAccent: "#12345" } });
        eq("bad hex rejected", r.value.appearance.customAccent, "#c9bfa9");
        r = Schema.merge({ weather: { latitude: null, longitude: 19.94 } });
        eq("numOrNull accepts null", r.value.weather.latitude, null);
        eq("numOrNull accepts number", r.value.weather.longitude, 19.94);
        r = Schema.merge({ meridian: { height: 33.5 } });
        eq("int rejects fractions", r.value.meridian.height, 34);

        let u = Schema.setPath({}, "meridian.height", 40);
        eq("setPath writes", u, { meridian: { height: 40 } });
        u = Schema.setPath(u, "meridian.height", 34);
        eq("setPath removes defaults", u, { meridian: {} });
        ok("specAt finds leaf", Schema.specAt("atlas.previews").t === "bool");
        ok("specAt rejects section", Schema.specAt("atlas") === null);
        ok("specAt rejects unknown", Schema.specAt("atlas.nope") === null);
    }

    function testFuzzy() {
        ok("prefix beats substring", Fuzzy.score("fire", "firefox") > Fuzzy.score("fox", "firefox"));
        ok("boundary beats mid-word", Fuzzy.score("code", "visual studio code") > Fuzzy.score("ode", "visual studio code"));
        ok("subsequence matches", Fuzzy.score("ffx", "firefox") > 0);
        eq("non-match is zero", Fuzzy.score("xyz", "firefox"), 0);
        eq("empty needle matches", Fuzzy.score("", "anything"), 1);
        ok("tighter subsequence wins", Fuzzy.score("term", "terminal") > Fuzzy.score("term", "the remote manager"));
        ok("best uses weights", Fuzzy.best("web", ["firefox", "web browser"], [1, 0.5]) > 0);
    }

    function testAtlas() {
        let s = M.empty();
        eq("empty has one collection", s.collections.length, 1);
        M.seed(s, [1, 2, 3, 7]);
        eq("seed places ws1 at A1", s.collections[0].cells["0,0"].ref, "id:1");
        eq("seed places ws7 at G1", s.collections[0].cells["6,0"].ref, "id:7");
        eq("locate finds", M.locate(s, "id:3"), { collection: "c1", x: 2, y: 0 });
        eq("locate misses", M.locate(s, "id:99"), null);
        eq("free id skips bound and live", M.freeNumericId(s, [4]), 5);
        eq("free id honours minimum", M.freeNumericId(s, [], 11), 11);
        eq("row 1 of first collection mirrors ws numbers", M.idForCell(s, "c1", 4, 0, []), 5);
        eq("taken row-1 id falls back to 11+", M.idForCell(s, "c1", 2, 0, []), 11);
        eq("other rows use 11+", M.idForCell(s, "c1", 0, 3, []), 11);
        eq("other collections use 11+", M.idForCell(s, "c9", 0, 0, []), 11);

        M.bind(s, "c1", 0, 1, "id:2");
        eq("rebind moves the ref", M.locate(s, "id:2"), { collection: "c1", x: 0, y: 1 });
        ok("old cell released", !s.collections[0].cells["1,0"]);

        eq("first free in row", M.firstFreeInRow(s.collections[0], 0), { x: 1, y: 0 });
        const b = M.bounds(s.collections[0], 1);
        eq("bounds padded", [b.minX, b.maxX, b.minY, b.maxY], [-1, 7, -1, 2]);

        eq("labels A1", M.coordLabel(0, 0), "A1");
        eq("labels AA", M.columnLabel(26), "AA");
        eq("labels negative", M.coordLabel(-1, -2), "−B−2");

        const ps = M.empty(); M.seed(ps, [1]); ps.collections[0].cursor = { x: 4, y: 2 };
        eq("placement: numbered ws to row 1", M.placementFor(ps, "id:7"), { collection: "c1", x: 6, y: 0 });
        eq("placement: high id at cursor", M.placementFor(ps, "id:42"), { collection: "c1", x: 4, y: 2 });
        M.bind(ps, "c1", 4, 2, "id:42");
        eq("placement: occupied cursor -> row", M.placementFor(ps, "id:43"), { collection: "c1", x: 0, y: 2 });
        eq("placement: taken row-1 cell falls back", M.placementFor(ps, "id:1"), { collection: "c1", x: 0, y: 2 });

        const id2 = M.nextCollectionId(s);
        eq("next collection id", id2, "c2");

        // Sanitize repairs instead of discarding.
        const dirty = { active: "zzz", collections: [{ id: "c1", name: "", cells: { "1,1": { ref: "id:4", name: "Mail" }, "bad": {}, "2,2": { ref: 5 } }, cursor: { x: "a" } }, null] };
        const clean = M.sanitize(dirty);
        eq("sanitize keeps good cell", clean.collections[0].cells["1,1"], { ref: "id:4", name: "Mail" });
        ok("sanitize drops bad key", !clean.collections[0].cells["bad"]);
        ok("sanitize drops bad ref", !clean.collections[0].cells["2,2"]);
        eq("sanitize fixes cursor", clean.collections[0].cursor, { x: 0, y: 0 });
        eq("sanitize fixes active", clean.active, "c1");
        eq("sanitize garbage -> empty", M.sanitize("nope").collections.length, 1);
        const dup = M.sanitize({ collections: [{ id: "c1", cells: {} }, { id: "c1", cells: {} }] });
        ok("sanitize dedupes ids", dup.collections[0].id !== dup.collections[1].id);
    }

    function testFmt() {
        eq("percent clamps", Fmt.percent(1.4), "100%");
        eq("duration h/m", Fmt.duration(3720), "1h 02m");
        eq("duration none", Fmt.duration(0), "");
        eq("media time", Fmt.mediaTime(125), "2:05");
        eq("bytes", Fmt.bytes(5 * 1024 * 1024 * 1024), "5.0 GiB");
        eq("plain strips markup", Fmt.plain("<b>Hi</b> &amp; bye"), "Hi & bye");
        eq("roman", Fmt.roman(4), "IV");
    }

    function testPalette() {
        // Text on plate must meet WCAG AA (4.5:1) on both grounds.
        for (const g of ["obsidian", "vellum"]) {
            const gr = P.grounds[g];
            ok(g + ": text/plate >= 7", P.contrast(gr.text, gr.plate) >= 7);
            ok(g + ": textDim/plate >= 4.5", P.contrast(gr.textDim, gr.plate) >= 4.5);
            ok(g + ": textFaint/plate >= 3", P.contrast(gr.textFaint, gr.plate) >= 3);
            for (const a in P.accents) {
                const hex = P.accent(a, g === "obsidian");
                ok(g + ": accent " + a + "/plate >= 3", P.contrast(hex, gr.plate) >= 3);
            }
        }
    }

    function testIcons() {
        for (const k in Icons.p) {
            const d = Icons.p[k];
            ok("icon " + k + " starts with M", d.charAt(0) === "M");
            ok("icon " + k + " uses only path syntax", /^[MLHVACZ0-9 .\-]+$/.test(d));
        }
    }

    function testKeybinds() {
        const sc = Schema.defaults().shortcuts;
        const h = KB.hyprland(sc);
        ok("hyprland: lens bind", h.indexOf("bind = SUPER, SPACE, exec, ssh-shell lens toggle") >= 0);
        ok("hyprland: traverse bind", h.indexOf("bind = SUPER ALT, left, exec, ssh-shell atlas traverse left") >= 0);
        const n = KB.niri(sc);
        ok("niri: lens bind", n.indexOf("Mod+Space { spawn \"ssh-shell\" \"lens\" \"toggle\"; }") >= 0);
        ok("niri: carry bind", n.indexOf("Mod+Alt+Shift+Left { spawn \"ssh-shell\" \"atlas\" \"carry\" \"left\"; }") >= 0);
        const hl = KB.hyprlandLua(sc);
        ok("hyprland lua: autostart", hl.indexOf('hl.on("hyprland.start", function () hl.exec_cmd("ssh-shell --daemon") end)') >= 0);
        ok("hyprland lua: lens bind", hl.indexOf('hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("ssh-shell lens toggle"))') >= 0);
        ok("hyprland lua: traverse bind", hl.indexOf('hl.bind("SUPER + ALT + left", hl.dsp.exec_cmd("ssh-shell atlas traverse left"))') >= 0);
        ok("hyprland lua: media flags", hl.indexOf('"ssh-shell audio up"), { locked = true, repeating = true })') >= 0);
        eq("generate dispatches", KB.generate("niri", sc), n);
        ok("niri: balanced braces", (n.match(/\{/g) || []).length === (n.match(/\}/g) || []).length);

        // Session (runtime) binds
        const sp = KB.specs(sc);
        eq("specs: 5 actions + 8 arrows + 6 media", sp.length, 19);
        eq("mask: SUPER", KB.hyprMask("SUPER"), 64);
        eq("mask: SUPER SHIFT", KB.hyprMask("SUPER SHIFT"), 65);
        eq("mask: SUPER ALT SHIFT", KB.hyprMask("SUPER ALT SHIFT"), 73);
        eq("mask: lower case and CTRL", KB.hyprMask("ctrl alt"), 12);
        eq("mask: none", KB.hyprMask(""), 0);
        const taken = [{ modmask: 64, key: "SPACE", submap: "" }, { modmask: 0, key: "XF86AudioRaiseVolume", submap: "" },
                       { modmask: 64, key: "D", submap: "resize" }];
        const p = KB.partition(sp, taken);
        eq("partition: user's SUPER+SPACE and volume key are kept", p.skipped.map(b => b.key), ["SPACE", "XF86AudioRaiseVolume"]);
        eq("partition: a bind inside a submap does not block", p.free.some(b => b.key === "D"), true);
        eq("partition: counts add up", p.free.length + p.skipped.length, sp.length);
        eq("lua bind", KB.hyprlandLuaBind(sp[0]), 'hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("ssh-shell lens toggle"))');
        eq("lua unbind", KB.hyprlandLuaUnbind(sp[0]), 'hl.unbind("SUPER + SPACE")');
        eq("classic keyword", KB.hyprlandKeyword(sp[0]), "keyword bind SUPER, SPACE, exec, ssh-shell lens toggle");
        eq("classic media keyword", KB.hyprlandKeyword(sp[13]), "keyword bindel , XF86AudioRaiseVolume, exec, ssh-shell audio up");
        eq("classic unbind", KB.hyprlandUnkeyword(sp[0]), "keyword unbind SUPER, SPACE");
        eq("session.keybinds default on", Schema.defaults().session.keybinds, true);
    }

    function testIntents() {
        const r = Intents.commands("lock");
        ok("command found", r.length > 0 && r[0].payload === "lock");
        const w = Intents.windows("fire", [{ id: "0x1", title: "Mozilla Firefox", appId: "firefox", workspaceRef: "id:1" }], ref => "A1");
        eq("window intent", w.length, 1);
        const s = M.empty(); s.collections[0].cells["2,1"] = { ref: "id:3", name: "Studio" };
        const c = Intents.cells("stu", s, M.coordLabel);
        eq("cell intent payload", c[0].payload, { collection: "c1", x: 2, y: 1 });
    }

    // Quit is only wired up after the config finishes loading.
    Timer { id: quitTimer; interval: 50; onTriggered: Qt.quit() }

    Component.onCompleted: {
        const suites = [testSchema, testFuzzy, testAtlas, testFmt, testPalette, testIcons, testKeybinds, testIntents];
        for (const t of suites) {
            try { t(); } catch (e) { failures.push(t.name + " threw: " + e); }
        }
        for (const f of failures) console.warn("FAIL " + f);
        console.info("RESULT " + passed + " passed, " + failures.length + " failed");
        quitTimer.start(); // Quickshell does not route Qt.exit(); scripts/test.sh reads RESULT
    }
}
