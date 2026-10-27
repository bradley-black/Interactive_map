# Schlepped There Atlas

A travel map for you and your friends: colour in the countries you've visited or fill them with photos, keep a bucket list, collect flags and dive into US states and Canadian provinces, pin cities, and document trips step by step with photos and transport, Polarsteps-style. Friends can follow each other with approval, and like and comment on each other's trips. Works on phones held either way up.

## What's in here

- `been-there-atlas.html`: the page published as a Claude artifact (AI trip chat, saves to your Claude account).
- `standalone/`: the website version (OpenStreetMap street view, plus accounts, photos and following through Supabase). See `standalone/SETUP.md` to put it online.
- `countries.json`, `regions-map.json`, `cities.json`, `flags.json`, `earth.jpg`: country outlines, US state and Canadian province outlines, the city list used for search, flag images, and NASA's Blue Marble satellite image.
- `index.html` (top level): a copy of `standalone/index.html` that GitHub Pages serves.
- `src/interactive_map/`: two small commands, below.

## Commands

Try the website version on this computer:

```bash
uv run interactive-map
```

This opens it at http://localhost:8000. Accounts and photos work once you've filled in `standalone/config.js`.

Check how much of the free Supabase plan is used:

```bash
uv run interactive-map-usage
```

## Licence

The code is released under the [MIT licence](LICENSE). The bundled data and images keep their own licences, listed below.

## Credits

- Country, state and province outlines: [Natural Earth](https://www.naturalearthdata.com/) (public domain).
- City list: [GeoNames](https://www.geonames.org/) (CC BY 4.0).
- Satellite image: NASA Blue Marble (public domain).
- Country flags: [flag-icons](https://github.com/lipis/flag-icons) by Panayiotis Lipiridis (MIT).
- US state and Canadian province flags: [Wikimedia Commons](https://commons.wikimedia.org/). Most are public domain government symbols; check each file's page there before reusing them elsewhere.
- Street map: © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors.
