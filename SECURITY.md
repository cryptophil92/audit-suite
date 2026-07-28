# Politique de sécurité

## Versions prises en charge

Audit Suite est actuellement expérimental et ne dispose pas encore d’une politique de maintenance par version. Les corrections de sécurité doivent viser la branche `main` actuelle, sauf indication contraire du propriétaire.

## Signaler une vulnérabilité

Ne publiez pas de vulnérabilité, secret, donnée d’audit ou méthode d’exploitation dans une issue publique.

Utilisez en priorité le canal privé « Report a vulnerability » de l’onglet Security du dépôt lorsqu’il est disponible. Si ce canal n’est pas activé, contactez le propriétaire du dépôt par un moyen privé visible sur son profil GitHub et demandez un canal de transmission sécurisé avant d’envoyer les détails.

Le premier message peut contenir uniquement :

- la zone concernée ;
- la gravité estimée ;
- l’impact général ;
- une adresse de contact ;
- la mention qu’un rapport technique est prêt.

Attendez l’accord sur le canal avant de transmettre :

- preuve de concept ;
- adresse, nom d’hôte ou résultat de scan ;
- secret ou jeton ;
- instructions d’exploitation ;
- donnée client ou personnelle.

## Contenu attendu du rapport privé

- version, commit et plateforme ;
- préconditions ;
- comportement observé ;
- impact ;
- reproduction minimale et non destructive ;
- proposition de correction ;
- mesures temporaires de réduction du risque.

## Cadre d’utilisation

Audit Suite est destiné uniquement aux réseaux et systèmes explicitement autorisés. La politique fonctionnelle et les plages bloquées par défaut sont décrites dans `docs/SECURITY.md`.

## Divulgation

Le calendrier de correction et de divulgation est défini avec le rapporteur selon la gravité, la disponibilité d’un correctif et le risque pour les utilisateurs. Aucun engagement de délai n’est garanti tant que le projet reste expérimental.
