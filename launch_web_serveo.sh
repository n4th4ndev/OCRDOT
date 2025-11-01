#!/bin/bash
# Script pour lancer DocStrange Web avec Serveo (le plus simple!)

set -e

echo "🚀 Démarrage de DocStrange Web avec Serveo..."
echo "   (Aucune installation requise!)"
echo ""

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
echo "🌍 Création du tunnel public avec Serveo..."
echo "   (Peut demander de confirmer la connexion SSH)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Lancer serveo tunnel via SSH
ssh -R 80:localhost:8000 serveo.net

# Cleanup quand on arrête le script (Ctrl+C)
trap "echo '\n🛑 Arrêt du serveur...'; kill $WEB_PID 2>/dev/null; exit 0" INT TERM
