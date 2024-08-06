import sqlparse
import argparse
import os

# Create the parser which checks through the SQL script
parser = argparse.ArgumentParser(description="Validate SQL script")

# Add the arguments needed to retrieve the SQL script
parser.add_argument('--sql_script', type=str, required=True, help='The SQL script file path to be validated')

# Parse the arguments from the command line
args = parser.parse_args()

# Function to check if the parsed SQL is a DDL or DML statement
def is_ddl_or_dml(parsed):
    for statement in parsed:
        if statement.get_type() not in ['UNKNOWN', '']:
            return True
    return False

# Function to read and parse the SQL script
def read_and_parse_script(file_path):
    if not os.path.isfile(file_path):
        raise FileNotFoundError(f"Error: The file was not found at '{file_path}', please check the repository and ensure the runtime variable was set.")

    # Open the file with read mode
    with open(file_path, 'r') as file:
        sql_script_content = file.read()
    
    parsed = sqlparse.parse(sql_script_content)
    return sql_script_content, parsed
   

# Function to check if content of 'parsed' was successfully parsed
def check_syntax(parsed):
    return len(parsed) > 0

# Function to detect potential SQL injection risks - just a demo and is not an extensive detection method
def detect_potential_injection(parsed):
    potential_injection = False
    for statement in parsed:
        # Looks to see if 'CONCAT' or '?' is added to the parsed SQL
        if 'CONCAT' in str(statement) or '?' in str(statement):
            potential_injection = True
    return potential_injection

# Main script execution
def main():
    try:
        # Read and print the SQL script
        sql_script_content, parsed = read_and_parse_script(args.sql_script)
        print(f"Script Content:\n{sql_script_content}\n")
        
        # Preliminary syntax checks
        if not check_syntax(parsed):
            print("Error: SQL script parsing failed.")
            exit(1)

        # Check for DDL or DML statements
        if is_ddl_or_dml(parsed):
            print("The SQL script is a DDL or DML statement.")
        else:
            print("The SQL script is not a DDL or DML statement, failing pipeline.")
            exit(1)

        # Detect potential SQL injection risks
        injection_risk = detect_potential_injection(parsed)
        print(f"Potential SQL Injection Risk: {injection_risk}")
        if injection_risk:
            print("Potential injection risk found, failing pipeline.")
            exit(1)

# Catch other file not found or exception errors
    except FileNotFoundError as e:
        print(e)
        exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        exit(1)

if __name__ == "__main__":
    main()