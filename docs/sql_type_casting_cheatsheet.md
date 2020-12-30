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
