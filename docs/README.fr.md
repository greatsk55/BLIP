# BLIP

**Parlez. Puis disparaissez.**

🌐 [한국어](README.ko.md) | [English](../README.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](README.es.md) | [Français](#)

---

BLIP est un service de chat éphémère qui ne laisse aucune trace.
Pas de comptes. Pas d'historique. Pas de profils. Commencez avec un seul lien, et quand c'est fini, tout disparaît.

> « Cette conversation n'a pas besoin d'être sauvegardée. » — Conçu exactement pour ces moments-là.

---

## Pourquoi BLIP ?

Tous les messagers actuels conservent trop de choses. Comptes, listes d'amis, historique de chat, notifications...
Mais la plupart des conversations dans la vie ne sont que des **échanges rapides qui n'ont pas besoin de durer**.

| Messagers traditionnels | BLIP |
|---|---|
| Compte requis | Aucun compte |
| Historique stocké indéfiniment | Zéro historique — irrécupérable |
| Ajout d'amis nécessaire | Rejoignez instantanément via un lien |
| Données stockées sur les serveurs | Aucun stockage serveur, chiffrement E2E |

## Concept central

- **Zéro préparation** — Démarrez instantanément avec un seul lien
- **Zéro persistance** — Irrécupérable après la fin
- **Zéro identité** — Pas de comptes, d'amis ni de profils
- **100% basé sur le consentement** — N'existe que tant que tous les participants sont d'accord
- **Auto-destruction** — Seuls les derniers messages restent visibles ; les anciens sont détruits en temps réel
- **Protection contre les captures** — Détecte les tentatives de capture d'écran et d'enregistrement, floutant instantanément les messages

## Comment ça marche

```
1. Créer un salon  →  Un seul bouton
2. Partager        →  Envoyez le lien à n'importe qui
3. Discuter        →  Messagerie en temps réel chiffrée E2E
4. Terminer        →  Toutes les données détruites instantanément
```

## Cas d'utilisation

- « Discussion rapide, puis détruire le salon »
- « Réunion stratégique, puis effacer toutes les traces »
- « Un lien, rassemblement instantané »
- Coordination de parties de jeu, communication événementielle, conversations sensibles ponctuelles

## Philosophie

BLIP n'est pas un messager.
C'est un **outil de communication jetable**.

Il n'existe pas pour retenir les gens.
Il existe pour éliminer les frictions, parler et disparaître.

### Ce que nous ne faisons PAS

Ce service ne fait intentionnellement **PAS** ce qui suit :

- ~~Demandes d'amis~~
- ~~Historique de chat~~
- ~~Profils utilisateurs~~
- ~~Archives de conversations~~
- ~~Fonctionnalités sociales~~

> Nous ne sacrifions jamais la philosophie pour la commodité.

## Stack technique

- Communication en temps réel basée sur WebSocket
- Chiffrement de bout en bout (E2E — Curve25519 ECDH + XSalsa20-Poly1305)
- Le serveur n'agit que comme relais
- À la fermeture du salon : irrécupérable côté serveur et client
- Auto-destruction : les messages hors de la fenêtre visible sont supprimés instantanément avec libération des blob URL
- Protection contre les captures : détection de changement d'onglet, raccourcis clavier et menu contextuel pour flouter les messages

## BLIP me — Lien de contact jetable

Partagez un seul lien sur votre profil. Quand quelqu'un clique, un chat chiffré 1:1 démarre instantanément — sans compte, sans demande d'ami.

- **Votre propre lien** — Créez une URL unique (ex : `blip.me/yourname`)
- **Alerte en temps réel** — Soyez notifié dès qu'un visiteur se connecte
- **Gestion du lien** — Modifiez ou supprimez votre URL à tout moment
- **Sans compte requis** — Un jeton basé sur l'appareil prouve la propriété
- Visitez `/blipme` sur le web, ou appuyez sur l'onglet **BLIP me** sur mobile

## Mes Salons

Les salons récemment créés ou rejoints sont sauvegardés localement — aucun stockage serveur.

- **Sauvegarde automatique**: les salons sont stockés dans localStorage (web) ou SecureStorage (mobile)
- **Reconnexion en un clic**: le mot de passe sauvegardé permet de rejoindre sans le retaper
- **Persistance admin**: les jetons d'administrateur de groupe sont sauvegardés pour maintenir les privilèges
- **Liste unifiée**: discussions 1:1 et de groupe en un seul endroit
- Visitez `/my-rooms` sur le web, ou appuyez sur l'onglet **Chat** sur mobile

> Les mots de passe et jetons admin ne quittent jamais votre appareil. Effacer les données du navigateur les supprime définitivement.

## Intégration

Ajoutez le chat BLIP à n'importe quel site web avec un simple iframe :

```html
<iframe
  src="https://blip-blip.vercel.app/embed"
  width="400"
  height="600"
  style="border: none;"
  allow="clipboard-write"
></iframe>
```

Écoutez les événements de l'intégration :

```js
window.addEventListener('message', (e) => {
  if (e.origin !== 'https://blip-blip.vercel.app') return;

  switch (e.data.type) {
    case 'blip:ready':         // Widget chargé
    case 'blip:room-created':  // Salon créé (roomId, shareUrl)
    case 'blip:room-joined':   // Entré dans le chat
    case 'blip:room-destroyed': // Salon détruit
  }
});
```

- Mise en page légère — pas de publicité, pas de navigation
- Chiffrement E2E complet maintenu
- Les liens partagés restent dans le contexte intégré
- Exemple complet : [embed-example.html](../web/public/embed-example.html)

## Télécharger

<a href="https://play.google.com/store/apps/details?id=com.bakkum.blip" target="_blank"><img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Disponible sur Google Play" width="200"></a>

## Soutien

Si vous aimez ce projet, offrez-moi un café !

<a href="https://buymeacoffee.com/ryokai" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200"></a>

## Licence

MIT
