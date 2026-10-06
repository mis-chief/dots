pragma Singleton
import Quickshell

Singleton {
    function score(e, q) {
        const name = e.name.toLowerCase()
        if (name.startsWith(q)) return 3
        if (name.includes(q)) return 2
        if ((e.genericName ?? "").toLowerCase().includes(q)) return 1
        if ((e.comment ?? "").toLowerCase().includes(q)) return 1
        return 0
    }

    function search(query) {
        const q = query.toLowerCase().trim()
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
        if (q === "") return apps.sort((a, b) => a.name.localeCompare(b.name))
        return apps
            .map(e => ({ e: e, s: score(e, q) }))
            .filter(x => x.s > 0)
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .map(x => x.e)
    }
}
