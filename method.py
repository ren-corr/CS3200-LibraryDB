## METHOD: CONTAINS ALL THE METHODS SUPPORTED BY THE APPLICATION
## TRANG DO, REN CORR, MORGAN SPENCER

## ####################################################################

import pymysql
import pandas as pd

## ####################################################################

# Ensuring that the input from the user is an int
# Given the prompt to the user
# Return a string of the user's input
def inputint(string: str):
    userInput = input(string)

    while not userInput.isdigit():
        userInput = input(string)

    return userInput

# Contains all methods supported by the application
class Method:
    def __init__(self) -> None:
        self.isRunning = True            # bool for whether the application is currently running
        self.userID = 0                  # int for storing user's ID
        self.isLibrarian = False         # bool for whether the user is a librarian. True: user is a librarian. False: user is a customer
        self.cnx = self.connectDB()       

    # Hook the application to the library database.
    # Print a success message if connected, and an error message if otherwise
    def connectDB(self):
        while True:             # TODO: remove the while loop since the login for MySQL will be provided
            sqlname = "root"
            sqlpass = "sujIObsa8239*"

            ## Use the user provided username and password values to connect to the sharkDB database.
            try:
                cnx = pymysql.connect(host='localhost', user=sqlname,
                                        password=sqlpass,
                                    db='libraryDB', charset='utf8mb4',         # TODO: Fix the name of the db
                                        cursorclass=pymysql.cursors.DictCursor)

                if cnx.open:
                    print("Successfully logged into library management MySQL server \n")
                    print("----------------------------------------------------------------------------")
                    return cnx
                
                else:
                    print("Connection to MySQL unsuccessful. Please double check your connection\n")

            ## Error signing in with the provided credentials
            except pymysql.err.OperationalError as e:
                print('Error: %d: %s' % (e.args[0], e.args[1]))

    # Call a procedure given a proc and args and print the result in a table
    def printProc(self, proc: str, args: str):
        try:
            ## Creating a cursor object
            cur = self.cnx.cursor()

            # Call the procedure
            cur.callproc(proc, args)

            # Fetch returned results
            result = cur.fetchall()

            # Print the result to the user
            df = pd.DataFrame(result)
            print(df)

            cur.close()

        except pymysql.Error as e:
            print('Error: %d: %s' % (e.args[0], e.args[1]))

    # Call a function given the function name and args and return the dict value of the function
    def runFunc(self, func: str, args: str):
        try:
            # Create a cursor object
            cur = self.cnx.cursor()

            # Prepare the SQL statement
            sql = f"SELECT {func}({args})"

            # Execute the function
            cur.execute(sql)

            # Fetch and return the result
            result = cur.fetchone()
            cur.close()

            return result
        
        except pymysql.Error as e:
            print('Error: %d: %s' % (e.args[0], e.args[1]))
            return 0

    # Print a table given its select statement
    def printTable(self, select: str):
        try:
            # Create the cursor object
            cur = self.cnx.cursor()

            # Retrieve the result table
            cur.execute(select)
            result = cur.fetchall()

            cur.close()

            # Print the data as a table
            data = pd.DataFrame(result)
            print(data)

        except pymysql.Error as e:
            print('Error: %d: %s' % (e.args[0], e.args[1]))

    # Disconnect the database
    def disconnectDB(self):
        print("Thank you for using the library management application!\n")
        self.cnx.close

    # Check all books available in the library
    def booksAvailable(self):
        proc = 'booksAvailable'
        args = ''

        self.printProc(proc, args)

    # Return data of a book given the book's ID
    def bookInfo(self):
        proc = 'bookInfo'
        bookID = inputint("Please provide the ID of the book which you would like to know more: ")

        self.printProc(proc, bookID)

    # Checks out a book given the book's ID
    def bookCheckout(self):
        proc = 'bookCheckout'
        bookID = inputint("Please provide the ID of the book you would like to check out: ")
        args = (bookID, self.userID) 

        self.printProc(proc, args)
    
    # Request a hold on a book given the book's ID
    def createHold(self):
        proc = 'createHold'
        bookID = inputint("Please provide the ID of the book you would like to request a hold on: ")
        args = (int(bookID), self.userID)

        self.printProc(proc, args)

    # Check all books currently checked out by the user
    def booksBorrowed(self):
        proc = 'booksBorrowed'

        self.printProc(proc, self.userID)
    
    # Returns a book given its ID
    def returnBook(self):
        proc = 'returnBook'
        bookID = input("Please provide the ID of the book you would like to return: ")
        args = (bookID, self.userID)

        self.printProc(proc, args)

    # Check the overdue fees of the current user
    def checkOverdueFees(self):
        proc = 'checkOverdueFees'

        self.printProc(proc, str(self.userID))

    # Add a book to the current database given all necessary fields
    def addBook(self):
        title = input("What is the title of the book you want to add? ")
        author = input("Who is the author of the book? ")
        genre = input("What is/are the genre(s) of the book? ")
        description = input("Please provide a short description to the book: ")
        copies = input("How many count of this book will be available in the database? ")
        available = True

        # Preparing the procedure
        proc = 'addBook'
        args = (title, author, genre, description, copies, available)

        self.printProc(proc, args)

    # Remove a book from the current database given the book's ID
    def removeBook(self):
        book = input("What is the ID of the book you would like to remove? ")

        # Preparing the procedure
        proc = 'removeBook'
        
        self.printProc(proc, book)

    # Create a new patron in the database
    def createPatron(self):
        # prompt to create a new user
        pin = inputint("Please provide a pin number you would like to use for logging in: ")
        first = input("What is your first name? ")
        last = input("What is your last name? ")
        address = input("Where do you live? ")

        proc = 'newPatron'
        args = (pin, first, last, address)

        try:
            ## Creating a cursor object
            cur = self.cnx.cursor()

            # Call the procedure
            cur.callproc(proc, args)

            # Print message
            print(cur.fetchone())

        except pymysql.err.OperationalError as e:
            print('Error: %d: %s' % (e.args[0], e.args[1]))

    # Logging in a user assuming that they are a returning patron
    def existPatron(self):
        func = 'loginPatron'        # TODO: confirm that the procedure has this name
        pin = input("What is the PIN of your patron account? ")

        # Retrieve the userID using the provided PIN
        retInput = f"{func}({pin})"
        self.userID = self.runFunc(func, pin).get(retInput)   

    # Handle login command input from the user
    def loginPatron(self):
        # indicate if the user is new or old member
        isNew = inputint("Please enter 1 if you would like to register as a new patron or 0 if you are an existing member: ")

        match isNew:
            case '1':
                # create new user
                self.createPatron()

                # loop back to the beginning
                self.loginPatron()

            case '0':
                # logging in the patron
                self.existPatron()

                # failed to login
                if self.userID <= 0:
                    print("Patron PIN not recognized in the database. Please try again\n")
                    self.loginPatron()
                else:
                    string = f"Successfully logged into the server! Welcome user {self.userID}!\n"
                    print(string)
            case _:
                print("Invalid input. Please try again\n")
                self.loginPatron()

    # TODO: Handle login command input from the user (librarian)
    def loginLib(self):
        username = input("Please provide your librarian's username: ")
        password = input("Please provide your librarian's password: ")

        func = 'loginLib'
        args = f"\'{username}\', \'{password}\'"
        retInput = f"{func}(\'{username}\', \'{password}\')"

        self.userID = self.runFunc(func, args).get(retInput)

        if self.userID <= 0:
            print("Login credentials not recognized in the database. Please try again\n")
            self.loginLib()
        else:
            string = f"Successfully logged in as a librarian! Welcome librarian {self.userID}!\n"
            print(string)

    # Show commands to the user (librarian)
    def showCommsLib(self):
        print("List of supported commands:\n")
        self.printTable("SELECT * FROM show_comms_lib")

    # Handle command input from the user (librarian)
    def processCommsLib(self):
        userInput = input("Please input the id of the command you want to proceed with: ")

        # Match the user input to the correct comm
        match userInput:
            case '0':
                self.isRunning = False
            case '1':
                self.addBook()
            case '2':
                self.removeBook()
            case '3':
                self.booksAvailable()
            case '4':
                self.bookInfo()
            case _:
                print("Invalid input. Please refer to the list of commands for the correct input\n")

    # Show commands to the user (patron)
    def showCommsPatron(self):
        print("List of supported commands:\n")
        self.printTable("SELECT * FROM show_comms_patron")

    # Handle command input from the user (patron)
    def processCommsPatron(self):
        userInput = input("Please input the id of the command you want to proceed with: ")

        # Match the user input to the correct comm
        match userInput:
            case '0':         # exits the program
                self.isRunning = False
            case '1':         # booksAvailable
                self.booksAvailable()
            case '2': 
                self.createHold()
            case '3':
                self.bookCheckout()
            case '4':
                self.returnBook()
            case '5':
                self.booksBorrowed()
            case '6':
                self.bookInfo()
            case '7':
                self.checkOverdueFees()
            case '8':
                self.showComms()
            case _:
                print("Invalid input. Please refer to the list of commands for the correct input\n")

