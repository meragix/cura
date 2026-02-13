# 🗺️ Roadmap Complète `pub_pulse` (2026-2027)

> **Vision** : Devenir l'outil de référence pour l'audit de santé des dépendances Dart/Flutter, éliminant le "vibe code" et guidant les développeurs vers des choix de production robustes.

---

## 📅 Timeline Globale

```
┌─────────────────────────────────────────────────────────────────────┐
│ Q1 2026      │ Q2 2026      │ Q3 2026      │ Q4 2026    │ 2027      │
├─────────────────────────────────────────────────────────────────────┤
│ MVP          │ Community    │ Advanced     │ Enterprise │ Ecosystem │
│ v0.1-v0.5    │ v1.0-v1.2    │ v1.3-v1.5    │ v2.0       │ v2.x+     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Phase 1 : MVP - "Le Fondement" (Q1 2026, ~6-8 semaines)

### Objectif

Créer un outil fonctionnel minimal qui résout le problème principal : **identifier les paquets morts dans un `pubspec.yaml`**.

### Milestones

#### **v0.1.0 - Proof of Concept** (Semaine 1-2)

**Fonctionnalités :**

- ✅ Commande `pub_pulse view <package>` fonctionnelle
- ✅ Scoring basique (maintenance + trust + popularity)
- ✅ Affichage terminal simple (pas de table élégante encore)
- ✅ Cache local opérationnel
- ✅ Tests unitaires du `ScoreCalculator` (>80% coverage)

**Livrable :**

```bash
$ pub_pulse view dio
Package: dio (v5.4.0)
Score: 95/100 ✅ HEALTHY
Last update: 15 days ago
Publisher: dart.dev (verified)
```

**Décisions techniques :**

- Utiliser `mason_logger` pour les logs colorés
- Pas encore de gestion de pool de requêtes (ajouté en v0.2)
- Cache simple sans TTL variable (24h fixe)

**Critères de succès :**

- [ ] L'outil analyse correctement `dio`, `http`, `flutter_bloc`
- [ ] Le cache fonctionne et évite les appels répétés
- [ ] Les tests passent sur CI/CD (GitHub Actions)

---

#### **v0.2.0 - Scan Automatique** (Semaine 3-4)

**Fonctionnalités :**

- ✅ Commande `pub_pulse check` qui lit `pubspec.yaml`
- ✅ Parsing des dépendances (dependencies + dev_dependencies)
- ✅ Pool de requêtes concurrent (max 5 simultanées)
- ✅ Barre de progression (`mason_logger.progress()`)
- ✅ Rapport textuel avec résumé

**Livrable :**

```bash
$ pub_pulse check
📦 Analyse de 23 paquets...
[████████████████████████] 100%

╭───────────────────────────────────────╮
│ RÉSUMÉ                                │
├───────────────────────────────────────┤
│ ✅ Healthy: 18 paquets                │
│ ⚠️  Warning: 4 paquets                │
│ ❌ Critical: 1 paquet                 │
╰───────────────────────────────────────╯

PAQUETS CRITIQUES:
- old_package (score: 25/100)
  └─ Legacy (540+ jours), pas de repository
```

**Défis techniques :**

- Parser correctement les dépendances Git/Path (ignorer pour MVP)
- Gérer les erreurs réseau gracieusement
- Afficher la progression sans polluer le terminal

**Critères de succès :**

- [ ] Analyse un projet Flutter standard (30+ deps) en <30 secondes
- [ ] Rate limiting respecté (aucune erreur 429)
- [ ] Gestion d'erreurs robuste (paquet introuvable → warning, pas crash)

---

#### **v0.3.0 - Mode CI/CD** (Semaine 5-6)

**Fonctionnalités :**

- ✅ Flag `--fail-on <score>` qui retourne exit code 1 si seuil atteint
- ✅ Format JSON (`--json`) pour parsing automatique
- ✅ Flag `--verbose` pour debug
- ✅ Documentation complète du README

**Livrable :**

```bash
# Pipeline GitLab CI
$ pub_pulse check --fail-on 50 --json > report.json
$ echo $?  # 1 si un paquet < 50/100

