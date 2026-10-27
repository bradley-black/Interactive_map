# Been There Atlas

A travel map for you and your friends: colour in the countries you've visited, pin cities, and document trips step by step with photos, Polarsteps-style.

## What's in here

- `been-there-atlas.html`: the page published as a Claude artifact (AI trip chat, saves to your Claude account).
- `standalone/`: the website version (OpenStreetMap street view, accounts and photos through Supabase). See `standalone/SETUP.md` to put it online.
- `countries.json`, `cities.json`, `earth.jpg`: map data, the city list used for search, and NASA's Blue Marble satellite image.

## Try the website version on this computer

```bash
uv run interactive-map
```

This opens it at http://localhost:8000. Accounts and photos work once you've filled in `standalone/config.js`.
