# REPORT

## Installation
### Windows
1. Install **TeX Live**. When the installer opens, choose **Custom Install**, then deselect language collections you do not need (like Cyrillic or Arabic). Ensure "Add to PATH" is checked.
2. Install [Strawberry Pearl](https://strawberryperl.com/).
3. In VS Code, install **LaTeX Workshop** (James Yu).
4. In VS Code, configure the `settings.json` file.
    * Press `Ctrl + Shift + P`.
    * Type "Open User Settings (JSON)" and click it.
    * Add (or merge) these specific lines into your JSON file:
    ```json
    {
        // 1. Set the default tool to latexmk (which TeX Live loves)
        "latex-workshop.latex.recipe.default": "lastUsed",

        // 2. Tell VS Code to compile every time you save (Ctrl+S)
        "latex-workshop.latex.autoBuild.run": "onSave",

        // 3. Make the PDF appear inside a VS Code tab (best for single monitor)
        "latex-workshop.view.pdf.viewer": "tab",

        // 4. Clean up auxiliary files (.aux, .log, .out) after a successful build
        "latex-workshop.latex.autoClean.run": "onBuilt",

        // 5. Ensure the extension can find your TeX Live tools
        "latex-workshop.latex.tools": [
            {
                "name": "latexmk",
                "command": "latexmk",
                "args": [
                    "-synctex=1",
                    "-interaction=nonstopmode",
                    "-file-line-error",
                    "-pdf",
                    "-outdir=%OUTDIR%",
                    "%DOC%"
                ],
                "env": {}
            }
        ]
    }
    ```

## Run
1. Open `.tex` file.
2. Press `Ctrl + S`.