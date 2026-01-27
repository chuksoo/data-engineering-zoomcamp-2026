# Module 1 Homework: Docker & SQL

Solutions for Module 1 of the Data Engineering Zoomcamp.

## Question 1. Understanding Docker images

Run docker with the `python:3.13` image. Use an entrypoint `bash` to interact with the container.

What's the version of `pip` in the image?

- 25.3 ✅
- 24.3.1
- 24.2.1
- 23.3.1

**Answer: 25.3**

Step 1: Run the `python:3.13` image with `bash` as the entrypoint
```
docker run -it --rm --entrypoint=bash python:3.13
```
Step 2: Inside the container, check the pip version
```
root@a1237c5ecd07:/# pip --version
```
Output:
```
pip 25.3 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)
```

## Question 2. Understanding Docker networking and docker-compose

Given the following `docker-compose.yaml`, what is the `hostname` and `port` that pgadmin should use to connect to the postgres database?

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

- postgres:5433 
- localhost:5432
- db:5433
- postgres:5432
- db:5432 ✅ 

**Answer: db:5432**

Containers within the same Docker Compose network communicate using the **service name** and the **container's internal port**.

From the `docker-compose.yaml`:
- The Postgres service name is `db`
- Postgres listens on port `5432` inside the container
- The port mapping `5433:5432` is only used for host-to-container access

Since pgAdmin runs in the same Docker network as Postgres, it should connect using the service name (`db`) and the internal Postgres port (`5432`).

## Prepare the Data (Q3–Q6)

The goal is to load the datasets into PostgreSQL (running in Docker) so I can query them with SQL in pgAdmin.

**Step-by-Step Guide to Ingesting Zones Data**

To Start PostgreSQL + pgAdmin with Docker Compose

**Step 1: Set Up the Database Environment**

- **Start PostgreSQL and pgAdmin**

  Launch the database and admin interface in the homework directory
  ```bash
  docker-compose up -d
  ```

- **Verify containers are running**

  Use `docker ps` to confirm both `postgres` and `pgadmin` containers are up.
    
**Step 2: Build the Ingestion Docker Image**

- **Navigate to the homework directory**
  ```bash
  cd /workspaces/data-engineering-zoomcamp-2026/01-docker-terraform/homework
  ```
- **Build the image**
  ```bash
  docker build -t zone_ingest:v001 .
  ```
  *This creates a Docker image containing the Python script (zones_data.py) and its dependencies.*
      
**Step 3: Run the Data Ingestion Script**

- Execute the ingestion container for taxi zones:
```bash
docker run -it \
  --network=homework_default \
  zone_ingest:v001 \
  --pg_user=postgres \
  --pg_password=postgres \
  --pg_host=db \
  --pg_port=5432 \
  --pg_db=ny_taxi \
  --target_table=taxi_zones
```

Re-run for green trips
```bash
docker build -t taxi_ingest:v001 .
```

```bash
docker run -it \
  --network=homework_default \
  taxi_ingest:v001 \
  --pg_user=postgres \
  --pg_password=postgres \
  --pg_host=db \
  --pg_port=5432 \
  --pg_db=ny_taxi \
  --target_table=green_taxi_trips \
  --year=2025 \
  --month=11 \
  --chunksize=100000
```


**Step 4: Verify the Data Ingestion**

- **Connect to pgAdmin**: Add Port and open the forwarded port `http://127.0.0.1:8082/login?next=/` in your browser.
- **Login credentials**: Email: `pgadmin@pgadmin.com`, Password: `pgadmin`
- **Register server**:
  - Host: `db`
  - Port: `5432`
  - Database: `ny_taxi`
  - Username: `postgres`
  - Password: `postgres`
- **Query the data**: Run SQL `SELECT` query to confirm the data was loaded.
  
```sql
SELECT COUNT(*) FROM green_taxi_trips;
SELECT COUNT(*) FROM taxi_zones;
```

## Question 3. Counting short trips

For the trips in November 2025 (lpep_pickup_datetime between '2025-11-01' and '2025-12-01', exclusive of the upper bound), how many trips had a `trip_distance` of less than or equal to 1 mile?

- 7,853
- 8,007 ✅
- 8,254
- 8,421

