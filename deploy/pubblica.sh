#!/usr/bin/env bash
#
# Pubblica il sito su Bluehost sincronizzando site/ con il server, via FTP.
#
# Differenza rispetto al caricamento con FileZilla: questa procedura
# CANCELLA dal server i file che non esistono più nel repository. È il
# motivo per cui esiste: senza, le pagine e i moduli ritirati restano
# online per sempre.
#
# Richiede lftp:  sudo pacman -S lftp
#
# Prima esecuzione:
#   cp deploy/config.esempio.sh deploy/config.sh   e compila config.sh
#
# Uso:
#   ./deploy/pubblica.sh            mostra cosa farebbe, non tocca nulla
#   ./deploy/pubblica.sh --esegui   esegue davvero

set -euo pipefail

RADICE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RADICE"

ESEGUI=no
[[ "${1:-}" == "--esegui" ]] && ESEGUI=si

command -v lftp >/dev/null || {
    echo "lftp non è installato. Installalo con:  sudo pacman -S lftp"
    exit 1
}

# ── Configurazione ───────────────────────────────────────────────────
if [[ ! -f deploy/config.sh ]]; then
    echo "Manca deploy/config.sh."
    echo "Crealo con:  cp deploy/config.esempio.sh deploy/config.sh"
    exit 1
fi
# shellcheck source=/dev/null
source deploy/config.sh

for v in UTENTE_REMOTO HOST_REMOTO PERCORSO_REMOTO URL_SITO; do
    [[ -n "${!v:-}" ]] || { echo "In deploy/config.sh manca $v"; exit 1; }
done

# Rete di sicurezza: una cancellazione puntata sulla cartella sbagliata
# fa danni seri.
case "$PERCORSO_REMOTO" in
    ""|/|"~"|"~/"|*public_html|*public_html/)
        echo "PERCORSO_REMOTO ('$PERCORSO_REMOTO') è troppo generico."
        echo "Deve puntare alla cartella del singolo sottodominio."
        exit 1 ;;
esac

# ── 1. Build ─────────────────────────────────────────────────────────
echo "▸ Ricostruisco il sito"
PY=.venv/bin/python
[[ -x $PY ]] || PY=venv/bin/python
[[ -x $PY ]] || PY=$(command -v python3)
"$PY" -m mkdocs build --clean --quiet

[[ -f site/.htaccess ]]  || { echo "site/.htaccess non generato: mi fermo."; exit 1; }
[[ -f site/index.html ]] || { echo "site/index.html assente: build incompleta."; exit 1; }
echo "▸ Build ok ($(find site -type f | wc -l) file, .htaccess incluso)"

# ── 2. Password ──────────────────────────────────────────────────────
# Non viene salvata da nessuna parte: resta in memoria per la durata
# dell'esecuzione. Per automatizzare: PASSWORD_FTP=... ./deploy/pubblica.sh
if [[ -z "${PASSWORD_FTP:-}" ]]; then
    read -rsp "Password FTP di $UTENTE_REMOTO: " PASSWORD_FTP
    echo
fi

# ── 3. Impostazioni della connessione ────────────────────────────────
# ssl-force: la connessione è cifrata (FTPS), come in FileZilla.
# verify-certificate no: sull'hosting condiviso il certificato FTP è
#   intestato al server Bluehost e non al tuo dominio, quindi la verifica
#   fallirebbe sempre. Le credenziali restano cifrate in transito.
PRELUDIO="set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:verify-certificate no
set cmd:fail-exit true
set net:max-retries 3"

# .well-known serve ai certificati SSL: se sparisse si romperebbe il
# rinnovo di HTTPS. cgi-bin e i log sono di cPanel, non li produce MkDocs.
ESCLUSIONI="--exclude ^\.well-known/ --exclude ^cgi-bin/ --exclude ^error_log\$ --exclude ^\.htpasswd\$"

# I comandi arrivano a lftp dallo standard input e non come argomenti:
# così la password non compare nell'elenco dei processi (ps).
esegui_lftp () {
    lftp <<LFTP
$PRELUDIO
open -u "$UTENTE_REMOTO","$PASSWORD_FTP" ftp://$HOST_REMOTO
$1
bye
LFTP
}

# ── 4. Conferma di puntare al sito giusto ────────────────────────────
# Non basta il codice di uscita: si controlla che il file sia elencato.
if [[ -z "$(esegui_lftp "cls -1 '$PERCORSO_REMOTO/index.html'" 2>/dev/null || true)" ]]; then
    echo "Su $PERCORSO_REMOTO non trovo index.html."
    echo "Il percorso è sbagliato, oppure le credenziali non sono corrette."
    exit 1
fi

# ── 5. Sincronizzazione ──────────────────────────────────────────────
# -R = dal locale al remoto. --delete rimuove dal server ciò che non
# esiste più in site/. Vengono ricaricati tutti i file a ogni build:
# sono poche centinaia di kB, e garantisce che il server sia identico.
MIRROR="mirror -R --delete --parallel=4 $ESCLUSIONI"

if [[ $ESEGUI == no ]]; then
    echo
    echo "▸ ANTEPRIMA — non viene modificato nulla sul server"
    echo "  Cerca le righe 'rm' e 'rmdir': sono i file che verrebbero rimossi."
    echo
    esegui_lftp "$MIRROR --dry-run --verbose site/ '$PERCORSO_REMOTO/'"
    echo
    echo "Se l'elenco ti convince:  ./deploy/pubblica.sh --esegui"
    exit 0
fi

echo "▸ Pubblico su $URL_SITO"
esegui_lftp "$MIRROR --verbose site/ '$PERCORSO_REMOTO/'"

# ── 6. Verifica dal punto di vista dell'utente ───────────────────────
echo
echo "▸ Verifica"
CC=$(curl -sI --max-time 20 "$URL_SITO/" | grep -i '^cache-control:' || true)
if [[ -n $CC ]]; then
    echo "  ✓ ${CC%$'\r'}"
else
    echo "  ✗ nessun header Cache-Control: l'.htaccess non è attivo."
    echo "    Verifica che mod_headers sia abilitato sul piano Bluehost."
fi
echo "  ✓ home: $(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$URL_SITO/")"
