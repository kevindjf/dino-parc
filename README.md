# Dino Parc Pixel

Le parc de dinosaures en 2D, vu de dessus, en pixel art façon console portable des années 2000. Tous les dessins (dinosaures, arbres, barrières, bâtiments, personnages) sont faits dans le code : il n'y a aucune image à fournir.

## Lancer le jeu

- Dans Godot : **Importer**, choisir `project.godot`, puis **F5**.
- En ligne de commande : `godot --path ~/dino-parc-pixel`
- Avec un parc de démonstration déjà construit : `godot --path ~/dino-parc-pixel -- --demo`

## Deux façons de jouer

L'écran titre affiche **Mes mondes**, comme dans Minecraft : on reprend un monde en le touchant, on le supprime (avec confirmation), ou on **crée un nouveau monde**. Un monde a un nom et un mode de jeu :

- **Aventure** : on crée son personnage, un petit explorateur ou une petite exploratrice avec son chapeau de brousse (prénom, peau, cheveux courts ou queue de cheval, couleurs du chapeau, de la chemise et du short), puis on le dirige dans un parc sauvage. On frappe les arbres pour avoir du bois, on casse les rochers avec la pioche pour avoir de la pierre et on cueille des baies. Ensuite on fabrique ses outils et ses barrières dans le sac, et on les pose soi-même. Des objectifs guident les premiers pas.
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

Chaque massif de montagnes a une **entrée de mine** creusée dans sa falaise sud. Il suffit de marcher dedans (vers le haut) pour descendre. Les échelles se prennent pareil, en marchant dessus.

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
- L'ambre et les fossiles servent au **laboratoire** pour faire naître des bébés dinos.

Une partie commencée sur l'ancienne petite carte est replacée telle quelle près de l'entrée, avec la nouvelle carte autour.

## Aventure : les Terres sauvages

Ton parc n'est que le début : il est au milieu d'un monde de **7 × 7 zones**, chacune aussi grande que le parc. Sors par les **sentiers tout autour du parc** (panneaux « Terres sauvages ») : 3 en haut, 3 en bas, 2 à gauche à côté de la route du village, et à droite une digue de sable qui traverse la mer ; dans les zones sauvages, il suffit de marcher jusqu'au bord pour passer à la suivante. L'hélicoptère passe d'une zone à l'autre en volant.

- Plus on va **au nord**, plus il fait froid (neige, sapins) ; **au sud**, la jungle ; **à l'ouest**, les marais ; **à l'est**, le désert. Les zones se raccordent entre elles.
- Les **étoiles** à côté du nom de la zone disent si elle est loin du parc : plus il y en a, plus les **gros dinosaures et les espèces rares** sont fréquents.
- Certaines zones ont des **montagnes avec une mine**.
- Dans les zones sauvages, on peut poser des **feux de camp, des ponts et des chemins**. Les enclos se construisent seulement dans le parc.
- Pendant que tu explores, le parc continue : en rentrant, les visiteurs venus entre-temps ont payé leur billet.

### La mer et le ciel

- **Tout à l'est du monde, c'est la mer** : une côte de sable, puis le large avec des îles. Le **bateau** (15 bois, ou 500 pièces à la boutique avec un parc ★★) se met à l'eau face à l'eau avec Action ; face à la rive, Action pour descendre. En bateau, on passe d'une zone de mer à l'autre.
- La **canne à pêche** (2 bois + 1 baie) : face à l'eau, Action pour pêcher des **poissons** (et parfois un fossile !). Ça marche aussi depuis le bateau. On peut griller les poissons au feu de camp.
- Les **dinos volants** tournent dans le ciel des zones sauvages, chacun au-dessus de son biome (le Ptérodactyle dans la neige, le Quetzalcoatlus dans les plaines…). Les **reptiles marins** nagent là où l'eau est assez large pour eux : le Plésiosaure dans les lacs, les géants (Mosasaure, Liopleurodon…) seulement dans la mer.
- Pour les avoir : **lance-leur des poissons** (le poisson grillé compte double) jusqu'à ce qu'ils te fassent confiance (plus ils sont gros, plus il en faut), ou fatigue-les avec une arme puis lance une capsule. Un volant épuisé se pose par terre, un marin flotte à la surface.
- Dans le parc, ils vivent dans une **volière** (8 × 8 cases, 20 bois + 8 fer) ou un **lagon** (12 × 8 cases, 25 pierres + 4 cristaux), aussi vendus à la boutique. Relâche-les dedans depuis « Mes dinos ».

