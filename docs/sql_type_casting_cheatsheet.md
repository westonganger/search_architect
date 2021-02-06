# Active Record Search Architect

## SQL Type Casting Cheatsheet

- Numbers:
  - `CAST(posts.number AS VARCHAR)`
- Date / Time:
  - Postgresql, Oracle
    - `TO_CHAR(posts.created_at, 'YYYY-mm-dd')`
  - MySQL
    - `DATE_FORMAT(posts.created_at, '%Y-%m-%d')`
  - SQLite
    `strftime(posts.created_at, '%Y-%m-%d')`

## CASE Statements in WHERE Clauses

Apparently ANSI SQL has the restriction where you cannot use SQL `CASE` statements in `WHERE` clauses.

For example if you were trying to search a `boolean` by the string of its column name:

`CASE WHEN users.admin IS TRUE THEN 'admin' ELSE  '' END`

You will find it extremely difficult to work around this. Instead I strongly recommend handling your booleans seperately from the searching / search string.
