# 🌐 Lancer DocStrange Web avec Tunnel Public

Trois méthodes pour exposer l'interface web DocStrange publiquement :

## 🚀 Méthode 1 : Serveo (LE PLUS SIMPLE !)

**Aucune installation requise**, utilise juste SSH :

```bash
./launch_web_serveo.sh
```

✅ **Avantages** : Aucune inscription, marche immédiatement
❌ **Inconvénients** : URL aléatoire à chaque démarrage

---

## 🔥 Méthode 2 : ngrok (RECOMMANDÉ)

**Nécessite une inscription gratuite** sur [ngrok.com](https://ngrok.com)

```bash
./launch_web_ngrok.sh
```

**Configuration requise :**
1. Va sur https://dashboard.ngrok.com/get-started/your-authtoken
2. Copie ton authtoken
3. Exécute : `ngrok config add-authtoken <ton_token>`

✅ **Avantages** : Interface web pour voir les requêtes, stable
❌ **Inconvénients** : Nécessite un compte gratuit

---

## ⚡ Méthode 3 : Cloudflared

**Cloudflare Tunnel**, pas d'inscription nécessaire :

```bash
./launch_web_tunnel.sh
```

✅ **Avantages** : Rapide, pas de compte requis, Cloudflare CDN
❌ **Inconvénients** : URL aléatoire

---

## 📝 Utilisation Manuelle

Si tu préfères lancer manuellement :

```bash
# 1. Installer Flask
pip install Flask

# 2. Lancer l'app web
python3 -m docstrange.web_app &

# 3. Créer le tunnel (choisis une méthode)

# Option A : Serveo (le plus simple)
ssh -R 80:localhost:8000 serveo.net

# Option B : ngrok
ngrok http 8000

# Option C : Cloudflared
cloudflared tunnel --url http://localhost:8000
```

---

## 🛑 Arrêter les Serveurs

Pour tous les scripts, appuie sur **Ctrl+C** pour arrêter proprement.

Pour tuer manuellement le serveur web si besoin :

```bash
pkill -f "python.*web_app"
```

---

## 🎯 Résumé Rapide

| Méthode | Installation | Compte Requis | Stabilité | Recommandation |
|---------|--------------|---------------|-----------|----------------|
| **Serveo** | ❌ Aucune | ❌ Non | ⭐⭐⭐ | **Pour tester vite** |
| **ngrok** | ✅ Simple | ✅ Gratuit | ⭐⭐⭐⭐⭐ | **Pour utilisation régulière** |
| **Cloudflared** | ✅ Binaire | ❌ Non | ⭐⭐⭐⭐ | **Alternative solide** |

**Mon conseil** : Commence avec **Serveo** pour tester, puis passe à **ngrok** si tu veux quelque chose de plus stable.