### Les feux de camp

Chaque zone sauvage cache un ou deux **vieux feux de camp éteints**. Mets-toi devant et appuie sur Action pour l'allumer. On peut aussi en fabriquer (3 bois + 3 pierres) et les poser où on veut.

Devant un feu allumé, Action ouvre son menu :
- **Se reposer** : tous tes cœurs reviennent ;
- **Griller une viande** → viande grillée, et **faire une tarte** avec 2 baies → tarte aux baies. Les dinosaures les aiment **deux fois plus** : elles comptent double pour les apprivoiser et pour l'amitié ;
- **Voyager avec la carte**.

Si un dinosaure te fait trop peur, tu te réveilles **près du dernier feu de camp** où tu t'es arrêté.

### La carte

Le bouton **Carte** (en haut) montre le monde : les zones visitées en couleur, les autres en gris avec « ? », le parc, l'endroit où tu es, et les feux allumés. **Touche le parc pour rentrer**, ou une zone avec un feu allumé pour y aller tout de suite (pas depuis une mine ni le village).

Le monde se règle dans `scripts/wild.gd` (taille, climat, noms des zones) et `scripts/world_gen.gd` (`generate_zone`).

## Aventure : les étoiles du parc

Ton parc gagne des **étoiles**, de 1 à 5, affichées en haut à gauche à côté de ton nom. Elles montent avec les **espèces montrées aux visiteurs** (un dinosaure dans un enclos le long d'un chemin relié à l'entrée, ou dans une volière ou un lagon ouverts) et les **visiteurs accueillis** :

| Étoiles | Espèces montrées | Visiteurs | Cadeau | Nouveau à la boutique |
|---|---|---|---|---|
| ★ | 1 | 0 | 100 pièces | |
| ★★ | 3 | 50 | 300 pièces | moto, laboratoire |
| ★★★ | 6 | 300 | 600 pièces | voiture, capsule en or, fusil à lunette |
| ★★★★ | 10 | 1000 | 1000 pièces | hélicoptère |
| ★★★★★ | 15 | 3000 | 2000 pièces | |

Une étoile gagnée reste pour toujours, et chacune augmente le **prix du billet** de 5 pièces (10 sans étoile). Tout se règle dans `scripts/main.gd` (`STARS`) et `scripts/market.gd` (colonne `stars`).

## Aventure : le jour, la nuit et les orages

- Une journée dure **10 minutes**. La nuit, tout devient bleu sombre (jamais trop noir) : ta lampe éclaire autour de toi et les **feux de camp** brillent.
- De temps en temps, un **orage** éclate pendant une minute : pluie, éclairs, « BOUM ! ». Tes dinos ont peur et **poussent leurs barrières** : pendant l'orage, seule une barrière plus forte qu'eux les retient (ou une barrière électrique). Prépare tes enclos !
- Quand un dinosaure s'échappe, une **flèche rouge** au bord de l'écran montre où il est. Endors-le avec ton lance-pierre ou tes fléchettes : il est ramené dans son enclos.

Le temps se règle dans `scripts/weather.gd` (`DAY`, `STORM_TIME`).

## Aventure : le laboratoire

Le **laboratoire** se fabrique (10 bois + 8 pierres + 2 fer + 1 cristal) ou s'achète au village (600 pièces), et se pose dans le parc. Devant lui, Action ouvre sa fenêtre. Il couve **un œuf à la fois** :

