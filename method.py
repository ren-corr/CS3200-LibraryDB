## METHOD: CONTAINS ALL THE METHODS SUPPORTED BY THE APPLICATION
## TRANG DO, REN CORR, MORGAN SPENCER

## ####################################################################

import pymysql
import pandas as pd

## ####################################################################
# Contains all methods supported by the application
class Method:

    # Hook the application to the library database.
    # Print a success message if connected, and an error message if otherwise
    def connectDB(self):
        while True:             # TODO: remove the while loop since the login for MySQL will be provided
            sqlname = input("Please enter your MySQL username: ")
            sqlpass = input("Please enter your MySQL password: ")

            ## Use the user provided username and password values to connect to the sharkDB database.
            try:
                cnx = pymysql.connect(host='localhost', user=sqlname,
                                        password=sqlpass,
                                    db='sharkdb', charset='utf8mb4',
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

    # Check if the user provided credentials is in the database via username and password (pre-existing user)
    def existingUser(self, cnx, username: str, password: str):
        try:
            ## Creating a cursor object
            cur = cnx.cursor()
            login_select = "SELECT * FROM login"

            ## Retrieve the list of credentials
            cur.execute(login_select)
            login = cur.fetchall();

            cur.close()

        except pymysql.Error as e:
            print('Error: %d: %s' % (e.args[0], e.args[1]))

        invalidInput = True
        while invalidInput:     # TODO: check if need to have this while loop or request the user to return to this function later
            # Check if the provided username and password combo is registered in the server
            for row in login:
                if username.lower() == row['username'] and password.lower() == row['password']:
                    invalidInput = False
                    break
                else:
                    continue
            else:
                print("This login credential might not have been registered. Please register as a member or try again\n")

    # Check if the new username is not in the database
    def checkUsername(self, cnx, username):
        try:
            ## Creating a cursor object
            cur = cnx.cursor()
            user_select = "SELECT username FROM login"

            ## Retrieve the list of credentials
            cur.execute(user_select)
            user = cur.fetchall();

            cur.close()

        except pymysql.Error as e:
            print('Error: %d: %s' % (e.args[0], e.args[1]))

        invalidInput = True
        while invalidInput:     # TODO: check if need to have this while loop or request the user to return to this function later
            # Check if the provided username and password combo is registered in the server
            for row in user:
                if username == row['username']:
                    print('This username already existed in the database. Please try a different username\n')
                    return 0
                else:
                    continue
            else:
                print("The username %s can be used to create a new account\n", username)
                return 1

    # Creating new user account (new user)
    def newUser(self, cnx, first, last, address, username, password):
        try:
            # Check if the current name already existed in the database
            check = self.checkUsername(cnx, username)

            ## Creating a cursor object
            cur = cnx.cursor()
            login_select = "SELECT * FROM login"

            ## Retrieve the list of credentials
            cur.execute(login_select)
            login = cur.fetchall();                          # store all township values in var

            cur.close()

        except:
            print('Error: Unable to create the new user')

    # Check all functionalities of the application
    def showComms(self, cnx):
        try:
            ## Creating a cursor object
            cur = cnx.cursor()
            comms_select = "SELECT * FROM command"

            ## Retrieve the list of town (township table)
            cur.execute(comms_select)
            comms = cur.fetchall();                          # store all township values in var

            cur.close()

        except pymysql.Error as e:
            print('Error: %d: %s' % (e.args[0], e.args[1]))

        ## Print list of acceptable inputs for pair of town and state
        print("List of supported commands:\n")
        data = pd.DataFrame(comms)
        print(data)

    # Handle command input from the user
    def processComms(self, cnx):
        userInput = input("Please input the id of the command you want to proceed with: ")

        
    # Check all books available in the library

    # Return data of a book given its isbn

    # Checks out a book given its isbn

    # Check all books currently checked out by the user

    # Disconnect the database
    def disconnectDB(self, cnx):
        print("Thank you for using the library management application!\n")
        cnx.close

