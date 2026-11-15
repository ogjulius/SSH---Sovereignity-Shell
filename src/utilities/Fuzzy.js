.pragma library
// Small, allocation-conscious fuzzy matcher used by the launcher and the
// Lens intent line. Scores favour, in order: exact prefix, word-boundary
// prefix, contiguous substring, then ordered subsequence. Returns 0 for no
// match. Inputs are expected to be lower-cased by the caller (cache them).

function score(needle, hay) {
    if (needle.length === 0) return 1;
    if (hay.length === 0) return 0;
    if (hay.indexOf(needle) === 0) return 1000 - hay.length;
    var at = hay.indexOf(needle);
    if (at > 0) {
        var prev = hay.charCodeAt(at - 1);
        // space - _ . / (
        var boundary = prev === 32 || prev === 45 || prev === 95 || prev === 46 || prev === 47 || prev === 40;
        return (boundary ? 800 : 600) - at - hay.length * 0.1;
    }
    // ordered subsequence with gap penalty
    var hi = 0, gaps = 0, last = -1, streak = 0, best = 0;
    for (var ni = 0; ni < needle.length; ni++) {
        var c = needle.charCodeAt(ni);
        var found = -1;
        while (hi < hay.length) {
            if (hay.charCodeAt(hi) === c) { found = hi; hi++; break; }
            hi++;
        }
        if (found < 0) return 0;
        if (last >= 0 && found !== last + 1) { gaps += found - last - 1; streak = 0; }
        else { streak++; if (streak > best) best = streak; }
        last = found;
    }
    var s = 300 - gaps * 4 + best * 6 - hay.length * 0.1;
    return s > 1 ? s : 1;
}

// Best score of a needle over several fields with weights.
function best(needle, fields, weights) {
    var top = 0;
    for (var i = 0; i < fields.length; i++) {
        if (!fields[i]) continue;
        var s = score(needle, fields[i]) * (weights ? weights[i] : 1);
        if (s > top) top = s;
    }
    return top;
}
