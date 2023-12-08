
applyTheme();


function applyTheme() {
    // check current theme
    var themeMode = localStorage.getItem('theme-mode');
    if(themeMode === null) themeMode = "auto";
    
    var useTheme = "light";
    if(themeMode === "auto") {
        useTheme = (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
    } else if(themeMode === "dark") {
        useTheme = "dark";
    }
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