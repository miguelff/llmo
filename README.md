# LLMO

A web application to analyze and optimize the relevance of brands, products and services in Large Language Models, and AI-based search engines.

## Prerequisites

-   Ruby 3.x
-   Rails 8.0.0
-   SQLite3 or another compatible database
-   Node.js and Yarn (for managing frontend dependencies)

## Setup

1. **Clone the repository**:

    ```bash
    git clone https://github.com/miguelff/llmo.git
    cd llmo
    ```

2. **Install dependencies**:

    ```bash
    bundle install
    yarn install
    ```

3. **Set up the database**:

    ```bash
    rails db:create
    rails db:migrate
    ```

4. **Run the application**:

    ```bash
    rails server
    ```

5. **Access the application**:
   Open your web browser and go to `http://localhost:3000`.

## Testing

Run the test suite using:

```
bin/rails test:all test:system
```

## Deployment

To deploy the application on Fly.io, follow these steps:

1. **Install Fly CLI**:

    If you haven't already, install the Fly CLI by following the instructions on the [Fly.io documentation](https://fly.io/docs/getting-started/installing-flyctl/).

2. **Authenticate with Fly.io**:

    ```bash
    flyctl auth login
    ```

3. **Create and configure a new Fly.io application**:

    ```bash
    flyctl launch
    ```

    Follow the prompts to set up your application. This will create a `fly.toml` configuration file in your project directory.

4. **Set up the database**:

    Fly.io supports PostgreSQL databases. You can create a new PostgreSQL database instance using:

    ```bash
    flyctl postgres create
    ```

    Follow the prompts to set up your database. Once created, connect your application to the database by setting the `DATABASE_URL` environment variable.

5. **Deploy the application**:

    ```bash
    flyctl deploy
    ```

6. **Run database migrations**:

    After deploying, run the database migrations on Fly.io:

    ```bash
    flyctl ssh console -C "bin/rails db:migrate"
    ```

7. **Access the application**:

    Once the deployment is complete, you can access your application using the URL provided by Fly.io.

For more detailed instructions and advanced configurations, refer to the [Fly.io documentation](https://fly.io/docs/rails/getting-started/).