**Solution: 8007**
```sql
SELECT COUNT(*)
FROM green_trips
WHERE lpep_pickup_datetime >= '2025-11-01'
AND lpep_pickup_datetime < '2025-12-01'
AND trip_distance <= 1;
```
Answer:
```
8007
```

## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance? Only consider trips with `trip_distance` less than 100 miles (to exclude data errors).

Use the pick up time for your calculations.

- 2025-11-14 ✅
- 2025-11-20
- 2025-11-23
- 2025-11-25

**Solution: 2025-11-14**

```sql
SELECT
  DATE(lpep_pickup_datetime) AS pickup_day
  , MAX(trip_distance) AS max_trip_distance
FROM green_trips
WHERE lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
  AND trip_distance < 100
GROUP BY DATE(lpep_pickup_datetime)
ORDER BY max_trip_distance DESC
LIMIT 1;
```

Answer:

| pickup_day | max_trip_distance |
| --- | --- |
| 2025-11-14 | 88.03 |

## Question 5. Biggest pickup zone

Which was the pickup zone with the largest `total_amount` (sum of all trips) on November 18th, 2025?

- East Harlem North ✅
- East Harlem South
- Morningside Heights
- Forest Hills

**Solution: East Harlem North**
```sql
SELECT
  t_zone."Zone" AS pickup_zone
  , SUM(trips.total_amount) AS largest_total_amount
FROM green_taxi_trips AS trips
JOIN taxi_zones AS t_zone
  ON trips."PULocationID" = t_zone."LocationID"
WHERE trips.lpep_pickup_datetime >= '2025-11-18'
  AND trips.lpep_pickup_datetime <  '2025-11-19'
GROUP BY t_zone."Zone"
ORDER BY largest_total_amount DESC
LIMIT 1;
```

Answer:
| pickup_zone | largest_total_amount |
| --- | --- |
| East Harlem North | 9281.919999999996 |

## Question 6. Largest tip

For the passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?

Note: it's `tip` , not `trip`. We need the name of the zone, not the ID.

- JFK Airport
- Yorkville West ✅
- East Harlem North
- LaGuardia Airport

**Solution: Yorkville West**

```sql
SELECT
  zone_drop."Zone" AS dropoff_zone
  , trips.tip_amount
FROM green_taxi_trips AS trips
JOIN taxi_zones AS zone_pick
  ON trips."PULocationID" = zone_pick."LocationID"
JOIN taxi_zones AS zone_drop
  ON trips."DOLocationID" = zone_drop."LocationID"
WHERE zone_pick."Zone" = 'East Harlem North'
  AND trips.lpep_pickup_datetime >= '2025-11-01'
  AND trips.lpep_pickup_datetime <  '2025-12-01'
ORDER BY trips.tip_amount DESC
LIMIT 1;
```

Answer:
| dropoff_zone | tip_amount |
| --- | --- |
| Yorkville West | 81.89 |


## Terraform

In this section, Terraform was used to provision the required GCP infrastructure for the course. 

The Terraform configuration can be found in: `01-docker-terraform/terraform/main.tf`

This setup includes two main files:

- `main.tf`: defines the GCP resources, including:
  - a Google Cloud Storage bucket 
  - a BigQuery dataset
- `variables.tf`: declares configurable variables such as the GCP project ID, region, bucket name, and dataset name

The configuration was successfully applied in my GCP project using Terraform. After running `terraform apply`, both the GCS bucket and BigQuery dataset were created and verified in the GCP Console.  
The resources were later removed using `terraform destroy`.


## Question 7. Terraform Workflow

Which of the following sequences, respectively, describes the workflow for:
1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform

Answers:
- terraform import, terraform apply -y, terraform destroy
- teraform init, terraform plan -auto-apply, terraform rm
- terraform init, terraform run -auto-approve, terraform destroy
- terraform init, terraform apply -auto-approve, terraform destroy  ✅
- terraform import, terraform apply -y, terraform rm

**Solution Explanation:**
- `terraform init` initializes the working directory by downloading provider plugins and setting up the backend.
- `terraform apply -auto-approve` generates the execution plan and applies the changes without requiring manual approval.
- `terraform destroy` removes all infrastructure resources by using the state file to decide what to destroy.







