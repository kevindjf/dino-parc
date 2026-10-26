# Dino Parc Pixel

Le parc de dinosaures en 2D, vu de dessus, en pixel art façon console portable des années 2000. Tous les dessins (dinosaures, arbres, barrières, bâtiments, personnages) sont faits dans le code : il n'y a aucune image à fournir.

## Lancer le jeu

- Dans Godot : **Importer**, choisir `project.godot`, puis **F5**.
- En ligne de commande : `godot --path ~/dino-parc-pixel`
- Avec un parc de démonstration déjà construit : `godot --path ~/dino-parc-pixel -- --demo`

## Deux façons de jouer

L'écran titre affiche **Mes mondes**, comme dans Minecraft : on reprend un monde en le touchant, on le supprime (avec confirmation), ou on **crée un nouveau monde**. Un monde a un nom et un mode de jeu :

- **Aventure** : on crée son personnage (prénom, peau, coiffure, couleurs), puis on le dirige dans un parc sauvage. On frappe les arbres pour avoir du bois, on casse les rochers avec la pioche pour avoir de la pierre et on cueille des baies. Ensuite on fabrique ses outils et ses barrières dans le sac, et on les pose soi-même. Des objectifs guident les premiers pas.
- **Bac à sable** : on construit librement son parc avec des pièces (l'ancien « mode créatif »).

Chaque monde a sa propre sauvegarde, qui se fait toute seule (toutes les 20 secondes, en quittant et quand le jeu passe en arrière-plan). Le bouton « Menu » sauvegarde avant de revenir à l'écran titre. Les parties faites avant l'arrivée des mondes ont été reprises automatiquement comme deux mondes.

### Réglages d'un monde (pour plus tard)

Un monde peut avoir des réglages choisis à sa création (dinos agressifs, nuit, pièces à volonté…). Pour en ajouter un, il suffit d'une ligne dans `Worlds.SETTINGS` (`scripts/worlds.gd`) : l'écran de création affiche alors un interrupteur (oui/non) ou une rangée de choix pour les modes concernés, le réglage est sauvegardé avec le monde, et le jeu le lit avec `park.setting("clé")`. Les mondes déjà créés prennent la valeur par défaut.

## Aventure : les commandes (pensées pour la tablette)

| Action | Tablette | Clavier |
|---|---|---|
| Marcher | Joystick en bas à gauche | Flèches ou Z Q S D |
| Utiliser ce qu'on tient (frapper, cueillir, poser) | Gros bouton rouge | Espace |
| Tracer une barrière ou un chemin | Garder le bouton rouge appuyé en marchant | Garder Espace en marchant |
| Changer d'outil | Toucher une case de la barre du bas | 1 à 8 |
| Ouvrir le sac et fabriquer | Bouton bleu « Sac » | I ou Tab |
| Ranger un objet dans la barre | Dans le sac, toucher l'objet : il va dans la case choisie | |
| Démonter une barrière, un chemin | La frapper avec la hache ou la pioche | |
| Entrer dans un enclos | Passer par un portail : il s'ouvre tout seul pour toi, pas pour les dinosaures | |
| Zoomer | Pincer, ou boutons « Zoom » | Molette |

Les mains suffisent pour les arbres (plus lentement) et les baies. La hache va deux fois plus vite. La pioche est obligatoire pour les rochers. Les baies repoussent sur les buissons, et de nouveaux arbres et rochers apparaissent avec le temps.

## Aventure : la carte et les mines

La carte fait 128 × 96 cases, organisée en régions :
- **à l'ouest**, autour de l'entrée : la prairie, avec une forêt dense au nord ;
- **au sud-ouest** : le marais et ses lacs ;
- **au centre et au sud** : la jungle ;
- **à l'est** : le désert et ses canyons ;
- **au nord-est** : les montagnes enneigées ;
- **tout le long de la côte est** : la mer et sa plage.

Une rivière descend vers la mer. L'eau bloque le passage : on fabrique des **ponts** (3 bois → 2) qu'on pose sur l'eau. Un lac ou la mer servent aussi de mur pour un enclos.

Chaque massif de montagnes a une **entrée de mine** creusée dans sa falaise sud. Mets-toi devant et appuie sur Action pour descendre.

- Sous terre, il fait sombre et ta lampe éclaire autour de toi.
- On creuse les murs à la pioche, et ce qui est creusé le reste.
- Les échelles mènent aux 3 niveaux. Plus on descend, plus les pierres sont rares :

| Niveau | Ce qu'on y trouve |
|---|---|
| 1 | cuivre, fer |
| 2 | fer, cuivre, cristal, fossiles |
| 3 | cristal, or, ambre, fossiles |

- Le cristal, l'or, l'ambre et les fossiles demandent la **pioche en fer** (3 fer + 2 bois).
- Le fer et le cuivre servent à la **barrière électrique** (2 fer + 1 cuivre → 2), la seule qui retient un T-Rex ou un Spinosaure.
- L'ambre et les fossiles serviront au laboratoire, à la prochaine étape.

Une partie commencée sur l'ancienne petite carte est replacée telle quelle près de l'entrée, avec la nouvelle carte autour.

## Aventure : attraper les dinosaures

Des dinosaures sauvages vivent dans le parc, chacun dans son biome préféré : prairie, jungle, désert, marais ou neige. Les petits sont fréquents, les géants sont rares. Il y a deux façons de les attraper :

- **Apprivoiser un herbivore.** Prendre des baies en main et lui en donner 3 (bouton Action devant lui). Il te suit alors partout, même à travers les barrières. Dès qu'il entre dans un enclos fermé, il y habite.
- **Le combat, puis la capsule**, pour tous les dinosaures. Personne n'est blessé : chaque tir fatigue le dinosaure, et une fois épuisé il s'endort. On lance alors une capsule dessus : il va dans le sac, et on le relâche en visant une case libre dans un enclos.

**Le combat se joue de loin, en direct.** Avec une arme en main, une cible apparaît sur le dinosaure sauvage le plus proche devant toi, avec sa barre d'énergie. Le bouton Action tire (garder appuyé pour tirer en continu) :

| Arme | Effet | Munitions |
|---|---|---|
| Lance-pierre | fatigue un peu | les pierres du sac |
| Arc | fatigue plus, de plus loin | les flèches |
| Fléchettes endormantes | fatiguent beaucoup | elles-mêmes |
| Bolas | bloquent le dinosaure 4 secondes | elles-mêmes |

Les petits herbivores s'enfuient quand on les touche ; les carnivores et les gros herbivores (force 3 et plus) foncent sur toi. S'ils te touchent, tu perds un **cœur** (en haut de l'écran, il y en a 5, ils reviennent tout seuls). Sans cœur, tu te réveilles à l'entrée du parc, sans rien perdre. Si on le laisse tranquille 8 secondes, un dinosaure reprend des forces.

**Les capsules** se lancent de loin. Avec une capsule en main, une pastille de couleur sur la cible dit les chances : **verte** ça marche presque à coup sûr (dinosaure épuisé), **orange** peut-être, **rouge** presque jamais. La capsule tremble trois fois : elle tient, ou le dinosaure s'échappe (réveillé, un peu reposé, et la capsule est perdue). Chaque capsule a sa taille :

- **Capsule en cuivre** : jusqu'à la force 3 (Tricératops, Diplodocus, Vélociraptor…) ;
- **Capsule en fer** : jusqu'à la force 4 (Brachiosaure, Carnotaure, Yutyrannus) ;
- **Capsule en or** : tous, même le T-Rex et le Spinosaure.

La **cage** marche encore pour les petits dinosaures (force 1 et 2) : on la pose à la main sur un dinosaure endormi.

Les carnivores sauvages foncent sur toi s'ils te voient de près. Fermer une barrière autour d'un dinosaure sauvage marche aussi !

## Aventure : l'amitié et la monture

Chaque dinosaure du parc a de l'**amitié pour toi, de 0 à 5 cœurs**. Elle démarre à 1 cœur pour un dinosaure apprivoisé, à 0 pour un dinosaure attrapé en cage ou en capsule.

- **Le brosser** (brosse en main, Action devant lui) : tous les dinosaures aiment ça.
- **Lui donner des baies à la main**, pour les herbivores.
- Chaque soin ne marche qu'une fois toutes les 20 secondes : il faut revenir le voir. Les carnivores sont méfiants et demandent deux fois plus de soins.
- Toucher un dinosaure avec un autre objet en main affiche ses cœurs.

**La selle** se pose sur un dinosaure d'au moins 3 cœurs (selle en main, Action). À **5 cœurs**, Action à mains nues le monte. Il faut un dinosaure d'au moins 6 m : à partir du Gallimimus, du Tricératops ou du Dilophosaure. Sa vitesse dépend de l'espèce. Action fait descendre. Si tu descends hors de son enclos, il te suit jusqu'à ce que tu le ramènes. Sur un dinosaure au moins aussi fort qu'eux, les carnivores sauvages n'osent plus te foncer dessus.

Le **Dinodex** (bouton en haut) montre les 21 espèces : les ombres noires sont celles qu'il reste à attraper. Les volants et les reptiles marins arriveront plus tard.

Recettes : Hache (3 bois), Pioche (4 bois), Barrières en bambou (1 bois → 2), en bois (2 bois → 2), en pierre (2 pierres → 2), Portail (3 bois), Chemin (1 pierre → 4), Mangeoire (4 bois + 3 baies), Lance-pierre (3 bois), Arc (5 bois), Flèches (1 bois + 1 pierre → 5), Fléchettes endormantes (1 bois + 2 baies → 3), Bolas (2 pierres + 1 bois → 2), Cage (4 bois + 2 pierres), Capsules en cuivre (2 cuivre + 1 pierre → 2), en fer (2 fer + 1 cuivre → 2), en or (1 or + 1 fer + 1 cristal), Brosse (2 bois + 1 baie), Selle (4 bois + 2 pierres + 2 baies). On les modifie dans `scripts/items.gd`.

## Bac à sable : les commandes

| Action | Souris / trackpad | Clavier |
|---|---|---|
| Construire | Clic gauche (glisser pour les chemins, barrières, biomes, montagnes) | |
| Détruire | Clic droit ou Bulldozer | |
| Zoomer | Molette, pincement ou boutons « Zoom » | |
| Se déplacer | Glisser à deux doigts, ou clic molette + glisser | Flèches ou Z Q S D |
| Se promener, conduire (gardien, gyrosphère, jeep) | | Flèches ou Z Q S D, Échap pour arrêter |
| Piloter l'hélicoptère | | Flèches ou Z Q S D, Espace pour monter, Maj pour descendre, Échap pour sortir |

## Comment ça marche

Les règles sont celles de la version 3D (`~/dino-parc-3d`).

- **Le terrain** fait 128 × 96 cases, entouré d'une forêt, avec l'entrée à gauche. Une case mesure 16 pixels et représente 3 mètres. Chaque dinosaure a sa vraie taille : un Vélociraptor arrive à hauteur d'un visiteur, un T-Rex fait 4 cases de long. Les géants sont un peu réduits.
- **Les enclos** : toute zone entièrement fermée par des barrières (ou des montagnes) devient un enclos.
- **Les barrières** : Bambou, Bois, Pierre, Vitre, Béton et Électrique, de force 1 à 5. Un dinosaure plus fort finit par casser la barrière, surtout s'il a faim. On le rattrape avec la **Fléchette** (onglet Outils), après avoir réparé l'enclos.
- **Les biomes** : Prairie, Jungle (hautes herbes), Désert, Marais, Neige. Chaque dinosaure veut au moins la moitié de son enclos dans son biome préféré.
- **Les besoins** s'affichent dans une bulle au-dessus du dinosaure (« Faim ! », « Je veux de la jungle », « Trop serré ! »).
- **Volières et lagons** pour les dinosaures volants et les reptiles marins. Le Mosasaure saute hors de l'eau.
- **Les visiteurs** ne voient un enclos que si un chemin relié à l'entrée longe sa barrière.
- **Les transports** :
  - le **gardien** (« Se promener ») se balade à pied, et les dinosaures rugissent à son passage ;
  - la **gyrosphère** traverse les barrières pour rouler au milieu des dinosaures ;
  - la **jeep** roule sur l'herbe et les routes ;
  - l'**hélicoptère** décolle d'un héliport.

## Le modifier

| Envie | Où |
|---|---|
| Objets du sac, recettes, ce que donnent les arbres et rochers | `scripts/items.gd` |
| Objectifs de l'aventure | `scripts/main.gd` (`ADVENTURE_GOALS`) |
| Ce qui pousse dans chaque biome au début d'une aventure | `scripts/world_gen.gd` |
| Couleurs proposées pour le personnage | `scripts/creator.gd` |
| Prix, force, biome préféré, couleurs, taille d'un dinosaure | `scripts/catalog.gd` (`DINOS`) |
| Ajouter une espèce | Copier une entrée de `DINOS`, puis ajouter son id dans `CATEGORIES` |
| Dessin des dinosaures (cornes, plaques, voile, crête…) | `scripts/dino_art.gd` |
| Dessin du sol, des arbres, barrières, bâtiments, personnages | `scripts/art.gd` |
| Couleurs des biomes au sol | `scripts/art.gd` (`GROUND`) |
| Comportement (faim, évasion, vol, nage) | `scripts/dino.gd` |
| Objectifs, argent de départ, règles du parc | `scripts/main.gd` |
| Interface (couleurs des cadres, boutons) | `scripts/hud.gd` |

`scripts/painter.gd` est le petit outil de dessin. On lui donne des ellipses, des tubes et des polygones ; il ajoute tout seul l'ombre, la lumière et le contour foncé qui donnent le style pixel art.

## Jouer sur la tablette (version web)

Le jeu est publié sur GitHub Pages. Sur la tablette, ouvrir l'adresse du jeu dans Chrome,
puis menu ⋮ → « Ajouter à l'écran d'accueil » : il s'ouvre ensuite en plein écran comme une appli.
Les mondes et leurs sauvegardes restent dans le navigateur de la tablette.
Quand une nouvelle version est publiée, elle s'installe toute seule : à la prochaine ouverture,
l'écran titre affiche « Nouvelle version du jeu ! » et recharge le jeu (les mondes sont gardés).

### Publier une mise à jour

- On travaille sur la branche `main` : pousser dessus ne change rien en ligne.
- Avant de publier, ajouter les nouveautés en haut de `scripts/news.gd`, avec le numéro de version
  suivant et des phrases courtes qu'un enfant comprend (une image par nouveauté). Elles s'affichent
  une fois sur chaque appareil (« Quoi de neuf ? »), et le bouton « Nouveautés » les remontre toutes.
  Le numéro de version est écrit en bas à droite de l'écran titre.
- Pour publier : `git push origin main:release`. GitHub exporte la version web et la met en
  ligne en 2 à 3 minutes (onglet « Actions » du dépôt pour suivre).
- Pour revenir en arrière : `git push --force origin <commit>:release`.

### Tester la version web en local

```
godot --headless --export-release "Web" build/web/index.html
cd build/web && python3 -m http.server 8765   # puis http://localhost:8765
```
