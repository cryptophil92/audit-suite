# Personas provisoires

Ces personas sont des hypothèses de conception. Ils ne sont pas validés par une recherche utilisateur.

Le cœur de cible n’est pas organisé autour de rôles red team, blue team ou SOC.
Il est organisé autour de la tâche : comprendre un environnement autorisé,
prioriser des corrections et remettre un rapport clair.

## Persona A — Particulier avancé

**Contexte :** administre son réseau domestique et comprend les notions IP de base.

**Objectifs :**

- savoir quels appareils et services sont présents ;
- détecter une configuration inhabituelle ;
- conserver un rapport compréhensible ;
- rester entièrement en local.

**Freins :**

- installation Kali et dépendances ;
- résultats Nmap trop techniques ;
- peur de scanner une mauvaise cible ;
- difficulté à distinguer absence de résultat et erreur.

**Besoins :**

- onboarding prudent ;
- vocabulaire expliqué ;
- profil rapide recommandé ;
- résumé lisible et recommandations sourcées.

## Persona B — Technicien informatique

**Contexte :** intervient sur des réseaux clients avec autorisation.

**Objectifs :**

- préparer rapidement un périmètre ;
- exécuter un audit reproductible ;
- suivre l’avancement ;
- exporter un rapport anonymisable ;
- comparer avant/après.

**Freins :**

- absence de packaging ;
- statut partiel mal représenté ;
- difficulté à prouver la version et les options ;
- archives pouvant contenir trop d’informations.

**Besoins :**

- manifest fiable ;
- modèle d’autorisation/périmètre ;
- journal horodaté ;
- export contrôlé ;
- comparaison de runs.

## Persona C — Administrateur système

**Contexte :** gère une infrastructure interne et automatise les contrôles.

**Objectifs :**

- intégrer les sorties JSON ;
- sélectionner des vérifications ;
- diagnostiquer les dépendances ;
- reproduire les résultats ;
- conserver un historique local.

**Freins :**

- contrats JSON dupliqués ;
- versions incohérentes ;
- pas de pagination ni verrouillage ;
- pas de mode non interactif complètement documenté par capacité.

**Besoins :**

- schémas stables ;
- codes retour fiables ;
- API bornée ;
- installation reproductible ;
- logs structurés.

## Persona D — Référent sécurité de proximité

**Contexte :** accompagne une petite organisation, une association ou un client
autorisé sans disposer d’une équipe sécurité dédiée.

**Objectifs :**

- expliquer les risques à des interlocuteurs non spécialistes ;
- distinguer ce qui est observé, potentiel ou confirmé ;
- remettre un plan de correction priorisé ;
- conserver preuves et métadonnées ;
- vérifier les améliorations lors d’un nouvel audit.

**Freins :**

- rapport actuel centré sur les modules ;
- absence de notation et de confiance structurées ;
- preuves dispersées ;
- remédiations non normalisées ;
- risque de partager des données sensibles.

**Besoins :**

- résumé exécutif et détail technique ;
- notation justifiée ;
- preuves sourcées ;
- remédiation et méthode de vérification ;
- export anonymisable.

## Persona E — Utilisateur non expert accompagné

**Contexte :** veut comprendre son réseau mais ne maîtrise ni Kali ni Nmap.

**Objectifs :**

- savoir si l’outil est prêt ;
- lancer uniquement une vérification sûre et autorisée ;
- comprendre les appareils détectés ;
- recevoir des explications prudentes.

**Freins :**

- terminal ;
- jargon ;
- JSON brut ;
- risque de fausse alerte ;
- absence d’aide dans le flux.

**Besoins :**

- accompagnement pas à pas ;
- explications sans dramatisation ;
- actions réversibles ;
- aide contextuelle ;
- confirmation humaine avant toute opération.

## Hypothèses de segmentation

Axes à valider :

- expertise réseau ;
- fréquence d’usage ;
- responsabilité personnelle ou professionnelle ;
- besoin d’export ;
- besoin d’automatisation ;
- tolérance au terminal ;
- contraintes d’accessibilité ;
- politique de conservation.

## Questions de recherche

1. Quelle tâche déclenche l’usage réel ?
2. Quel niveau de preuve est attendu ?
3. Quels résultats sont compris sans aide ?
4. Quelles erreurs détruisent le plus la confiance ?
5. Qui partage les rapports, avec qui et sous quelle forme ?
6. Le mode Web doit-il rester consultation/préparation ?
7. Quels handicaps ou contraintes d’environnement faut-il prioriser ?
