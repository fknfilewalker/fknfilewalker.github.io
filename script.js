applyTheme();

function toGiscusTheme(theme) {
    if (theme === "auto") {
        return (window.matchMedia("(prefers-color-scheme: dark)").matches ? "transparent_dark" : "light");
    } else if (theme === "dark") {
        return "transparent_dark";
    }
    return "light";
}

function applyTheme() {
    // check current theme
    var themeMode = localStorage.getItem('theme-mode');
    if (themeMode === null) themeMode = "auto";

    var useTheme = "light";
    if (themeMode === "auto") {
        useTheme = (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
    } else if (themeMode === "dark") {
        useTheme = "dark";
    }

    // giscus
    function sendMessage(message) {
        const iframe = document.querySelector('iframe.giscus-frame');
        if (!iframe) return;
        iframe.contentWindow.postMessage({ giscus: message }, 'https://giscus.app');
    }
    sendMessage({ setConfig: { theme: toGiscusTheme(themeMode) } });

    // rest
    document.documentElement.setAttribute('theme-style', useTheme)
    document.documentElement.setAttribute('theme-mode', themeMode)
    localStorage.setItem('theme-mode', themeMode);
};

function changeTheme() {
    var themeMode = localStorage.getItem('theme-mode');
    if (themeMode === "light") {
        themeMode = "dark";
    } else if (themeMode === "dark") {
        themeMode = "auto";
    } else if (themeMode === "auto") {
        themeMode = "light";
    }
    localStorage.setItem('theme-mode', themeMode);
    applyTheme();

};

window.onload = (event) => {
    window.matchMedia("(prefers-color-scheme: light)").addEventListener("change", e => e.matches && applyTheme());
    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", e => e.matches && applyTheme());
};