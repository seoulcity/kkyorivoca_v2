# GenPub

## Deploying to Vercel

### Option 1: Automatic Deployment with GitHub

1. Push your code to a GitHub repository
2. Go to [Vercel](https://vercel.com) and sign in with your GitHub account
3. Click "Add New..." and select "Project"
4. Select your GitHub repository
5. Vercel will automatically detect SvelteKit and configure the build settings
6. Configure the following environment variables in the Vercel dashboard (under Project Settings > Environment Variables):
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

The project is set up to use PostgreSQL via a direct connection. The database client in `src/lib/db.ts` provides methods for querying the database.
