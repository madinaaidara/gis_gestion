# Giss Gestion 🇸🇳 - Plateforme B2B de Gestion de Stock et Crédits

 **Lien de démonstration en ligne :** [ https://madinaaidara.github.io/gis_gestion/]( https://madinaaidara.github.io/gis_gestion/)

**Giss Gestion** (*Giss* : voir/observer en wolof) est une application mobile et web conçue pour digitaliser et piloter les commerces de proximité au Sénégal. Elle permet aux boutiquiers de suivre leurs stocks (au kilo/pièce), d'enregistrer leurs ventes, de calculer leurs marges en temps réel et de remplacer le traditionnel "cahier de dette" par un registre de crédits numérique sécurisé.


---

##  Architecture du Projet

L'application cliente est développée avec **Flutter** en respectant scrupuleusement les principes de la **Clean Architecture** et du pattern **MVVM (Model-View-ViewModel)**.

### Structure des Dossiers (`lib/`)
*   `core/` : Constantes, thèmes visuels et utilitaires partagés (Responsive layout, adaptabilité mobile/ordinateur).
*   `data/` : Couche Infrastructure. Contient les `models/` (DTO pour la sérialisation JSON), les `datasources/` (appels directs aux API) et l'implémentation des `repositories/`.
*  `domain/` : Couche Métier pure (Entities/Usecases). Actuellement laissée vide dans ce prototype ; les règles métier sont temporairement portées par les ViewModels pour accélérer la validation du MVP. Sa mise en œuvre stricte est planifiée pour la phase de transition microservices.
*   `presentation/` : Couche UI. Organisée en `pages/` (écrans de l'application), `widgets/` réutilisables (comme `auth_wrapper.dart`) et `viewmodels/` (gestion de l'état de la vue).
*   `services/` : Services techniques transversaux (`supabase_service.dart`).

---

##  Technologies Utilisées

*   **Frontend :** Flutter & Dart (Interface responsive et adaptative Mobile/Web).
*   **Backend & Persistance :** Supabase (Moteur cloud s'appuyant sur **PostgreSQL**).
*   **Sécurité :** Authentification par jetons **JWT** et isolation stricte des boutiques via les politiques **RLS (Row Level Security)** de PostgreSQL.

---

##  Sécurité & Configuration des Clés (Code Source)

Pour des raisons de sécurité évidentes et conformément aux bonnes pratiques de l'ingénierie logicielle, **les clés d'API de production et l'URL Supabase ont été retirées de la branche principale (`main`)**. 

Si vous souhaitez cloner et exécuter ce code source localement, vous devez renseigner vos propres identifiants Supabase dans le fichier suivant :
 `lib/core/constants/supabase_constants.dart`

---

##  État d'Avancement du Prototype (Preuve de Concept)

Pour illustrer la pertinence de la macro et micro-architecture, les modules fonctionnels suivants ont été implémentés de bout en bout :
1.  **Authentification & Routage :** Gestion sécurisée des sessions via Supabase Auth et redirection dynamique (`auth_wrapper.dart`).
2.  **Gestion des Produits :** Catalogue, configuration des prix d'achat/vente et des unités de mesure.
3.  **Tunnel de Vente :** Gestion du panier, calcul dynamique et instantané des bénéfices/marges, et sélection du mode de paiement (**Comptant** ou **Crédit**).

*Note : Les modules de statistiques, d'historiques avancés et l'intégration de l'API d'IA constituent la phase suivante de la feuille de route de transition vers les microservices détaillée dans le rapport PDF.*

---

##  Installation et Exécution Locale

### Prérequis
*   Flutter SDK (dernière version stable)
*   Un compte ou une instance Supabase active

### Lancement du Projet
1. Récupérez le code source :
   ```bash
   git clone https://github.com/madinaaidara/gis_gestion.git
   cd gis_gestion
   ```
2. Installez les dépendances Flutter :
   ```bash
   flutter pub get
   ```
3. Configurez vos identifiants dans le fichier des constantes mentionné dans la section Sécurité.
4. Lancez l'application sur votre terminal ou navigateur :
   ```bash
   flutter run
   ```
