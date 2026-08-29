"""Copia deploy/htaccess in site/.htaccess alla fine di ogni build.

MkDocs esclude dalla build i file che iniziano con un punto, quindi la
politica di cache non può stare dentro docs/: la teniamo in
deploy/htaccess e la copiamo a mano nell'output, così finisce sul server
insieme al resto del sito e non va persa a ogni caricamento.
"""

import logging
import shutil
from pathlib import Path

log = logging.getLogger("mkdocs.hooks.htaccess")

SORGENTE = Path(__file__).parent.parent / "deploy" / "htaccess"


def on_post_build(config, **kwargs):
    if not SORGENTE.is_file():
        log.error(
            "%s non trovato: il sito verrà pubblicato senza politica di cache "
            "e gli utenti continueranno a vedere le pagine vecchie.",
            SORGENTE,
        )
        return
    shutil.copyfile(SORGENTE, Path(config["site_dir"]) / ".htaccess")
