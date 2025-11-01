#!/bin/bash
# Script pour lancer DocStrange Web avec Cloudflared Tunnel

set -e

echo "🚀 Démarrage de DocStrange Web avec tunnel public..."

# Vérifier si on est dans le bon répertoire
if [ ! -f "docstrange/web_app.py" ]; then
    echo "❌ Erreur: docstrange/web_app.py non trouvé"
    echo "💡 Exécute ce script depuis la racine du projet OCRDOT"
    exit 1
fi

# Installer Flask si nécessaire
echo "📦 Vérification de Flask..."
if ! python3 -c "import flask" 2>/dev/null; then
    echo "Installation de Flask..."
    pip install Flask
fi

# Installer cloudflared si nécessaire
if ! command -v cloudflared &> /dev/null; then
    echo "📥 Installation de cloudflared..."

    # Détecter l'architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    else
        echo "❌ Architecture non supportée: $ARCH"
        exit 1
    fi

    curl -L --output cloudflared "$CLOUDFLARED_URL"
    chmod +x cloudflared
    sudo mv cloudflared /usr/local/bin/ || mv cloudflared ~/.local/bin/
    echo "✅ cloudflared installé"
fi

# Lancer l'application web en arrière-plan
echo "🌐 Démarrage du serveur web..."
python3 -m docstrange.web_app &
WEB_PID=$!

# Attendre que le serveur démarre
echo "⏳ Attente du démarrage du serveur..."
sleep 5

# Vérifier que le serveur est bien démarré
if ! kill -0 $WEB_PID 2>/dev/null; then
    echo "❌ Erreur: Le serveur web n'a pas démarré correctement"
    exit 1
fi

echo ""
echo "✅ Serveur web démarré (PID: $WEB_PID)"
echo "🌍 Création du tunnel public avec cloudflared..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Lancer cloudflared tunnel
cloudflared tunnel --url http://localhost:8000

# Cleanup quand on arrête le script (Ctrl+C)
trap "echo '\n🛑 Arrêt du serveur...'; kill $WEB_PID 2>/dev/null; exit 0" INT TERM
