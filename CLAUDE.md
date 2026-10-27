# Dino Parc Pixel — règles du projet

Jeu Godot 4.7 fait par Kevin avec ses enfants. Le CLAUDE.md global (Flutter) ne s'applique pas ici.

- Code et commentaires en anglais ; textes du jeu et README en français, simples, pour des enfants.
- Tout est dessiné par code (`scripts/art.gd`, `scripts/dino_art.gd`) : pas d'images importées.
- Style graphique : rustique, en vue de trois-quarts pour les bâtiments (façade + un mur de côté
  dans l'ombre + pente du toit). Matières communes dans `art.gd` : `LOG`, `THATCH`, `LEAVES`,
  `STONES` et les textures `_logs`, `_planks`, `_stones`, `_thatch`, `_leaf_roof`, `_moss`,
  `_block3q`. Personnages en pixel art lettre par lettre (`hero`, `dino_folk`), 4 images de marche.
- Chaque monde a son dossier `user://worlds/<id>/` (voir `scripts/worlds.gd`). Un nouveau réglage
  de monde = une ligne dans `Worlds.SETTINGS`, lue avec `park.setting("clé")`.
- La carte d'aventure grandit **par zones** (`scripts/village.gd`, `scripts/mine.gd`) : une zone est
  construite quand on y entre et libérée quand on en sort ; `main.away` est la zone en cours.
- Publication : `main` = travail, `release` = en ligne (GitHub Actions → GitHub Pages).
- **Avant chaque publication sur `release`**, ajouter une entrée en haut de `scripts/news.gd`
  (version suivante, titre, une phrase courte par nouveauté avec une image) : c'est ce que
  les enfants lisent dans « Quoi de neuf ? ».
- Tester sans toucher aux sauvegardes de Kevin : copie du projet avec un autre `config/name`.
