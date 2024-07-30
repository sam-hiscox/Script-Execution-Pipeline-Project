import os
import pytest
import pyodbc
import argparse

def get_connection_string():
    db_server = os.getenv('DB_SERVER', 'localhost')
    db_database = os.getenv('DB_DATABASE', 'testdb')
    db_trusted_connection = os.getenv('DB_TRUSTED_CONNECTION', 'yes')

    connection_string = (
        f'Driver={{SQL Server}};'
        f'Server={db_server};'
        f'Database={db_database};'
        f'Trusted_Connection={db_trusted_connection};'
    )
    return connection_string

@pytest.fixture(scope="module")
def db_connection():
    conn = pyodbc.connect(get_connection_string())
    yield conn
    conn.close()

def run_sql_script(cursor, script):
    commands = script.split(';')
    for command in commands:
        if command.strip():
            cursor.execute(command)
    cursor.commit()

def test_update_phone_number_success(db_connection):
    cursor = db_connection.cursor()

    # Prepare the database state
    cursor.execute("INSERT INTO SalesLT.Customer (CustomerID, Phone) VALUES (1, '000-000-0000')")
    db_connection.commit()

    # Read the SQL script
    with open('your_sql_script.sql', 'r') as file:
        sql_script = file.read()

    # Run the SQL script
    run_sql_script(cursor, sql_script)

    # Verify the phone number was updated
    cursor.execute("SELECT Phone FROM SalesLT.Customer WHERE CustomerID = 1")
    result = cursor.fetchone()
    assert result[0] == '123-123-1234'

def test_update_phone_number_failure(db_connection):
    cursor = db_connection.cursor()

    # Prepare the database state with a different CustomerID to ensure no updates happen
    cursor.execute("INSERT INTO SalesLT.Customer (CustomerID, Phone) VALUES (2, '000-000-0000')")
    db_connection.commit()

    # Read the SQL script
    with open('your_sql_script.sql', 'r') as file:
        sql_script = file.read()

    # Run the SQL script
    with pytest.raises(pyodbc.Error) as excinfo:
        run_sql_script(cursor, sql_script)

    # Verify the error message
    assert 'PHONE NUMBER NOT UPDATED' in str(excinfo.value)

    # Verify the phone number was not updated
    cursor.execute("SELECT Phone FROM SalesLT.Customer WHERE CustomerID = 2")
    result = cursor.fetchone()
    assert result[0] == '000-000-0000'

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run pytest with database connection parameters")
    parser.add_argument("--db-server", required=True, help="Database server name")
    parser.add_argument("--db-database", required=True, help="Database name")
    parser.add_argument("--db-trusted-connection", required=True, help="Trusted connection")

    args = parser.parse_args()

    # Set environment variables for pytest
    os.environ['DB_SERVER'] = args.db_server
    os.environ['DB_DATABASE'] = args.db_database
    os.environ['DB_TRUSTED_CONNECTION'] = args.db_trusted_connection

    # Run pytest
    pytest.main()
