# Dati di collegamento al server. Copia questo file in deploy/config.sh
# e compilalo: config.sh è escluso da git, quindi non finisce su GitHub.
#
# Sono gli stessi dati che usi in FileZilla.

# Utente FTP (Account FTP di cPanel)
UTENTE_REMOTO="utente_ftp"

# Host FTP: lo stesso che hai in FileZilla
HOST_REMOTO="ftp.isiaurbino.net"

# Cartella del sito sul server, SENZA barra finale.
# In FileZilla è il percorso remoto in cui entri per caricare il sito.
# Conferma in cPanel -> Domini -> colonna "Document Root".
PERCORSO_REMOTO="public_html/guide"

# Indirizzo pubblico del sito, usato per la verifica finale
URL_SITO="https://guide.isiaurbino.net"

# La password NON si scrive qui: te la chiede lo script a ogni esecuzione.
