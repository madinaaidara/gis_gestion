# Giss Gestion 🇸🇳 - Plateforme B2B de Gestion de Stock et Crédits

**Gis Gestion** (*Gis* : voir/observer en wolof) est une application mobile et web conçue pour digitaliser et piloter les commerces de proximité au Sénégal. Elle permet aux boutiquiers de suivre leurs stocks (au kilo/pièce), d'enregistrer leurs ventes, de calculer leurs marges en temps réel et de remplacer le traditionnel "cahier de dette" par un registre de crédits numérique sécurisé.

Ce projet s'inscrit dans le cadre du module d'**Architecture Logicielle (Licence 3)**.

---

## Architecture du Projet

Conformément aux exigences du cahier des charges, l'application cliente est développée avec **Flutter** en respectant scrupuleusement les principes de la **Clean Architecture** et du pattern **MVVM (Model-View-ViewModel)**.

### Structure des Dossiers (`lib/`)
*   `core/` : Constantes, thèmes visuels et utilitaires partagés.
*   `data/` : Couche Infrastructure. Contient les `models/` (DTO pour la sérialisation JSON), les `datasources/` (appels directs aux API) et l'implémentation des `repositories/`.
*   `domain/` : Couche Métier pure. Contient les entités et les cas d'utilisation (indépendante des frameworks).
*   `presentation/` : Couche UI. Organisée en `pages/` (écrans de l'application), `widgets/` réutilisables (comme `auth_wrapper.dart`) et `viewmodels/` (gestion de l'état de la vue).
*   `services/` : Services techniques transversaux (`supabase_service.dart`).

---

## Technologies Utilisées

*   **Frontend :** Flutter & Dart (Interface responsive et adaptative Mobile/Web).
*   **Backend & Persistance :** Supabase (Moteur cloud s'appuyant sur **PostgreSQL**).
*   **Sécurité :** Authentification par jetons **JWT** et isolation stricte des boutiques via les politiques **RLS (Row Level Security)** de PostgreSQL.

---

## État d'Avancement du Prototype (Preuve de Concept)

Pour illustrer la pertinence de la macro et micro-architecture, les modules prioritaires suivants ont été implémentés de bout en bout :
1.  **Authentification & Routage :** Gestion sécurisée des sessions via Supabase Auth et redirection dynamique (`auth_wrapper.dart`).
2.  **Gestion des Produits :** Catalogue, configuration des prix d'achat/vente et des unités de mesure.
3.  **Tunnel de Vente :** Gestion du panier, calcul dynamique et instantané des bénéfices/marges, et sélection du mode de paiement (**Comptant** ou **Crédit**).

*Note : Les modules de statistiques, d'historiques avancés et l'intégration de l'API d'IA constituent la phase suivante de la feuille de route de transition vers les microservices détaillée dans le rapport PDF.*

---

##  Installation et Exécution

### Prérequis
*   Flutter SDK (dernière version stable)
*   Un compte ou une instance Supabase active

### Lancement du Projet
1. Récupérez le code source :
   ```bash
   git clone <url-de-votre-depot-git>
   cd giss_gestion
   ```
2. Installez les dépendances Flutter :
   ```bash
   flutter pub get
   ```
3. Configurez vos clés Supabase dans le fichier d'initialisation (`lib/core/constants/supabase_constants.dart`).
4. Lancez l'application sur votre terminal ou navigateur :
   ```bash
   flutter run
   ```
