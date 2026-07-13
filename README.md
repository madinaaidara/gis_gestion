# Gis Gestion 🇸🇳 - Plateforme B2B de Gestion de Stock et Crédits

**Lien de démonstration en ligne :** [https://madinaaidara.github.io/gis_gestion/](https://madinaaidara.github.io/gis_gestion/)

**Gis Gestion** (*Gis* : voir/observer en wolof) est une application mobile et web conçue pour digitaliser et piloter les commerces de proximité au Sénégal. Elle permet aux boutiquiers de suivre leurs stocks (au kilo/pièce), d'enregistrer leurs ventes, de calculer leurs marges en temps réel et de remplacer le traditionnel « cahier de dette » par un registre de crédits numérique sécurisé.

---

## Architecture du Projet

L'application cliente est développée avec **Flutter** en respectant les principes de la **Clean Architecture** et du pattern **MVVM (Model-View-ViewModel)**.

### Structure des Dossiers (`lib/`)

* `core/` : Constantes, thèmes visuels, services métier (assistant, prédictions) et utilitaires partagés (responsive, téléchargements web).
* `data/` : Couche infrastructure — `models/`, `datasources/` et `repositories/` (Supabase).
* `domain/` : Couche métier pure (Entities/Usecases). Laissée vide dans ce prototype ; les règles métier sont portées par les ViewModels pour accélérer la validation du MVP.
* `presentation/` : Couche UI — `pages/`, `widgets/` réutilisables et `viewmodels/`.
* `services/` : Services techniques transversaux (`supabase_service.dart`).

---

## Technologies Utilisées

* **Frontend :** Flutter & Dart (interface responsive Mobile/Web).
* **Backend & persistance :** Supabase (PostgreSQL).
* **État UI :** Provider.
* **Graphiques :** fl_chart.
* **Sécurité :** authentification JWT et isolation des boutiques via **RLS (Row Level Security)**.

---

## Modules Fonctionnels

Les modules suivants sont implémentés de bout en bout :

1. **Authentification & onboarding** — connexion Supabase, création de boutique, visite guidée.
2. **Accueil** — tableau de bord avec indicateurs clés (CA, stock, crédits).
3. **Produits** — catalogue, prix d'achat/vente, unités (pièce, kg, g, ml), stock et alertes.
4. **Ventes** — panier, calcul des marges/bénéfices, paiement comptant ou crédit, gestion du stock.
5. **Crédits clients** — registre numérique, suivi des soldes et encaissements.
6. **Historique** — journal des ventes et mouvements de crédit, filtres par période.
7. **Statistiques** — courbes d'évolution, répartition des ventes, export des rapports.
8. **Assistant Gis** — réponses contextuelles (CA du jour, tendances, prévisions stock).
9. **Profil & abonnement** — gestion du compte et de la licence boutique.

---

## Sécurité & Configuration Supabase

Le dépôt contient l'**URL Supabase** et la **clé anonyme (anon)** dans `lib/core/constants/supabase_constants.dart`. Cette clé est publique par conception chez Supabase : l'accès aux données est restreint par les politiques **RLS** côté base, pas par le secret de la clé.

Pour cloner et exécuter le projet avec **votre propre instance Supabase**, remplacez ces valeurs dans ce fichier.

> En production, évitez de committer des clés `service_role`. La clé `anon` peut rester côté client si les politiques RLS sont correctement configurées.

---

## Installation et Exécution Locale

### Prérequis

* Flutter SDK (dernière version stable)
* Un projet Supabase actif (schéma et RLS configurés)

### Lancement

```bash
git clone https://github.com/madinaaidara/gis_gestion.git
cd gis_gestion
flutter pub get
flutter run
```

Pour le web :

```bash
flutter run -d chrome
```

### Tests

```bash
flutter test
flutter analyze
```

---

## Déploiement Web (GitHub Pages)

La démo est servie depuis la branche `gh-pages` à l'URL `/gis_gestion/`.

Build local :

```bash
flutter build web --release --base-href "/gis_gestion/"
```

Puis publier le contenu de `build/web/` sur la branche `gh-pages` (déploiement manuel ou workflow `.github/workflows/deploy-web.yml`).

---

## Évolutions Prévues

* Extraction stricte de la couche `domain/` (use cases).
* Transition vers une architecture microservices (décrite dans le rapport PDF).
* Renforcement de la couverture de tests et durcissement CI/CD.
