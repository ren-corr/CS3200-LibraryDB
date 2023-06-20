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
  wait_time DATE,
  patron_id INT,
  FOREIGN KEY (book_id) REFERENCES book(book_id),
  FOREIGN KEY (patron_id) REFERENCES patron(library_card_number),
  FOREIGN KEY (wait_time) REFERENCES loan(due_date)
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


-- add all procedures and functions

-- place a book on hold
DROP PROCEDURE IF EXISTS createHold;
DELIMITER //
CREATE PROCEDURE createHold(
  IN p_book_id INT,
  IN p_patron_id INT,
  IN p_wait_time INT
)
BEGIN
  DECLARE availability_status TINYINT;

  -- check if the book exists and is available
  SELECT available INTO availability_status
  FROM book
  WHERE book_id = p_book_id;

  IF availability_status = 1 THEN
    -- check if the book is already checked out
    IF EXISTS (SELECT 1 FROM loans WHERE book_id = p_book_id) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book is already checked out';
    ELSE
      -- check if the patron exists
      IF NOT EXISTS (SELECT 1 FROM patron WHERE library_card_number = p_patron_id) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Patron does not exist';
      END IF;

      -- insert the hold
      INSERT INTO hold (book_id, wait_time, patron_id)
      VALUES (p_book_id, p_wait_time, p_patron_id);

      -- display success message
      SELECT 'Hold created successfully' AS Message;
    END IF;
  ELSE
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Book is not available';
  END IF;
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

-- add book to database
DROP PROCEDURE IF EXISTS addBook;
DELIMITER //
CREATE PROCEDURE addBook(
	IN p_title VARCHAR(50),
    IN p_author VARCHAR(50),
    IN p_genre VARCHAR(50),
    IN p_description VARCHAR(50),
    IN p_total_copies INT,
    IN p_available TINYINT
)
BEGIN
	-- insert book into book table
    INSERT INTO book(title, author, genre, book_description, total_copies, available)
    VALUES (p_title, p_author, p_genre, p_description, p_total_copies, p_available);
    
    SELECT 'Book added sucessfully!' AS MESSAGE;
END //
DELIMITER ;


-- remove book from database
DROP PROCEDURE IF EXISTS removeBook;
DELIMITER //
CREATE PROCEDURE removeBook(IN p_book_id INT)
BEGIN 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        RESIGNAL;
	END;
    
    START TRANSACTION;
    
    -- delete book from loans
    DELETE FROM loans
    WHERE book_id = p_book_id;
    
    -- rollback overdue fees
    DELETE FROM overdueFees
    WHERE book_id = p_book_id;
    
    -- rollback all holds
    DELETE FROM hold
    WHERE book_id = p_book_id;
    
    -- delete from copies table
    DELETE FROM numCopies
    WHERE book_id = p_book_id;
    
    -- delete from author table
    DELETE FROM book_author 
    WHERE book_id = p_book_id;
    
    -- delete book-author relationship
    DELETE FROM book_author
    WHERE book_id = p_book_id;
    
    -- delete from book table
    DELETE FROM book
    WHERE book_id = p_book_id;
    
    COMMIT;
    
    SELECT 'Book removed successfully!' AS MESSAGE;
END //
DELIMITER ;

-- show all of the user's overdue fees
DROP PROCEDURE IF EXISTS checkOverdueFees;
DELIMITER //
CREATE PROCEDURE checkOverdueFees(p_patron_id INT)
BEGIN	
	DECLARE num_fees INT;

    SELECT COUNT(*) INTO num_fees
    FROM overdueFees
    WHERE p_patron_id= overdueFees.patron_id;
    
    IF num_fees = 0 THEN
		SELECT 'No overdue fees!' AS MESSAGE;
	ELSE
		SELECT *
        FROM loans
        WHERE patron_id = user;
	END IF;
END //
DELIMITER ;

-- register new patron
DROP PROCEDURE IF EXISTS newPatron;
DELIMITER //
CREATE PROCEDURE newPatron(
IN p_pin_number INT,
IN p_first_name VARCHAR(50),
IN p_last_name VARCHAR(50),
IN p_address VARCHAR(50)
)
BEGIN
	DECLARE p_library_card_number INT;
    
    -- check if patron already exists
    IF EXISTS (
		SELECT 1 FROM patron
        WHERE pin_number = p_pin_number
        AND first_name = p_first_name
        AND last_name = p_last_name
        AND address = p_address) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patron already exists.';
	ELSE
		SET p_library_card_number = LAST_INSERT_ID();

		-- insert new patron
		INSERT INTO patron(library_card_number, pin_number, first_name, last_name, address)
		VALUES (p_library_card_number, p_pin_number, p_first_name, p_last_name, p_address);
        
		SELECT 'Patron added successfully!' AS MESSAGE, p_library_card_number AS library_card_number;
	END IF;
END //
DELIMITER ;


DROP FUNCTION IF EXISTS loginLib;
DELIMITER //
CREATE FUNCTION loginLib(p_username VARCHAR(50), p_password VARCHAR(50))
RETURNS INT
DETERMINISTIC READS SQL DATA
BEGIN
	DECLARE p_librarian_id INT;

	-- check if username and password exist in librarian table
    SELECT librarian_id INTO p_librarian_id
    FROM librarian
    WHERE username = p_username AND password = p_password;
    
    IF p_librarian_id IS NULL THEN
		RETURN 0;
	ELSE 
		RETURN p_librarian_id;
	END IF;
END//
DELIMITER ;
	
DROP FUNCTION IF EXISTS loginPatron;
DELIMITER //
CREATE FUNCTION loginPatron(p_pin INT)
RETURNS INT
DETERMINISTIC READS SQL DATA
BEGIN
	DECLARE p_library_card_number INT;
    
	-- check if patron already exists
    SELECT library_card_number INTO p_library_card_number
    FROM patron
    WHERE pin = p_pin;
    
    IF p_library_card_number IS NULL THEN
		RETURN 0;
	ELSE
		RETURN p_library_card_number;
	END IF;
END //
DELIMITER ;








