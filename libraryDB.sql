-- create the database
DROP DATABASE IF EXISTS libraryDB;
CREATE DATABASE libraryDB;

-- select the database
USE libraryDB;

-- create the tables
CREATE TABLE book
(
  book_id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(50) UNIQUE,
  author VARCHAR(50),
  genre VARCHAR(50),
  book_description VARCHAR(50),
  total_copies INT,
  available TINYINT
);

CREATE TABLE library
(
  library_id INT PRIMARY KEY,
  address VARCHAR(50),
  city VARCHAR(50) NOT NULL,
  state CHAR(2) NOT NULL,
  zip_code VARCHAR(20) NOT NULL,
  phone_number VARCHAR(50)
);

CREATE TABLE patron
(
  library_card_number INT PRIMARY KEY,
  pin_number INT,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  address VARCHAR(50)
);

CREATE TABLE librarian
(
  librarian_id INT PRIMARY KEY,
  branch INT UNIQUE,
  username VARCHAR(50),
  password VARCHAR(50),
  FOREIGN KEY (branch) REFERENCES library(library_id)
);

CREATE TABLE hold
(
  hold_id INT PRIMARY KEY,
  book_id INT,
  wait_time INT,
  patron_id INT,
  FOREIGN KEY (book_id) REFERENCES book(book_id),
  FOREIGN KEY (patron_id) REFERENCES patron(library_card_number)
);

CREATE TABLE overdueFees
(
  book_id INT,
  days_overdue INT,
  amt_owed INT,
  patron_id INT,
  PRIMARY KEY (book_id, patron_id),
  FOREIGN KEY (book_id) REFERENCES book(book_id),
  FOREIGN KEY (patron_id) REFERENCES patron(library_card_number)
);

CREATE TABLE loans
(
  loan_id INT PRIMARY KEY,
  patron_id INT,
  book_id INT,
  loan_date DATE,
  due_date DATE,
  FOREIGN KEY (patron_id) REFERENCES patron(library_card_number),
  FOREIGN KEY (book_id) REFERENCES book(book_id)
);

CREATE TABLE numCopies
(
  copy_id INT PRIMARY KEY AUTO_INCREMENT,
  book_id INT NOT NULL,
  FOREIGN KEY (book_id) REFERENCES book(book_id)
);

CREATE TABLE author
(
  author_id INT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  book_id INT NOT NUll,
  FOREIGN KEY (book_id) REFERENCES book(book_id)
);

CREATE TABLE book_author
(
  book_id INT NOT NULL,
  author_id INT NOT NULL,
  PRIMARY KEY (book_id, author_id),
  FOREIGN KEY (book_id) REFERENCES book(book_id),
  FOREIGN KEY (author_id) REFERENCES author(author_id) 
);