- **Œuf mystère** : 2 fossiles + 1 ambre. Une surprise ! Les espèces pas encore dans le Dinodex sortent plus souvent.
- **Œuf trouvé dans la nature** : dans les Terres sauvages, des **nids** cachent un œuf (plus souvent loin du parc). Action devant le nid pour le prendre.
- **Faire naître un dino du Dinodex** : plus il est gros, plus il faut de fossiles et d'ambre (un T-Rex : 6 fossiles + 3 ambres).

L'œuf couve de 1 à 2 minutes selon l'espèce, même si tu pars explorer, et le dôme du laboratoire montre l'œuf. Quand il est prêt, « Faire éclore ! » : le **bébé** naît devant le laboratoire. Il est petit, il t'aime déjà (3 cœurs) et **il te suit** : emmène-le dans un enclos pour qu'il y habite. Il **grandit en 4 minutes** ; une fois grand, on peut lui mettre une selle.

Les fossiles et l'ambre se trouvent au fond des mines (niveaux 2 et 3). Tout se règle dans `scripts/main.gd` (`MYSTERY_EGG`, `clone_cost`, `hatch_time`) et `scripts/dino.gd` (`GROW_TIME`).

## Aventure : le village et la boutique

Sors du parc par le **portail, à gauche** (le panneau « ← Village ») : la route mène au village. On y va à pied, pas sur le dos d'un dinosaure.

- La **boutique** est sur la place. Mets-toi devant le marchand et appuie sur Action.
  - **Acheter** : capsules (même en or), flèches, bolas, fléchettes, **viande** (5 pour 25 pièces), mangeoire à viande, selle, brosse, pioche en fer, buissons, mangeoire, barrières électriques, fer, cristal, or.
  - **Vendre** : le bois, les pierres, les baies, les minerais et les fossiles qu'on a en trop.
- **Pour aller plus vite** (achetés une seule fois) :

| Achat | Prix | Vitesse (cases par seconde) |
|---|---|---|
| à pied | | 4 |
| Bottes | 80 | 5 |
| Bottes de course | 250 | 6 |
| Vélo | 150 | 8 |
| Moto | 400 | 11 |
| Voiture | 800 | 14 |
| Hélicoptère | 1500 | 16 |

  - Les bottes marchent toutes seules dès qu'elles sont dans le sac.
  - Un véhicule se prend en main comme un outil : Action pour monter, Action pour descendre, et il retourne dans le sac. Il passe là où on passe à pied, et on ne se fait pas bousculer par les dinos.
  - L'**hélicoptère** décolle tout seul et vole au-dessus des arbres, de l'eau et des barrières. Action pour atterrir, sur une case libre.
- Les **pièces** viennent des visiteurs du parc, de la vente à la boutique et des coffres.
- Quatre **maisons abandonnées** cachent chacune un **coffre** : des pièces et un objet rare. Un coffre ne s'ouvre qu'une fois.
- Les **villageois sont des dinosaures habillés** (tricératops, raptors, ptéranodons, T-Rex), dessinés dans `scripts/art.gd` (`dino_folk`).
- **On entre dans les huit maisons** : il suffit de marcher vers la porte (Action devant la maison marche aussi). Chacune a son habitant (Mamie Rose, Marcel le boucher, Léa l'exploratrice…). Mets-toi devant lui et appuie sur Action pour parler : à la première visite, il te fait un **cadeau** (baies, viande, flèches, pièces…), ensuite il donne des conseils. Pour ressortir, passe la porte en bas. En véhicule, il faut d'abord descendre. Les habitants et leurs cadeaux sont dans `scripts/house.gd` (`RESIDENTS`).
- **Les quêtes** : après son cadeau, chaque habitant te demande quelque chose, trois fois de suite et de plus en plus dur. Par exemple, ramener des baies ou des fossiles, montrer un Parasaurolophus ou un T-Rex dans ton parc, explorer les Terres sauvages, monter sur un carnivore. Retourne le voir quand c'est fait pour ta récompense (pièces, capsules en or, seringues…). Le bouton **Quêtes** (en haut) rappelle tout ce qu'on te demande et où tu en es. Les quêtes sont dans `scripts/quests.gd`.
- Pour rentrer, suis la route vers la droite (le panneau « Parc → »). Le parc continue de vivre pendant ce temps : les visiteurs paient leur billet.

### Une carte en zones

Le monde grandit **zone par zone**, comme les mines : le village, une mine ou une zone des Terres sauvages est construit quand on y entre et oublié quand on en sort. Seule la zone où se trouve le joueur est en mémoire, donc le monde peut devenir très grand et tourner quand même sur une tablette. Chaque zone garde ce qui a changé (mines creusées, coffres ouverts) dans la sauvegarde.

## Aventure : le mode Construction

Le bouton orange **Construire** (ou la touche B) met le jeu en mode Construction : le personnage attend, une grille apparaît sur le sol, le joystick déplace la caméra et la barre du bas montre ce qu'on peut poser (ce qu'il y a dans le sac).

