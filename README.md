# database-migrations-and-testing

This repo is a companion to the YouTube video: [Database Migrations and Testing Video](https://youtu.be/vf7hDdYJQoA), and it is a simple project to demonstrate how to use database migrations and testing in a NodeJS / Bun project.

I am using graphile-migrate for database migrations which is a tool that allows you to manage your PostgreSQL database schema using a simple version-controlled workflow.

Make sure to have a PostgreSQL database running.
In my case, I am using Crunchy Data's PostgreSQL Operator for Kubernetes, so the `demo-postgres.yaml` file is a Kubernetes manifest to deploy a PostgreSQL database. Note that this requires additional setup and is not required to run the project.

You just need to run a PostgreSQL database, and have a couple of users and databases created. You don't need to run it on Kubernetes.

You need toe following databases:
* demo -> this is the main database
* demo_shadow -> this is used by graphile-migrate to store the migration history and other metadata about the migrations.

As for database users:
* postgres -> this is the superuser, and it is used to be able to run the migrations in watch mode during **DEVELOPMENT**.
* demo_user -> this is the user that the application will use to connect to the database and run the actual migrations. This user should have access to both the `demo` and `demo_shadow` databases.

To install dependencies:

```bash
bun install
```

To run:

```bash
bun run gm --watch
```

This project was created using `bun init` in bun v1.0.26. [Bun](https://bun.sh) is a fast all-in-one JavaScript runtime.
