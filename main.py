## MAIN: RUNS THE APPLICATION AND ACT AS A CONTROLLER
## TRANG DO, REN CORR, MORGAN SPENCER
## PYTHON USING PYMYSQL CONNECTION

## ####################################################################

import method
from method import inputint

#############################################################################################

# Welcome message
print("Welcome to library managment application\n")

print("\nConnecting to the database...\n")

# create the method object (which is the controller)
# also establish a connection to the MySQL server
method = method.Method()

# Prompt user type indication to the user
isPatron = inputint("Please enter 1 if you are logging in as a patron and 0 if otherwise\n")

# Display the list of supported commands accordingly
match isPatron:
    case '1':       # user is a patron
        # process login
        method.loginPatron()

        # print list of commands
        method.showCommsPatron()

        # process input
        while method.isRunning:
            method.processCommsPatron()
    
    case '0':       # user is a librarian
        # process login
        method.loginLib()
        
        # print list of commands
        method.showCommsLib()

        # process input
        while method.isRunning:
            method.processCommsLib()

    case _:
        print("Invalid input. \n")
        method.disconnectDB()

if not method.isRunning:
    # Disconnect from the database
    method.disconnectDB()