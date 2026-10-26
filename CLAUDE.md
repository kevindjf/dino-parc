# Dino Parc Pixel — règles du projet

Jeu Godot 4.7 fait par Kevin avec ses enfants. Le CLAUDE.md global (Flutter) ne s'applique pas ici.

- Code et commentaires en anglais ; textes du jeu et README en français, simples, pour des enfants.
- Tout est dessiné par code (`scripts/art.gd`, `scripts/dino_art.gd`) : pas d'images importées.
- Chaque monde a son dossier `user://worlds/<id>/` (voir `scripts/worlds.gd`). Un nouveau réglage
  de monde = une ligne dans `Worlds.SETTINGS`, lue avec `park.setting("clé")`.
- Publication : `main` = travail, `release` = en ligne (GitHub Actions → GitHub Pages).
- **Avant chaque publication sur `release`**, ajouter une entrée en haut de `scripts/news.gd`
  (version suivante, titre, une phrase courte par nouveauté avec une image) : c'est ce que
  les enfants lisent dans « Quoi de neuf ? ».
- Tester sans toucher aux sauvegardes de Kevin : copie du projet avec un autre `config/name`.
