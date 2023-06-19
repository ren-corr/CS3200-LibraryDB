## METHOD: CONTAINS ALL THE METHODS SUPPORTED BY THE APPLICATION
## TRANG DO, REN CORR, MORGAN SPENCER

## ####################################################################

import pymysql
import pandas as pd

## ####################################################################
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
                                    db='libraryDB', charset='utf8mb4',
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

    # Check all functionalities of the application
    def showComms(self):
        proc = 'showComms'
        args = ''

        print("List of supported commands:\n")
        self.printProc(proc, args)

    # Check all books available in the library
    def booksAvailable(self):
        proc = 'booksAvailable'
        args = ''

        self.printProc(proc, args)

    # Return data of a book given the book's ID
    def bookInfo(self):
        proc = 'bookInfo'
        bookID = input("Please provide the ID of the book which you would like to know more: ")

        self.printProc(proc, bookID)

    # Checks out a book given the book's ID
    def bookCheckout(self):
        proc = 'bookCheckout'
        bookID = input("Please provide the ID of the book you would like to check out: ")
        args = bookID + ", " + str(self.userID) 

        self.printProc(proc, args)
    
    # Request a hold on a book given the book's ID
    def createHold(self):
        proc = 'createHold'
        bookID = input("Please provide the ID of the book you would like to request a hold on: ")

        self.printProc(proc, bookID)

    # Check all books currently checked out by the user
    def booksBorrowed(self):
        proc = 'booksBorrowed'

        self.printProc(proc, str(self.userID))
    
    # Returns a book given its ID
    def returnBook(self):
        proc = 'returnBook'
        bookID = input("Please provide the ID of the book you would like to return: ")
        args = bookID + ", " + str(self.userID)

        self.printProc(proc, args)

    # Disconnect the database
    def disconnectDB(self):
        print("Thank you for using the library management application!\n")
        self.cnx.close

    # Handle command input from the user
    def processComms(self):
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
                self.showComms()

