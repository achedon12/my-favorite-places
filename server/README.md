# Server - My Favorite Places

Backend Node.js/TypeScript pour l'application My Favorite Places.

## 🚀 Quick Start

### Installation

```bash
npm install
```

### Développement

```bash
npm run dev
```

Le serveur démarre sur `http://localhost:3000`

### Build

```bash
npm run build
```

### Production

```bash
npm start
```

## 🧪 Tests

### Exécuter les tests

```bash
# Exécuter tous les tests
npm test

# Exécuter en mode watch
npm run test:watch

# Exécuter avec couverture
npm test -- --coverage
```

### Structure des tests

Les tests unitaires se trouvent dans:
- `src/__tests__/` - Tests d'intégration
- `src/controllers/__tests__/` - Tests des contrôleurs

Voir [TESTING.md](./TESTING.md) pour plus de détails.

## 📚 Documentation

- [TESTING.md](./TESTING.md) - Guide complet des tests
- [CONTRIBUTING_TESTS.md](./CONTRIBUTING_TESTS.md) - Guide pour écrire des tests

## 🏗️ Architecture

```
src/
├── index.ts              # Point d'entrée
├── app.ts                # Configuration Express
├── router.ts             # Routes
├── datasource.ts         # Configuration TypeORM
├── controllers/          # Contrôleurs (logique métier)
│   ├── Users.ts
│   ├── Addresses.ts
│   └── __tests__/       # Tests des contrôleurs
├── entities/             # Entités TypeORM
│   ├── User.ts
│   └── Address.ts
├── utils/               # Utilitaires
│   ├── isAuthorized.ts
│   └── getUserFromRequest.ts
└── __tests__/          # Tests d'intégration
```

## 🔐 Fonctionnalités

- **Authentification**: JWT avec argon2 pour le hachage des mots de passe
- **Gestion des utilisateurs**: CRUD utilisateurs
- **Gestion des adresses**: CRUD adresses associées aux utilisateurs
- **Base de données**: PostgreSQL avec TypeORM

## 📡 API Endpoints

### Utilisateurs

- `POST /api/users` - Créer un utilisateur
- `GET /api/users/me` - Récupérer mon profil (authentifié)
- `POST /api/users/tokens` - Se connecter (obtenir un token JWT)

### Adresses

- `GET /api/addresses` - Lister les adresses de l'utilisateur
- `POST /api/addresses` - Créer une adresse
- `PUT /api/addresses/:id` - Mettre à jour une adresse
- `DELETE /api/addresses/:id` - Supprimer une adresse

## 🛠️ Dépendances principales

- **express**: Framework web
- **typeorm**: ORM pour PostgreSQL
- **argon2**: Hachage sécurisé des mots de passe
- **jsonwebtoken**: Authentification JWT
- **jest**: Framework de test
- **ts-jest**: Support TypeScript pour Jest

## 📝 Variables d'environnement

```env
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=myuser
DATABASE_PASSWORD=mypassword
DATABASE_NAME=myfavoriteplaces
SESSION_SECRET=votre_secret_long_et_securise
NODE_ENV=development
```

## 🐳 Docker

```bash
# Build
docker build -t my-favorite-places-server .

# Run
docker run -p 3000:3000 my-favorite-places-server
```

## 📊 Couverture de code

Les tests couvrent:
- ✓ Création d'utilisateurs avec validation
- ✓ Hachage sécurisé des mots de passe
- ✓ Gestion des erreurs
- ✓ Opérations de base de données

Voir `TESTING.md` pour les détails.

## 🤝 Contribution

Avant de faire un commit:

1. Exécutez les tests: `npm test`
2. Compilez le TypeScript: `npm run build`
3. Consultez [CONTRIBUTING_TESTS.md](./CONTRIBUTING_TESTS.md) pour les standards de test

## 📄 License

MIT

