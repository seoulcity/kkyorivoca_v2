# ${SERVICE_TITLE}

## Service Configuration

The application uses the following environment variables for configuration:

- `VITE_SERVICE_TITLE`: The name of your service displayed throughout the application (default: "GenPub")
- `VITE_SERVICE_EMAIL`: The contact email address for your service (default: "contact@genpub.com")
- `VITE_SITE_URL`: The base URL of your application for OAuth redirects (default: "https://genpub.vercel.app")
- `VITE_SUPABASE_URL`: Your Supabase project URL
- `VITE_SUPABASE_ANON_KEY`: Your Supabase anonymous API key
- Database connection variables (see Database Connection section below)

You should set these variables in your `.env` file and in your deployment environment.

## Google Authentication Setup

This application uses Google OAuth for authentication via Supabase. To set up Google authentication:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to "APIs & Services" > "Credentials"
4. Click "Create Credentials" > "OAuth client ID"
5. Set up the OAuth consent screen if prompted:
   - User Type: External (or Internal if applicable)
   - App name: (Your service name)
   - User support email: (Your email)
   - Developer contact information: (Your email)
6. Back in Credentials, set up the OAuth client ID:
   - Application type: Web application
   - Name: (Your application name)
   - Authorized JavaScript origins: Add your domain(s), e.g., `https://yourapp.vercel.app` and `http://localhost:5173` for development
   - Authorized redirect URIs: Add your Supabase redirect URI(s):
     - `https://[YOUR_SUPABASE_PROJECT_ID].supabase.co/auth/v1/callback`
     - `http://localhost:5173/api/auth/callback` (for local development)
7. Click "Create" and note your Client ID and Client Secret
8. In your Supabase dashboard:
   - Go to Authentication > Providers > Google
   - Enable Google authentication
   - Enter the Client ID and Client Secret from Google
   - Save changes

After setting up Google authentication, update your `.env` file with the correct `VITE_SITE_URL` value.

## Deploying to Vercel

### Option 1: Automatic Deployment with GitHub

1. Push your code to a GitHub repository
2. Go to [Vercel](https://vercel.com) and sign in with your GitHub account
3. Click "Add New..." and select "Project"
4. Select your GitHub repository
5. Vercel will automatically detect SvelteKit and configure the build settings
6. Configure the following environment variables in the Vercel dashboard (under Project Settings > Environment Variables):
   - `VITE_SERVICE_TITLE` (Your application name)
   - `VITE_SERVICE_EMAIL` (Your contact email address)
   - `PG_HOST` (Your PostgreSQL host - e.g., aws-0-us-west-1.pooler.supabase.com)
   - `PG_PORT` (Your PostgreSQL port - e.g., 6543)
   - `PG_DATABASE` (Your database name - e.g., postgres)
   - `PG_USER` (Your database user - e.g., postgres.xxutdsucpupczamwqqdv)
   - `PG_PASSWORD` (Your database password)
7. Click "Deploy"

### Option 2: Manual Deployment with Vercel CLI

1. Install the Vercel CLI:
   ```
   npm install -g vercel
   ```

2. Login to Vercel:
   ```
   vercel login
   ```

3. Deploy the project using the deployment script:
   ```
   ./deploy.sh
   ```
   
   The script will:
   - Log you into Vercel if needed
   - Load PostgreSQL environment variables from your `.env` file
   - Deploy the project to Vercel

4. After deployment, add your environment variables in the Vercel dashboard if you didn't have a local `.env` file.

## Development

1. **Node.js Version Requirements**

   This project requires Node.js version 18, 20, or 22 (recommended: 20.x).
   
   If you're currently using Node.js 23.x, you can install a compatible version using the provided script:
   
   ```
   ./install-node.sh
   ```
   
   This will install nvm (Node Version Manager) and Node.js 20.x.
   
   Alternatively, you can download Node.js 20.x from the [official website](https://nodejs.org/).

2. Install dependencies:
   ```
   npm install
   ```

3. Start the development server:
   ```
   npm run dev
   ```

## Database Connection

The project is set up to use PostgreSQL via a connection to Supabase. The database client in `src/lib/db.ts` provides methods for querying the database.

### Supabase Connection Options

Configure your `.env` file with one of the following connection options:

#### Option 1: Direct Connection
Ideal for applications with persistent, long-lived connections, such as those running on virtual machines or long-standing containers.

```
PG_HOST=db.ratynnxfnxvaejekupga.supabase.co
PG_PORT=5432
PG_DATABASE=postgres
PG_USER=postgres
PG_PASSWORD=[YOUR-PASSWORD]
DATABASE_URL=postgresql://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:${PG_PORT}/${PG_DATABASE}
```

#### Option 2: Transaction Pooler / Shared Pooler
Ideal for stateless applications like serverless functions where each interaction with Postgres is brief and isolated.

```
PG_HOST=aws-0-ap-northeast-2.pooler.supabase.com
PG_PORT=6543
PG_DATABASE=postgres
PG_USER=postgres.ratynnxfnxvaejekupga
PG_PASSWORD=[YOUR-PASSWORD]
DATABASE_URL=postgresql://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:${PG_PORT}/${PG_DATABASE}
```

Choose the connection option that best fits your deployment environment:
- Use Option 1 (Direct connection) for traditional applications with persistent connections
- Use Option 2 (Transaction pooler) for serverless or functions-based applications where connections are brief and isolated

Remember to replace `[YOUR-PASSWORD]` with your actual Supabase database password.

You'll also need to set up these environment variables in your Vercel project settings when deploying.
