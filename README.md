A project for generating my cvs both in Spanish and English.

Folder Structure:


app/
|-- data/
|   |-- aboutMe-en.json
|   |-- aboutMe-es.json
|-- templates/
|   |-- template-en.cv
|   |-- template-es.cv
|-- build-cv.sh



The image uses jq to parse values from JSON into the LaTeX templates.
During parsing, a temporary folder to hold temporary files is created in /output/tmp
During pdf generation (pdflatex) auxiliary files are created in /app/output/ inside the container.
After successful generation, such auxiliary files are deleted.
The PDF generated can be found in ./output (relative to this file location) folder, as per the volume mounted in compose.yml.
