## MAIN: RUNS THE APPLICATION AND ACT AS A CONTROLLER
## TRANG DO, REN CORR, MORGAN SPENCER
## PYTHON USING PYMYSQL CONNECTION

## ####################################################################

import method


#############################################################################################

method = method.Method()

# Welcome message
print("Welcome to library managment application\n")

print("\nConnecting to the database...\n")
# Connect the application to the database
cnx = method.connectDB()

# Display the list of supported commands

# Disconnect from the database
method.disconnectDB(cnx)