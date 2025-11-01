#!/bin/bash
# Script pour lancer DocStrange Web avec ngrok

set -e

echo "🚀 Démarrage de DocStrange Web avec ngrok..."

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

# Installer ngrok si nécessaire
if ! command -v ngrok &> /dev/null; then
    echo "📥 Installation de ngrok..."

    # Télécharger ngrok
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
        sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
        sudo tee /etc/apt/sources.list.d/ngrok.list
    sudo apt update && sudo apt install ngrok -y

    echo "✅ ngrok installé"
    echo ""
    echo "⚠️  IMPORTANT: Configure ton authtoken ngrok:"
    echo "   1. Va sur https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "   2. Copie ton authtoken"
    echo "   3. Exécute: ngrok config add-authtoken <ton_token>"
    echo ""
    read -p "Appuie sur ENTER une fois que c'est fait..."
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
echo "🌍 Création du tunnel public avec ngrok..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Lancer ngrok tunnel
ngrok http 8000

# Cleanup quand on arrête le script (Ctrl+C)
trap "echo '\n🛑 Arrêt du serveur...'; kill $WEB_PID 2>/dev/null; exit 0" INT TERM
