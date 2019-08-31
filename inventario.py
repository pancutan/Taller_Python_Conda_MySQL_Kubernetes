import mysql.connector

mydb = mysql.connector.connect(

    # Hacia el MySQL de la maquina real. No olvidar abrir 0.0.0.0
    #host="192.168.88.34",
    # port = "3306",

    # Hacia el MySQL del contenedor enlazado en docker-compose.yml
    host="db", # (requiere de un link en el docker-compose.yml)
    port = "3306",
    user="inventario_user",
    passwd="MiViejaMula",
    database="inventario"
)

mycursor = mydb.cursor()

mycursor.execute("SELECT * FROM amigos")

for x in mycursor:
    print(x)