- **Tracer** : toucher le sol pose un objet ; avec des barrières, un chemin ou un pont, on dessine la ligne au doigt (ou à la souris), les angles se font tout seuls.
- **Enclos** : avec des barrières, on tire d'un coin à l'autre et tout le tour est posé, avec un portail au milieu du bas si on en a un dans le sac.
- **Gomme** : ce qu'on a construit retourne dans le sac. Les **buissons à baies** se déterrent et se replantent ailleurs. Les arbres et les rochers, eux, se coupent à la hache et se cassent à la pioche.
- **Annuler** reprend le dernier tracé, objets rendus.

Pendant qu'on dessine, les cases sont **vertes** si ça marche et **rouges** sinon, avec la raison en haut de la barre (« Il y a un arbre », « Pas sur l'eau ! », « Il en manque »…), et le compteur : « 23 × Barrière en bois (tu en as 30) ». Rien n'est posé avant de lever le doigt.

Les **gros bâtiments** (pour l'instant la mangeoire) ne sont pas prêts tout de suite : un échafaudage monte pendant 15 secondes, et **chaque tape dessus** fait gagner du temps. Une mangeoire en chantier ne nourrit pas encore les dinosaures. Plus tard, des employés du parc pourront construire à notre place.

L'ancienne façon marche toujours : objet en main, Action pose devant le personnage, et garder Action en marchant pose une barrière à chaque pas.

## Aventure : attraper les dinosaures

Des dinosaures sauvages vivent dans le parc, chacun dans son biome préféré : prairie, jungle, désert, marais ou neige. Les petits sont fréquents, les géants sont rares. Il y a deux façons de les attraper :

- **Apprivoiser un dinosaure avec à manger.** Les herbivores mangent des **baies**, les carnivores de la **viande** (achetée à la boutique). Prendre la nourriture en main : une cible rose se place sur le dinosaure le plus proche devant toi (jusqu'à 5 cases). Le bouton Action la lui lance ; au bout de 3 (5 pour un carnivore, plus méfiant), il est apprivoisé et saute tout seul dans **« Mes dinos »**, sans capsule. Il te suit alors partout, même à travers les barrières. Dès qu'il entre dans un enclos fermé, il y habite.
- **Le combat, puis la capsule**, pour tous les dinosaures. Personne n'est blessé : chaque tir fatigue le dinosaure, et une fois épuisé il s'endort. On lance alors une capsule dessus : il va dans « Mes dinos ».

**« Mes dinos »** (bouton en haut) garde tous les dinosaures attrapés, à part du sac à objets. On touche « Relâcher » : le dinosaure passe dans la main, on vise une case libre dans un enclos et on appuie sur Action. Une fois relâché, la case de la barre d'outils retrouve l'objet qu'elle avait avant.

**Le combat se joue de loin, en direct.** Avec une arme en main, une cible apparaît sur le dinosaure sauvage le plus proche devant toi, avec sa barre d'énergie. On peut aussi **toucher un dinosaure** sur l'écran (ou cliquer dessus sur ordinateur) : le personnage se tourne vers lui et tire, et il reste la cible tant qu'il est à portée. Le bouton Action tire (garder appuyé pour tirer en continu) :

| Arme | Effet | Munitions |
|---|---|---|
| Lance-pierre | bon sur les petits, chatouille les gros | les pierres du sac |
| Arc | moyen partout, de loin (8 cases) | les flèches |
| Lance | très forte, mais il faut être tout près (2 cases) | aucune |
| Sarbacane | fatigue sans que le dinosaure s'enfuie ni ne fonce | les fléchettes |
| Fléchettes endormantes | fatiguent beaucoup, lancées à la main | elles-mêmes |
| Fusil à lunette | tire de très loin (20 cases), fait pour les géants | les seringues |
| Bolas | bloquent le dinosaure 4 secondes | elles-mêmes |
| Filet | bloque 7 secondes, jusqu'à la force 3 | lui-même |

Chaque arme a sa force selon la taille du dinosaure : il faut 3 tirs de fusil pour endormir un T-Rex, mais des dizaines de cailloux. L'**ankylosaure** et le **stégosaure** ont une carapace : les cailloux, les flèches et la sarbacane rebondissent dessus, il faut la lance, les fléchettes ou le fusil. Tout se règle dans `scripts/items.gd` (`WEAPONS`, colonne `power`).

Les petits herbivores s'enfuient quand on les touche ; les carnivores et les gros herbivores (force 3 et plus) foncent sur toi. S'ils te touchent, tu perds un **cœur** (en haut de l'écran, il y en a 5, ils reviennent tout seuls). Sans cœur, tu te réveilles à l'entrée du parc, sans rien perdre. Si on le laisse tranquille 8 secondes, un dinosaure reprend des forces.

**Les capsules** se lancent de loin. Avec une capsule en main, une pastille de couleur sur la cible dit les chances : **verte** ça marche presque à coup sûr (dinosaure épuisé), **orange** peut-être, **rouge** presque jamais. La capsule tremble trois fois : elle tient, ou le dinosaure s'échappe (réveillé, un peu reposé, et la capsule est perdue). Chaque capsule a sa taille :

- **Capsule en cuivre** : jusqu'à la force 3 (Tricératops, Diplodocus, Vélociraptor…) ;
- **Capsule en fer** : jusqu'à la force 4 (Brachiosaure, Carnotaure, Yutyrannus) ;
- **Capsule en or** : tous, même le T-Rex et le Spinosaure.

La **cage** marche encore pour les petits dinosaures (force 1 et 2) : on la pose à la main sur un dinosaure endormi.

Les carnivores sauvages foncent sur toi s'ils te voient de près. Fermer une barrière autour d'un dinosaure sauvage marche aussi !

## Aventure : l'amitié et la monture

Les baies et la viande se lancent aussi aux dinosaures du parc pour gagner leur amitié. Un carnivore sauvage qui reçoit de la viande arrête de te foncer dessus un moment.

Chaque dinosaure du parc a de l'**amitié pour toi, de 0 à 5 cœurs**. Elle démarre à 0 cœur.

- **Le brosser** (brosse en main, Action devant lui) : tous les dinosaures aiment ça.
- **Lui donner des baies à la main**, pour les herbivores.
- Chaque soin ne marche qu'une fois toutes les 20 secondes : il faut revenir le voir. Les carnivores sont méfiants et demandent deux fois plus de soins.
- Toucher un dinosaure avec un autre objet en main affiche ses cœurs.

**La selle** : dès qu'un dinosaure de ton parc a **3 cœurs**, prends la selle en main et appuie sur Action devant lui : la selle est posée et tu montes tout de suite. Ensuite, Action devant lui (mains vides ou selle en main) pour remonter. Quand on prend la selle en main dans le sac, le jeu explique ces étapes. Il faut un dinosaure d'au moins 6 m : à partir du Gallimimus, du Tricératops ou du Dilophosaure. Sa vitesse dépend de l'espèce. Action fait descendre. Si tu descends hors de son enclos, il te suit jusqu'à ce que tu le ramènes. Sur un dinosaure au moins aussi fort qu'eux, les carnivores sauvages n'osent plus te foncer dessus.

Le **Dinodex** (bouton en haut) montre les 44 espèces : les ombres noires sont celles qu'il reste à attraper. Les volants et les reptiles marins s'attrapent dans le ciel et la mer des Terres sauvages.

Recettes : Feu de camp (3 bois + 3 pierres), Hache (3 bois), Pioche (4 bois), Barrières en bambou (1 bois → 2), en bois (2 bois → 2), en pierre (2 pierres → 2), Portail (3 bois), Chemin (1 pierre → 4), Mangeoire à plantes (4 bois + 3 baies), Mangeoire à viande (4 bois + 3 viandes), Lance-pierre (3 bois), Arc (5 bois), Flèches (1 bois + 1 pierre → 5), Fléchettes endormantes (1 bois + 2 baies → 3), Bolas (2 pierres + 1 bois → 2), Lance (3 bois + 2 pierres), Sarbacane (4 bois), Filet (2 bois + 2 baies → 2), Fusil à lunette (4 fer + 2 cristal + 2 bois), Seringues (1 fer + 2 baies → 3), Cage (4 bois + 2 pierres), Capsules en cuivre (2 cuivre + 1 pierre → 2), en fer (2 fer + 1 cuivre → 2), en or (1 or + 1 fer + 1 cristal), Brosse (2 bois + 1 baie), Selle (4 bois + 2 pierres + 2 baies). On les modifie dans `scripts/items.gd`.

## Le bestiaire : 44 espèces

| Biome | Herbivores | Carnivores |
|---|---|---|
| Prairie | Tricératops, Styracosaure, Pachycéphalosaure, Maiasaura, Diplodocus, Apatosaure | T-Rex, Allosaure |
| Jungle | Stégosaure, Kentrosaure, Iguanodon, Brachiosaure | Vélociraptor, Deinonychus, Microraptor, Dilophosaure |
| Désert | Ankylosaure, Protocératops, Gallimimus, Oviraptor, Argentinosaure | Carnotaure, Cératosaure, Giganotosaure |
| Marais | Parasaurolophus, Corythosaure | Spinosaure, Baryonyx |
| Neige | Pachyrhinosaure, Nodosaure, Stygimoloch | Yutyrannus, Utahraptor |

Volants (volière) : Ptéranodon, Quetzalcoatlus, Dimorphodon, Tapejara, Rhamphorhynchus, Ptérodactyle. Marins (lagon) : Mosasaure, Plésiosaure, Ichthyosaure, Liopleurodon, Elasmosaure.

Pour ajouter une espèce : une ligne dans `Catalog.DINOS` (nom, régime, biome, force, prix, taille, couleurs, particularités), une ligne dans `DinoHand.SPECIES` (la famille de dessin et sa taille), et son id dans `Catalog.CATEGORIES` pour le bac à sable. Les particularités qu'on peut combiner : collerette, collerette à pointes, cornes, corne sur le nez, plaques, pointes de queue, armure, massue, voile, double crête, plumes, rayures, museau de crocodile ; têtes de petits bipèdes : raptor, dôme, bec, bec de canard avec tube, avec casque ou sans crête.

## Bac à sable : les commandes

| Action | Souris / trackpad | Clavier |
|---|---|---|
| Construire | Clic gauche (glisser pour les chemins, barrières, biomes, montagnes) | |
| Détruire | Clic droit, bouton « Gomme » ou Bulldozer | |
| Enclos entier | Bouton « Enclos », une barrière choisie : tirer d'un coin à l'autre (portail au milieu du bas) | |
| Annuler le dernier tracé | Bouton « Annuler » (les pièces sont rendues) | |
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
| Ce que vend et achète la boutique, et à quel prix | `scripts/market.gd` |
| Vitesse des bottes et des véhicules | `scripts/items.gd` (`GEAR_SPEED`, `VEHICLES`) |
| Plan du village, contenu des coffres | `scripts/village.gd` (`HOUSES`, `RUINS`, `CHESTS`…) |
| Habitants des maisons, leurs cadeaux et leurs phrases | `scripts/house.gd` (`RESIDENTS`) |
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
