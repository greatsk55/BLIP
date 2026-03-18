# Journal des modifications

Toutes les modifications importantes de BLIP sont documentées ici.

📋 Autres langues : [English](../CHANGELOG.md) | [한국어](CHANGELOG.ko.md) | [日本語](CHANGELOG.ja.md) | [中文](CHANGELOG.zh.md) | [Español](CHANGELOG.es.md)

---

## v1.7.0 — Transfert universel de fichiers

- **Support de tous les types de fichiers** : Envoyez des PDFs, documents, archives, fichiers de code et plus
- **Icônes intelligentes** : Sélection automatique d'icônes selon l'extension du fichier
- **Validation de la taille** : Limites par type (images 50 Mo, vidéos 100 Mo, fichiers 200 Mo)
- **Bouton de téléchargement** : Téléchargement en un clic pour les fichiers reçus
- **Progression du transfert** : Indicateur de progression en temps réel
- **Chiffrement de bout en bout** : Tous les fichiers chiffrés avec le même E2E que les messages

## v1.6.0 — Chat de groupe

- **Salons de groupe** : Créez des salons de chat de groupe sans limite de participants
- **Contrôles administrateur** : Verrouillage, expulsion, bannissement et destruction du salon
- **Jeton administrateur** : Authentification séparée pour la gestion du salon
- **Barre latérale des participants** : Liste des participants en temps réel avec indicateurs d'administrateur
- **Liens de partage** : Générez des liens d'invitation avec mot de passe intégré optionnel
- **Expiration en 24 heures** : Les salons de groupe expirent automatiquement après 24 heures

## v1.5.0 — Widget de chat intégrable

- **Guide d'intégration** : Guide étape par étape pour intégrer le chat BLIP sur n'importe quel site web
- **Personnalisation du widget** : Apparence et comportement configurables
- **Support cross-origin** : Intégration iframe sécurisée avec les en-têtes CSP appropriés

## v1.4.0 — Système de codes d'invitation communautaires

- **Codes d'invitation** : Générez et partagez des codes d'invitation pour les communautés
- **Tableau communautaire** : Tableau public pour les discussions communautaires
- **Limitation de débit** : Protection contre le spam et les abus

## v1.3.0 — Application mobile et stabilité

- **Optimisation mobile** : Design entièrement responsive et support PWA
- **Gestion du viewport visuel** : Comportement correct du clavier sur les appareils mobiles
- **Améliorations de performance** : Rendu et utilisation mémoire optimisés

## v1.2.0 — Transfert de médias chiffrés

- **Transfert d'images** : Envoi et réception d'images avec chiffrement E2E
- **Transfert vidéo** : Partage de vidéos chiffrées avec miniatures
- **Transfert par fragments** : Gros fichiers découpés en fragments pour une livraison fiable
- **Vérification de checksum** : Vérification d'intégrité SHA-256 pour tous les transferts

## v1.1.0 — Destruction instantanée de salons et notifications

- **Destruction de salons** : Détruisez instantanément les salons de chat une fois terminé
- **Notifications navigateur** : Soyez notifié à l'arrivée des messages
- **Détection de capture d'écran** : Alerte lorsqu'une capture d'écran est détectée
- **Confirmation de départ** : Confirmez avant de quitter un salon de chat

## v1.0.0 — Version initiale

- **Chiffrement de bout en bout** : Échange de clés X25519 + chiffrement XSalsa20-Poly1305
- **Salons éphémères** : Aucun stockage de messages, les salons expirent automatiquement
- **Accès par mot de passe** : Accès sécurisé aux salons avec des mots de passe générés
- **Messagerie en temps réel** : Messagerie instantanée WebSocket via Supabase Realtime
- **Architecture à connaissance zéro** : Le serveur ne voit jamais les messages en clair
- **Support multilingue** : Anglais, coréen, japonais, chinois, espagnol, français
