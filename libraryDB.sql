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

-- place a book on hold
DELIMITER //
CREATE PROCEDURE createHold(
  IN p_book_id INT,
  IN p_patron_id INT,
  IN p_wait_time INT
)
BEGIN
  -- check if the book exists
  IF NOT EXISTS (SELECT 1 FROM book WHERE book_id = p_book_id) THEN
    SIGNAL SQLSTATE '45000' -- reccomended for custom error messages 
      SET MESSAGE_TEXT = 'Book does not exist';
  END IF;
  
  -- check if the patron exists
  IF NOT EXISTS (SELECT 1 FROM patron WHERE library_card_number = p_patron_id) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Patron does not exist';
  END IF;

  -- insert the hold
  INSERT INTO hold (book_id, wait_time, patron_id)
  VALUES (p_book_id, p_wait_time, p_patron_id);

 -- hold sucsessfully placed 
  SELECT 'Hold created successfully' AS Message;
END //
DELIMITER ;

-- test call (change later)
CALL createHold(123, 1, 3);


-- check out book
DROP PROCEDURE IF EXISTS bookCheckout;
DELIMITER //
CREATE PROCEDURE bookCheckout(IN p_book_id INT, IN p_patron_id INT)
BEGIN
    DECLARE availability_status TINYINT;
    DECLARE v_loan_id INT;

    -- check if the book exists and is available
    SELECT available INTO availability_status
    FROM book
    WHERE book_id = p_book_id;
    
    IF availability_status = 1 THEN
        -- set the book as unavailable
        UPDATE book
        SET available = 0
        WHERE book_id = p_book_id;

        -- generate a new loan_id
        SELECT IFNULL(MAX(loan_id), 0) + 1 INTO v_loan_id
        FROM loans;

        -- insert a new loan record
        INSERT INTO loans (loan_id, patron_id, book_id, loan_date, due_date)
        VALUES (v_loan_id, p_patron_id, p_book_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 2 WEEK));

        SELECT 'Title borrowed successfully!' AS Message;
    ELSE
        SELECT 'Title not available.' AS Message;
    END IF;
END //
DELIMITER ;


-- return book
DROP PROCEDURE IF EXISTS returnBook;
DELIMITER //
CREATE PROCEDURE returnBook(
  IN p_book_id INT,
  IN p_patron_id INT
)
BEGIN
	DECLARE p_days_overdue INT;
    
	IF EXISTS (SELECT * FROM loans WHERE book_id = p_book_id) THEN
	  -- calculate days overdue
	  SELECT DATEDIFF(CURRENT_DATE(), due_date) INTO p_days_overdue
	  FROM loans
	  WHERE book_id = p_book_id AND patron_id = p_patron_id;
      
      -- handle early returns
      IF p_days_overdue <= 0 THEN
		SET p_days_overdue = 0;
	  END IF;
	  
	  -- update overdueFees table
	  UPDATE overdueFees
	  SET days_overdue = p_days_overdue, amt_owed = p_days_overdue * .15
	  WHERE book_id = p_book_id AND patron_id = p_patron_id;
	  
	  -- update book availability
	  UPDATE book
	  SET available = 1
	  WHERE book_id = p_book_id;
	  
	  -- delete book from loans
	  DELETE FROM loans
	  WHERE book_id = p_book_id AND patron_id = p_patron_id;
	  SELECT 'Book returned successfully.' AS MESSAGE;
	  -- 
	  IF p_days_overdue > 0 THEN
		SELECT amt_owed
		FROM overdueFees;
		END IF;
	ELSE
		SELECT 'Book not found in loans' AS MESSAGE;
    END IF;
END //
DELIMITER ;


-- show all books being borrowed by the user
DROP PROCEDURE IF EXISTS booksBorrowed;
DELIMITER //
CREATE PROCEDURE booksBorrowed(user INT)
BEGIN	
	DECLARE num_loans INT;

    SELECT COUNT(*) INTO num_loans
    FROM loans
    WHERE user = loans.patron_id;
    
    IF num_loans = 0 THEN
		SELECT 'No current loans!' AS MESSAGE;
	ELSE
		SELECT *
        FROM loans
        WHERE patron_id = user;
	END IF;
END //
DELIMITER ;


-- show what books are available
DROP PROCEDURE IF EXISTS booksAvailable;
DELIMITER //
CREATE PROCEDURE booksAvailable()
BEGIN
    SELECT *
    FROM book
    WHERE available = 1;
END //
DELIMITER ;

-- call test (delete later)
CALL booksAvailable();

-- search for book information given book_id
DROP PROCEDURE IF EXISTS bookInfo;
DELIMITER //
CREATE PROCEDURE bookInfo(IN p_book_id INT)
BEGIN
    SELECT *
    FROM book
    WHERE book_id = p_book_id;
END //
DELIMITER ;

-- showComms procedure(need to add)
-- newUser procedure(need to add)

