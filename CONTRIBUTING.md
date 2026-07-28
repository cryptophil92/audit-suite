# Contribuer à Audit Suite

Merci de contribuer à Audit Suite. Le projet manipule des fonctions d’audit réseau : chaque changement doit préserver un usage défensif, autorisé et local par défaut.

## Avant de commencer

1. Lisez `README.md`, `SECURITY.md` et `docs/SECURITY.md`.
2. Vérifiez les issues ouvertes et fermées pour éviter les doublons.
3. Pour une évolution importante, ouvrez d’abord une issue décrivant le besoin, les risques et les critères d’acceptation.
4. Ne joignez jamais de secret, résultat de scan réel, adresse IP identifiable, nom d’hôte, capture réseau ou donnée client à une issue publique.

## Environnement

Plateforme de référence :

- Kali Linux ou Linux compatible ;
- Bash 5 ;
- Python 3.10 ou plus récent ;
- `nmap`, `jq`, `tar`, `gzip` et GNU `timeout` ;
- ShellCheck pour l’analyse statique.

Préflight :

```bash
bash bin/check_deps.sh
```

## Branches

Créez une branche depuis `main` :

```bash
git switch main
git pull --ff-only
git switch -c type/description-courte
```

Préfixes recommandés :

- `fix/`
- `feat/`
- `docs/`
- `test/`
- `security/`
- `ux/`
- `refactor/`

Ne poussez pas directement sur `main`.

## Principes de changement

- Une pull request doit avoir un objectif principal clair.
- Séparez documentation, refactoring lourd et changement fonctionnel lorsque leur validation diffère.
- Préservez le blocage des cibles publiques par défaut.
- Toute future exécution depuis le Web doit faire l’objet d’un chantier de sécurité distinct.
- Les erreurs, résultats partiels et modules ignorés doivent être représentés explicitement.
- Les sorties d’audit doivent rester ignorées par Git.
- N’ajoutez pas de dépendance sans documenter sa version, son rôle, sa licence et sa stratégie de mise à jour.

## Tests

Avant d’ouvrir une pull request :

```bash
for file in $(git ls-files '*.sh'); do
  bash -n "$file"
done

shellcheck \
  -e SC1090 \
  -e SC1091 \
  -e SC2016 \
  -e SC2034 \
  -e SC2154 \
  audit.sh core/*.sh bin/*.sh modules/*.sh ui/*.sh tests/*.sh

for test_file in tests/test_*.sh; do
  bash "$test_file"
done

bash bin/smoke_local.sh
```

N’exécutez aucun scan réel dans la CI. Les essais réseau doivent utiliser un laboratoire autorisé, documenter le périmètre et ne jamais committer leurs sorties.

## Pull request

La description doit indiquer :

- le problème traité ;
- l’issue liée ;
- les fichiers et comportements modifiés ;
- les commandes réellement exécutées ;
- les résultats ;
- les limites et risques ;
- la procédure de retour arrière si nécessaire.

Une pull request de sécurité ne doit pas divulguer de détail exploitable. Suivez `SECURITY.md`.

## Documentation et UX

Toute modification visible doit mettre à jour la documentation associée. Pour l’interface Web, vérifiez au minimum :

- navigation au clavier ;
- focus visible ;
- contraste ;
- états chargement, vide, succès, avertissement et erreur ;
- comportement sur largeur mobile et zoom à 200 % ;
- terminologie cohérente ;
- absence de données réseau sensibles dans les captures.

## Revue

Les mainteneurs peuvent demander :

- une séparation en plusieurs pull requests ;
- un test supplémentaire ;
- une preuve de comportement reproductible ;
- une analyse sécurité ;
- une validation manuelle sur Kali/Linux.

Le merge reste une décision explicite du propriétaire.
