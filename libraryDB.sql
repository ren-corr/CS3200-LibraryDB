-- create the database
DROP DATABASE IF EXISTS libraryDB1;
CREATE DATABASE libraryDB1;

-- select the database
USE libraryDB1;

-- create the tables
CREATE TABLE book
(
  book_id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(50) UNIQUE,
  author VARCHAR(50),
  genre VARCHAR(50),
  book_description VARCHAR(250),
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
  library_card_number INT PRIMARY KEY AUTO_INCREMENT,
  pin_number INT UNIQUE,
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
  FOREIGN KEY (branch) REFERENCES library(library_id) ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE hold
(
  hold_id INT PRIMARY KEY,
  book_id INT,
  -- wait_time DATE,
  patron_id INT,
  FOREIGN KEY (book_id) REFERENCES book(book_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (patron_id) REFERENCES patron(library_card_number) ON UPDATE CASCADE ON DELETE CASCADE,
  -- FOREIGN KEY (wait_time) REFERENCES loans(due_date) ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE overdueFees
(
  book_id INT,
  days_overdue INT,
  amt_owed INT,
  patron_id INT,
  PRIMARY KEY (book_id, patron_id),
  FOREIGN KEY (book_id) REFERENCES book(book_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (patron_id) REFERENCES patron(library_card_number) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE loans
(
  loan_id INT PRIMARY KEY,
  patron_id INT,
  book_id INT,
  loan_date DATE,
  due_date DATE,
  FOREIGN KEY (patron_id) REFERENCES patron(library_card_number) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (book_id) REFERENCES book(book_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE numCopies
(
  copy_id INT PRIMARY KEY AUTO_INCREMENT,
  book_id INT NOT NULL,
  FOREIGN KEY (book_id) REFERENCES book(book_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE author
(
  author_id INT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  book_id INT NOT NUll,
  FOREIGN KEY (book_id) REFERENCES book(book_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE book_author
(
  book_id INT NOT NULL,
  author_id INT NOT NULL,
  PRIMARY KEY (book_id, author_id),
  FOREIGN KEY (book_id) REFERENCES book(book_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (author_id) REFERENCES author(author_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE showCommsLib
(
    comm_id INT PRIMARY KEY AUTO_INCREMENT,
    comm_name VARCHAR(50),
    comm_description VARCHAR(100)
);

CREATE TABLE showCommsPatron
(
    comm_id INT PRIMARY KEY AUTO_INCREMENT,
    comm_name VARCHAR(50),
    comm_description VARCHAR(100)
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
-- CALL createHold(123, 1, 3);


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
    
    IF availability_status != 0 THEN
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


-- test call
CALL bookCheckout(1, 2);

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

-- test call 
CALL returnBook(1, 2);

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

-- test call
CALL booksBorrowed(1);

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

-- test call
CALL bookInfo(1);

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

-- test call
CALL addBook('The Hobbit', 'J.R.R. Tolkien', 'Fantasy', 'An adventure of a hobbit and a group of dwarves', 1, 1);

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

-- test call
CALL removeBook(1);

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

-- test call
-- CALL checkOverdueFees(2);

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

-- test call
CALL newPatron(1234, 'Peter', 'Parker', '500 Water Street');

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

-- test call
SELECT loginLib('librarian1', 'password1');

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
    WHERE pin_number = p_pin;

    IF p_library_card_number IS NULL THEN
		RETURN 0;
	ELSE
		RETURN p_library_card_number;
	END IF;
END //
DELIMITER ;

-- test call
SELECT loginPatron(1234);

INSERT INTO book (title, author, genre, book_description, total_copies, available)
VALUES
  ('To Kill a Mockingbird', 'Harper Lee', 'Fiction', 'Classic novel set in the 1930s', 5, 3),
  ('1984', 'George Orwell', 'Fiction', 'Dystopian novel about totalitarianism', 8, 6),
  ('The Great Gatsby', 'F. Scott Fitzgerald', 'Fiction', 'American classic exploring the Jazz Age', 10, 10),
  ('Pride and Prejudice', 'Jane Austen', 'Fiction', 'Romantic novel set in 19th-century England', 6, 2),
  ('The Catcher in the Rye', 'J.D. Salinger', 'Fiction', 'Coming-of-age story of a teenager in New York City', 4, 1),
  ('To the Lighthouse', 'Virginia Woolf', 'Fiction', 'Modernist novel exploring themes of time and consciousness', 3, 3);
  
  -- Insert test data for library table
INSERT INTO library (library_id, address, city, state, zip_code, phone_number)
VALUES
  (1, '123 Main St', 'New York', 'NY', '10001', '123-456-7890'),
  (2, '456 Elm St', 'Los Angeles', 'CA', '90001', '987-654-3210');
  
INSERT INTO patron (library_card_number, pin_number, first_name, last_name, address)
VALUES
  (2, 2345, 'John', 'Doe', '123 Main St'),  -- TODO: fix the id of the patrons
  (3, 5678, 'Jane', 'Smith', '456 Elm St');
  
INSERT INTO librarian (librarian_id, branch, username, password)
VALUES
  (1, 1, 'librarian1', 'password1'),
  (2, 2, 'librarian2', 'password2');
  
-- fix hold FK situation

INSERT INTO overdueFees (book_id, days_overdue, amt_owed, patron_id)
VALUES
  (2, 10, 1.50, 1),
  (3, 5, 0.75, 2);
  
INSERT INTO loans (loan_id, patron_id, book_id, loan_date, due_date)
VALUES
  (1, 1, 2, '2023-06-10', '2023-06-24'),
  (2, 2, 3, '2023-06-12', '2023-06-26');
  
INSERT INTO numCopies (copy_id, book_id)
VALUES
  (1, 4),
  -- (2, 1),
  (3, 2),
  (4, 3);
  
INSERT INTO author (author_id, first_name, last_name, book_id)
VALUES
  -- (1, 'Harper', 'Lee', 1),
  (2, 'George', 'Orwell', 2),
  (3, 'F. Scott', 'Fitzgerald', 3),
  (4, 'Jane', 'Austen', 4),
  (5, 'J.D.', 'Salinger', 5),
  (6, 'Virginia', 'Woolf', 6);
  
INSERT INTO book_author (book_id, author_id)
VALUES
  -- (1, 1),
  (2, 2),
  (3, 3),
  (4, 4),
  (5, 5),
  (6, 6);
  
INSERT INTO showCommsLib(comm_name, comm_description)
VALUES
('addBook', 'Add a book to the database'),
('removeBook', 'Remove a book from the database'),
('booksAvailable', 'Show what books are available'),
('bookInfo', 'Show the information of a book');

INSERT INTO showCommsPatron(comm_name, comm_description)
VALUES
('booksAvailable', 'Show which books are available'),
('createHold', 'Place a hold on the book'),
('bookCheckout', 'Check out a book'),
('returnBook', 'Return a book'),
('booksBorrowed', 'See the books on loan'),
('checkOverdueFees', 'Check overdue fees'); 
 
-- select all books
SELECT * FROM book;

-- select books checked out for specific patron 
SELECT book.*
FROM book
JOIN loans ON book.book_id = loans.book_id
WHERE loans.patron_id = 1;
