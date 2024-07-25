import sqlparse
import argparse
import os

# Create the parser
parser = argparse.ArgumentParser(description="Validate SQL script")

# Add the arguments
parser.add_argument('--sql_script', type=str, required=True, help='The SQL script file path to be validated')

# Parse the arguments
args = parser.parse_args()

# Function to check if the parsed SQL is a DDL or DML statement
def is_ddl_or_dml(parsed):
    for statement in parsed:
        if statement.get_type() not in ['UNKNOWN', '']:
            return True
    return False

# Read the SQL script content
if not os.path.isfile(args.sql_script):
    print(f"Error: The file '{args.sql_script}' was not found.")
    exit(1)

try:
    with open(args.sql_script, 'r') as file:
        sql_script_content = file.read()
        print(f"Validating SQL script located at: {args.sql_script}")
        print(f"Script Content:\n{sql_script_content}\n")
except Exception as e:
    print(f"Error reading file '{args.sql_script}': {e}")
    exit(1)

# Parse the SQL script
try:
    parsed = sqlparse.parse(sql_script_content)
    if is_ddl_or_dml(parsed):
        print("The SQL script is a DDL or DML statement.")
    else:
        print("The SQL script is not a DDL or DML statement.")
        exit(1)
except Exception as e:
    print(f"Unexpected error during parsing: {e}")
    exit(1)