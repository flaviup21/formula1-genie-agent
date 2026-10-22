# Databricks notebook source
# MAGIC %md
# MAGIC # Apply Unity Catalog tags
# MAGIC Bundle `presets.tags` only covers jobs and pipelines. This task sets the same governed
# MAGIC tag on the Unity Catalog objects: the schema, its volumes, the gold tables and the metric view.

# COMMAND ----------

dbutils.widgets.text("catalog", "formula1")
dbutils.widgets.text("schema", "f1genie")
dbutils.widgets.text("tag", "f1genie")

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
tag = dbutils.widgets.get("tag")

fq_schema = f"`{catalog}`.`{schema}`"
tag_clause = f"SET TAGS ('{tag}')"

# COMMAND ----------

spark.sql(f"ALTER SCHEMA {fq_schema} {tag_clause}")
tagged = [fq_schema]

for v in spark.sql(f"SHOW VOLUMES IN {fq_schema}").collect():
    name = f"{fq_schema}.`{v.volume_name}`"
    spark.sql(f"ALTER VOLUME {name} {tag_clause}")
    tagged.append(name)

tables = spark.sql(
    f"SELECT table_name, table_type FROM `{catalog}`.information_schema.tables WHERE table_schema = '{schema}'"
    " AND table_name NOT LIKE '\\_\\_%'"  # skip pipeline-internal __materialization_* tables
).collect()
for t in tables:
    name = f"{fq_schema}.`{t.table_name}`"
    kind = {"MATERIALIZED_VIEW": "MATERIALIZED VIEW", "METRIC_VIEW": "VIEW", "VIEW": "VIEW"}.get(t.table_type, "TABLE")
    spark.sql(f"ALTER {kind} {name} {tag_clause}")
    tagged.append(name)

print("\n".join(tagged))
dbutils.notebook.exit(f"Tagged {len(tagged)} objects with '{tag}'")