# Format JSON
{
  "overall_score": 68,
  "status": "FAILED",
  "critical_packages": [
    {"name": "old_pkg", "score": 45}
  ]
}
```

**Cas d'usage :**

- Bloquer un merge request si un paquet critique est ajouté
- Dashboard de monitoring (intégration avec Grafana/DataDog)

**Critères de succès :**

- [ ] Intégration réussie dans un pipeline GitHub Actions
- [ ] Documentation détaillée avec exemples `.gitlab-ci.yml`
- [ ] Format JSON valide (validation avec JSON Schema)

---

#### **v0.4.0 - UX Polish** (Semaine 7)

**Fonctionnalités :**

- ✅ Table ASCII élégante (avec `package:cli_table`)
- ✅ Couleurs et émojis pour les statuts
- ✅ Flag `--skip-cache` pour forcer la mise à jour
- ✅ Commande `pub_pulse cache clear`

**Livrable :**

```bash
$ pub_pulse check

┌─────────────────────┬───────┬────────┬─────────────┐
│ Package             │ Score │ Status │ Last Update │
├─────────────────────┼───────┼────────┼─────────────┤
│ dio                 │ 95    │ ✅     │ 15 days     │
│ http                │ 88    │ ✅     │ 2 months    │
│ old_package         │ 25    │ ❌     │ 18 months   │
└─────────────────────┴───────┴────────┴─────────────┘
```

**Critères de succès :**

- [ ] Interface comparable à `flutter pub outdated` en qualité
- [ ] Temps de réponse acceptable (cache hit <50ms)

---

#### **v0.5.0 - Publication Officielle** (Semaine 8)

**Tâches :**

- ✅ Publication sur pub.dev
- ✅ Logo et branding
- ✅ README avec GIF démo
- ✅ Changelog structuré
- ✅ Licence MIT
- ✅ Contributing guidelines

**Métriques de succès :**

- [ ] 100+ likes sur pub.dev dans le premier mois
- [ ] 1000+ téléchargements/semaine
- [ ] 50+ stars sur GitHub
- [ ] Aucun bug critique reporté

---

## 🌍 Phase 2 : Community - "L'Adoption" (Q2 2026, ~12 semaines)

### Objectif

Construire une communauté active et améliorer l'outil grâce aux retours utilisateurs.

---

#### **v1.0.0 - Stable Release** (Semaine 9-10)

**Focus : Production-ready**

**Améliorations :**

- 🔒 API stable (pas de breaking changes avant v2.0)
- 📝 Documentation exhaustive (pub.dev + docs.pub-pulse.dev)
- 🧪 Tests d'intégration (100+ scénarios)
- 🐛 Correction de tous les bugs majeurs

**Nouveautés :**

- ✅ Support des dépendances Git (`git: url: ...`)
- ✅ Support des dépendances Path (`path: ../local_pkg`)
- ✅ Détection des paquets hébergés sur GitLab/Bitbucket

**Exemple :**

```bash
$ pub_pulse check
⚠️  internal_package (Git dependency)
   └─ Impossible à analyser (non publié sur pub.dev)
   └─ Recommandation: Auditer manuellement
```

**Critères de succès :**

- [ ] Zéro crash sur 1000 projets Flutter analysés
- [ ] Score pub.dev de 130/140 minimum
- [ ] Featured dans Flutter Weekly newsletter

---

#### **v1.1.0 - Alternative Suggestion** (Semaine 11-14)

**Fonctionnalités :**

- ✅ Commande `pub_pulse suggest <package>`
- ✅ Base de données de similarités (JSON local)
- ✅ Scoring comparatif
- ✅ Raisons de la suggestion

**Livrable :**

```bash
$ pub_pulse suggest shared_preferences

📦 shared_preferences (score: 65/100)
   └─ Dernière update: 8 mois
   └─ Publisher: flutter.dev

🔍 Alternatives plus saines:

1. ✅ hive (score: 92/100) ⭐ Recommandé
   └─ NoSQL léger, mieux maintenu
   └─ +45% plus rapide en lecture
   └─ Migration: guide disponible

2. ⚠️  flutter_secure_storage (score: 88/100)
   └─ Si besoin de chiffrement
   └─ Overhead de performance (+20ms)
