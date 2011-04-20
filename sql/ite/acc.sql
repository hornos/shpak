DROP TABLE IF EXISTS acc;

CREATE TABLE acc (
  acc       varchar(512) PRIMARY KEY NOT NULL,
  pass      text,
  ctime     date,
  mtime     date
);
