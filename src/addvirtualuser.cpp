#include <iostream>
#include <mysql.h>

using namespace std;

MYSQL *conn;

#define D_HOST_NAME "localhost"
#define D_USER_NAME "cpanel"
#define D_PASSWORD "cPanel1"
#define D_DB_NAME "cpanel"

int main(int argc, char ** argv)
{
     conn = mysql_init(NULL);
    if (conn == NULL) 
    {
        cout << "mysql_init() failed" << endl;
        exit(1);
    }
    
    if(mysql_real_connect(conn, D_HOST_NAME, D_USER_NAME, D_PASSWORD, D_DB_NAME, 3306, NULL, 0) == NULL){
        cout << "mysql_real_connect() failed" << mysql_errno(conn) <<": "<< mysql_error(conn) << endl;
        exit(1);
    }
    
    mysql_close(conn);

    return 0;
}