```

**Défis techniques :**

- Construire une base de similarités (scraping des tags pub.dev)
- Éviter les suggestions absurdes (`dio` ≠ `http` en usage)
- Permettre le crowdsourcing (fichier `.pub_pulse_suggestions.yaml`)

**Critères de succès :**

- [ ] 80% de pertinence des suggestions (validation manuelle)
- [ ] 50+ mappings de similarités
- [ ] Mécanisme de contribution communautaire opérationnel

---

#### **v1.2.0 - Whitelist Communautaire** (Semaine 15-17)

**Fonctionnalités :**

- ✅ Fichier `.pub_pulse_whitelist.yaml` dans les projets
- ✅ Whitelist globale communautaire (GitHub repo)
- ✅ Commande `pub_pulse whitelist add <package> --reason "..."`

**Use case :**

```yaml
# .pub_pulse_whitelist.yaml
packages:
  old_but_gold_pkg:
    reason: "Package stable, pas de bugs depuis 2 ans"
    whitelisted_by: "john@company.com"
    date: "2026-04-15"
```

**Impact :**

- Évite les faux positifs pour les équipes
- Permet de documenter les exceptions
- Whitelist partagée sur `github.com/pub-pulse/whitelist`

**Critères de succès :**

- [ ] 100+ paquets dans la whitelist communautaire
- [ ] Pull requests de la communauté acceptées

---

## 🚀 Phase 3 : Advanced - "L'Intelligence" (Q3 2026, ~12 semaines)

### Objectif

Ajouter des fonctionnalités avancées qui font de `pub_pulse` un outil indispensable.

---

#### **v1.3.0 - Analyse des Dépendances Transitives** (Semaine 18-21)

**Fonctionnalités :**

- ✅ Graph de dépendances complet
- ✅ Détection de paquets morts en profondeur
- ✅ Visualisation ASCII du graphe

**Livrable :**

```bash
$ pub_pulse check --deep

📦 Analyse profonde (3 niveaux)...

┌─ Votre app (score: 85/100)
│  ├─✅ dio (95/100)
│  │  └─✅ http_parser (90/100)
│  ├─⚠️  old_package (45/100)
│  │  └─❌ deprecated_lib (10/100)  ← RISQUE
│  └─✅ flutter_bloc (92/100)

⚠️  ALERTE: old_package dépend de deprecated_lib (abandonné)
   Recommandation: Migrer vers new_package
```

**Défis techniques :**

- Parser le fichier `pubspec.lock` (format complexe)
- Gérer les cycles de dépendances
- Limiter la profondeur (max 5 niveaux pour éviter explosion)

**Critères de succès :**

- [ ] Détecte 95%+ des dépendances transitives problématiques
- [ ] Temps d'analyse <2 minutes pour un projet moyen

---

#### **v1.4.0 - Sécurité & CVE** (Semaine 22-25)

**Fonctionnalités :**

- ✅ Intégration avec OSV (Open Source Vulnerabilities)
- ✅ Détection de CVEs connues
- ✅ Scoring de sévérité (Critical/High/Medium/Low)

**Livrable :**

```bash
$ pub_pulse check --security

🚨 VULNÉRABILITÉS DÉTECTÉES:

❌ CRITICAL: dio@4.0.0
   └─ CVE-2023-12345: SSRF vulnerability
   └─ Fix: Mettre à jour vers dio@5.4.0+
   └─ CVSS Score: 9.8/10

⚠️  MEDIUM: http@0.13.0
   └─ CVE-2022-67890: Header injection
   └─ Fix: Mettre à jour vers http@1.0.0+
```

**Sources de données :**

- GitHub Advisory Database (API gratuite)
- OSV.dev (Open Source Vulnerabilities)
- Snyk (si partenariat)

**Critères de succès :**

- [ ] 100% des CVEs critiques détectées
- [ ] Faux positifs <2%

---

#### **v1.5.0 - Rapport HTML/PDF** (Semaine 26-29)

**Fonctionnalités :**

- ✅ Export HTML interactif
- ✅ Graphiques (Chart.js)
- ✅ Historique d'évolution des scores
- ✅ Export PDF pour audits

**Livrable :**

```bash
$ pub_pulse check --report html --output audit.html

