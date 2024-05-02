--Question 1: The database has one superuser. Write a query that allows you to determine the name of that role.
SELECT rolname FROM pg_roles WHERE rolsuper ='true';

--Question 2: What are the names of the other users in the database? What permissions do these roles have (e.g. rolcreaterole, rolcanlogin, rolcreatedb, etc.)?
SELECT rolname
FROM pg_catalog.pg_roles;

--Question 3: With the name of the superuser, check the name of the role you’re currently using. Is this role the superuser?
SELECT current_user;

--Question 4: Create a login role named abc_open_data without superuser permissions.
CREATE ROLE abc_open_data WITH NOSUPERUSER LOGIN;

--Question 5: Create a non-superuser group role named publishers and include abc_open_data as a member.
CREATE ROLE publishers WITH NOLOGIN ROLE abc_open_data;

--Question 6: There’s a schema in the database named analytics. All publishers should have access to this schema. Grant USAGE on this schema to publishers
GRANT USAGE ON SCHEMA analytics TO publishers;

--Question 7: Now that publishers has USAGE, write the query that grants publishers the ability to SELECT on all existing tables in analytics.
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO publishers;

--Question 8: Check to see how PostgreSQL has recorded the changes to the schema permissions you just updated. Query the information schema table table_privileges to check whether abc_open_data has SELECT on analytics.downloads. Do you think abc_open_data or publishers will appear in this table?
SELECT *
FROM information_schema.table_privileges 
WHERE grantee = 'publishers';

--Question 9: Let’s confirm that abc_open_data has the ability to SELECT on analytics.downloads through inheritance from publishers. This is important because we’ll want to manage most publishers’ permissions through the group role publishers instead of the role for each publisher.
SET ROLE abc_open_data;

SELECT * FROM analytics.downloads
LIMIT 10;

SET ROLE ccuser;

--Question 10: There is a table named directory.datasets in the database with the following schema. SELECT from this table to see a few sample rows.
SELECT * FROM directory.datasets LIMIT 3;

--Question 11: Grant USAGE on directory to publishers. This statement should be almost identical to the way that we granted USAGE on analytics.
GRANT USAGE ON SCHEMA directory TO publishers;

--Question 12: Let’s write a statement to GRANT SELECT on all columns in this table (except data_checksum) to publishers.
GRANT SELECT (id, create_date, hosting_path, publisher, src_size) 
ON TABLE directory.datasets 
TO publishers;

--Question 13: Let’s mimic what might happen if a publisher tries to query the dataset directory for all dataset names and paths. SET the role of your current session to abc_open_data and try the query below.

--SELECT id, publisher, hosting_path, data_checksum 
--FROM directory.datasets

--Why is this query failing? Can you remove a column from this query so that it’s successful? Remember to SET your role back to ccuser after this section.

SET ROLE abc_open_data;

SELECT id, publisher, hosting_path FROM directory.datasets;

SET ROLE ccuser;


--Question 14: Although we’re designing a collaborative data environment, we may want to implement some degree of privacy between publishers. Let’s implement row level security on analytics.downloads. Create and enable policy that says that the current_user must be the publisher of the dataset to SELECT.

CREATE POLICY user_check_policy
ON analytics.downloads 
FOR SELECT TO publishers USING 
(current_user = owner);

ALTER TABLE analytics.downloads ENABLE ROW LEVEL SECURITY;

--Question 15: Write a query to SELECT the first few rows of this table. 

SELECT * FROM analytics.downloads LIMIT 5;


--Now SET your role to abc_open_data and re-run the same query, are the results the same?
SET ROLE abc_open_data;
SELECT * FROM analytics.downloads LIMIT 5;
--Only rows of information where abc_open_data as owner is seen. 