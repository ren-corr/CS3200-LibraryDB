-- create the database
DROP DATABASE IF EXISTS libraryDB;
CREATE DATABASE libraryDb;

-- select the database
USE libraryDB;

-- create the tables
CREATE TABLE book
(
  isbnNo        INT            PRIMARY KEY,
  title   VARCHAR(50)    UNIQUE,
  author   VARCHAR(50)    UNIQUE,
  genre   VARCHAR(50)    UNIQUE,
  book_description   VARCHAR(50)    UNIQUE,
  num_compies TINYINT -- tinyint is like boolean 
);

CREATE TABLE library
(
  library_id INT PRIMARY KEY,
  address               VARCHAR(50),
  city                   VARCHAR(50)    NOT NULL,
  state                  CHAR(2)        NOT NULL,
  zip_code               VARCHAR(20)    NOT NULL,
  phone_number                  VARCHAR(50)
  -- add a librarian FK and have a librarian table?
);

CREATE TABLE patron
(
  library_car_number INT PRIMARY KEY,
  pin_number              INT,
  first_name VARCHAR(50) UNIQUE,
  last_name VARCHAR(50) UNIQUE,
  address               VARCHAR(50),
  city                   VARCHAR(50)    NOT NULL,
  state                  CHAR(2)        NOT NULL,
  zip_code               VARCHAR(20)    NOT NULL,
  phone_number                  VARCHAR(50)
);

CREATE TABLE librarian
(
  librarian_id INT PRIMARY KEY,
  branch INT UNIQUE, -- FK with library_id in library table
  username VARCHAR(50),
  password VARCHAR(50)
);

CREATE TABLE hold
(
  isbnNo INT PRIMARY KEY,
  wait_time INT,
  patron_id INT -- FK with library_card_number in patron table
);

CREATE TABLE overdueFees
(
 isbnNo INT PRIMARY KEY,
 days_overdue INT,
 amt_owed INT,
 patron_id INT UNIQUE -- FK with library_card_number
);

CREATE TABLE loans
(
  loan_id INT PRIMARY KEY,
  patron_id INT UNIQUE, -- FK with patron table
  book_id INT, -- FK with isbnNo in book table
  loan_date DATE,
  due_date DATE
);