✅ Rapport généré: audit.html
   └─ Contenu:
      • Graphique d'évolution temporelle
      • Tableau interactif filtrable
      • Recommandations prioritaires
      • Roadmap de migration
```

**Cas d'usage :**

- Audits de sécurité pour clients
- Revues trimestrielles en équipe
- Documentation technique

**Critères de succès :**

- [ ] Rapport professionnel (design moderne)
- [ ] Export PDF <5MB pour 100 paquets

---

## 🏢 Phase 4 : Enterprise - "La Scale" (Q4 2026, ~12 semaines)

### Objectif

Rendre `pub_pulse` utilisable en entreprise avec des fonctionnalités de gouvernance.

---

#### **v2.0.0 - Multi-Projets & Dashboard** (Semaine 30-35)

**Fonctionnalités :**

- ✅ Scan de workspaces (monorepos)
- ✅ Dashboard web local (serveur HTTP intégré)
- ✅ Comparaison inter-projets
- ✅ Alertes par email/Slack

**Livrable :**

```bash
$ pub_pulse serve --port 8080

🌐 Dashboard disponible sur http://localhost:8080

┌─────────────────────────────────────────┐
│ Projets Monitorés                       │
├─────────────────────────────────────────┤
│ app_mobile    │ 85/100 │ 23 paquets    │
│ app_web       │ 92/100 │ 18 paquets    │
│ shared_lib    │ 78/100 │ 12 paquets    │
└─────────────────────────────────────────┘
```

**Architecture :**

- Backend: Dart shelf server
- Frontend: HTML/CSS/JS vanilla (pas de framework lourd)
- Stockage: SQLite local

**Critères de succès :**

- [ ] Support de 50+ projets simultanés
- [ ] Dashboard responsive (mobile-friendly)

---

#### **v2.1.0 - Détection de Licences** (Semaine 36-38)

**Fonctionnalités :**

- ✅ Analyse des licences (MIT, Apache, GPL, etc.)
- ✅ Détection de conflits (GPL dans app propriétaire)
- ✅ Export de compliance report

**Livrable :**

```bash
$ pub_pulse check --licenses

⚠️  CONFLIT DE LICENCE DÉTECTÉ:

Votre app: Licence propriétaire
├─ dio (Apache 2.0) ✅ Compatible
├─ flutter_bloc (MIT) ✅ Compatible
└─ gpl_package (GPL-3.0) ❌ INCOMPATIBLE
   └─ GPL-3.0 nécessite open-sourcing

📄 Compliance Report: licenses_report.pdf
```

**Critères de succès :**

- [ ] 95%+ de précision sur détection de licences
- [ ] Format rapport compatible ISO 27001

---

#### **v2.2.0 - Plugins & Extensions** (Semaine 39-41)

**Fonctionnalités :**

- ✅ Système de plugins (Dart packages)
- ✅ Hooks personnalisables
- ✅ Marketplace de plugins communautaires

**Exemple plugin :**

```dart
// package: pub_pulse_plugin_jira
class JiraPlugin extends PubPulsePlugin {
  @override
  Future<void> onCriticalPackageDetected(PackageInfo pkg) async {
    await jiraClient.createIssue(
      title: 'Package critique détecté: ${pkg.name}',
      priority: 'High',
    );
  }
}
```

**Critères de succès :**

- [ ] 10+ plugins officiels
- [ ] API de plugins documentée

---

## 🌐 Phase 5 : Ecosystem - "L'Écosystème" (2027+)

### Objectif

Construire un écosystème complet autour de `pub_pulse`.

---

#### **v2.3.0 - API Publique Cloud** (Q1 2027)

**Fonctionnalités :**

- ✅ API REST cloud (`api.pub-pulse.dev`)
- ✅ Webhooks pour monitoring continu
- ✅ Intégrations natives (GitHub App, GitLab Bot)

**Business model :**

- Tier gratuit: 1000 requêtes/mois
- Tier Pro: 50,000 requêtes/mois ($29/mois)
- Tier Enterprise: Illimité ($299/mois)

---

#### **v2.4.0 - AI-Powered Suggestions** (Q2 2027)

**Fonctionnalités :**

- ✅ LLM pour générer des guides de migration
- ✅ Analyse de code pour détecter l'usage réel
- ✅ Suggestions contextuelles

**Exemple :**

```bash
$ pub_pulse suggest shared_preferences --ai

🤖 Analyse IA en cours...

✅ Votre code utilise shared_preferences pour:
   - Stockage de tokens JWT (détecté dans auth_service.dart)
   - Préférences utilisateur (détecté dans settings_page.dart)

💡 Recommandation personnalisée:
   1. Migrer tokens vers flutter_secure_storage (chiffrement)
   2. Garder shared_preferences pour préférences UI

📝 Guide de migration généré: migration_guide.md
```

---

#### **v3.0.0 - The Ultimate Tool** (Q4 2027)

**Vision finale :**

- Plateforme SaaS complète (`pub-pulse.dev`)
- Monitoring temps réel
- Recommandations prédictives (ML)
- Intégrations avec tous les outils DevOps
- Certification "Pub Pulse Verified" pour paquets de qualité

---

## 📊 Métriques de Succès Globales

### Adoption

| Métrique | 6 mois | 12 mois | 24 mois |
|----------|--------|---------|---------|
| Téléchargements hebdomadaires | 5,000 | 20,000 | 100,000 |
| Projets utilisant pub_pulse | 1,000 | 10,000 | 50,000 |
| Stars GitHub | 500 | 2,000 | 10,000 |
| Contributors | 10 | 50 | 200 |

### Impact

- **Réduction du temps d'audit** : 80% (8h → 1.5h)
- **Détection de paquets morts** : 95%+ de précision
- **Adoption en entreprise** : 100+ entreprises en Q4 2026

---

## 🎓 Enseignements à Tirer

### Ce qui fera réussir le projet

1. **Résoudre un vrai problème** : La pollution pub.dev est réelle
2. **Qualité dès le MVP** : Première impression cruciale
3. **Communauté early** : Impliquer les utilisateurs dès v0.5
4. **Documentation excellente** : Le code ne suffit pas
5. **Open-source sincère** : Accepter les contributions

### Ce qui pourrait faire échouer le projet

1. **Faux positifs élevés** : Tue la confiance
2. **Perf médiocre** : Personne n'attend 5 minutes
3. **API pub.dev instable** : Plan B nécessaire (cache agressif)
4. **Monétisation prématurée** : Garder gratuit jusqu'à v2.0
5. **Complexité excessive** : Rester simple et focalisé

---

## 🛠️ Stack Technique Finale

```yaml
Backend:
  - Dart pur (CLI)
  - Shelf (serveur HTTP pour dashboard)
  - SQLite (stockage local)
  
Frontend (Dashboard):
  - HTML/CSS/JS vanilla
  - Chart.js (graphiques)
  - Alpine.js (interactivité légère)
  
Infra:
  - Docker (déploiement)
  - GitHub Actions (CI/CD)
  - DigitalOcean (API cloud)
  
Monitoring:
  - Sentry (error tracking)
  - Plausible (analytics privacy-first)
```

---

## ✅ Prochaines Actions Immédiates

Pour démarrer aujourd'hui :

1. ✅ **Créer le repo GitHub**
   - Structure des dossiers
   - README avec vision
   - LICENSE (MIT)

2. ✅ **Implémenter v0.1.0**
   - `pub_pulse view <package>`
   - Tests de base
   - CI/CD GitHub Actions

3. ✅ **Première release**
   - Publier sur pub.dev
   - Annoncer sur Reddit r/FlutterDev
   - Poster sur Twitter/X

4. 📣 **Collecter feedback**
   - Créer Discord/Slack communautaire
   - Issues template GitHub
   - Roadmap publique (GitHub Projects)

---

**Conclusion** : Ce projet a un potentiel énorme. La clé est de démarrer simple (MVP en 6 semaines), itérer vite, et construire une communauté engagée. Le marché est là, le problème est réel, l'architecture est solide. **Time to ship!** 🚀
