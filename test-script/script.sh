#!/bin/bash

SERVER_URL="http://localhost:8000/test"

correct_dates_to_test=(
    "01-Jan-2001"
    "02-Feb-2002"
    "03-Mar-2003"
    "04-Apr-2004"
    "05-May-2005"
    "06-Jun-2006"
    "07-Jul-2007"
    "08-Aug-2008"
    "09-Sep-2009"
    "10-Oct-2010"
    "11-Nov-2011"
    "12-Dec-2012"
)

transformed_dates_to_test=(
    "01-Sept-1965"
    "02-Sept-1966"
    "03-Sept-1967"
    "04-Sept-1968"
    "05-Sept-1969"
    "06-Sept-1970"
    "07-Sept-1971"
    "08-Sept-1972"
    "09-Sept-1973"
    "10-Sept-1974"
    "11-Sept-1975"
    "12-Sept-1976"
    "13-Sept-1977"
    "14-Sept-1978"
    "15-Sept-1979"
    "16-Sept-1980"
    "17-Sept-1981"
    "18-Sept-1982"
    "19-Sept-1983"
    "20-Sept-1984"
    "21-Sept-1985"
    "22-Sept-1986"
    "23-Sept-1987"
    "24-Sept-1988"
    "25-Sept-1989"
    "26-Sept-1990"
    "27-Sept-1991"
    "28-Sept-1992"
    "29-Sept-1993"
    "30-Sept-1994"
)

incorrect_dates_to_test=(
  "01-September-2001"
  "01-09-2001"
  "01/09/2001"
  "01-09-01"
  "NULL"
)

correct_date_format='^[0-9]{2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-[0-9]{4}$'

all_tests_passed=true

# Function to test the server with a given date
test_date() {
    local date=$1
    local response=$(curl -s -X POST -d "dob=$date" "$SERVER_URL")

    echo " - - - - - - - - - - - - "
    echo "curl url:" + $SERVER_URL
    echo "Request: $date"
    echo "Response: $response"
    if [[ "$date" =~ $correct_date_format ]]; then
        if [[ "$response" =~ $correct_date_format ]]; then
            echo "Test PASSED: Correct date format detected."
        else
            echo "Test FAILED: Expected correct date format but got incorrect response."
            all_tests_passed=false
        fi
    elif [[ "${transformed_dates_to_test[*]}" =~ "$date" ]]; then
        if [[ "$response" == *"Sep"* && "$response" != *"Sept"* ]]; then
            echo "Test PASSED: Transformed date format detected correctly."
        else
            echo "Test FAILED: Expected transformed date format but got incorrect response."
            all_tests_passed=false
        fi
    elif [[ "${incorrect_dates_to_test[*]}" =~ "$date" ]]; then
        if [[ "$response" =~ $correct_date_format ]]; then
            echo "Test FAILED: Incorrect date format unexpectedly passed."
            all_tests_passed=false
        else
            echo "Test PASSED: Incorrect date format correctly failed."
        fi
    else
        echo "Test FAILED: Unexpected case encountered."
        all_tests_passed=false
    fi
}

# Loop through the dates and test each one
for date in "${correct_dates_to_test[@]}"; do
    test_date "$date"
done

for date in "${transformed_dates_to_test[@]}"; do
    test_date "$date"
done

for date in "${incorrect_dates_to_test[@]}"; do
    test_date "$date"
done

# Final output
echo "========================================"
if $all_tests_passed; then
    echo -e "\033[1;32mALL TESTS PASSED SUCCESSFULLY!\033[0m"
else
    echo -e "\033[1;31mSOME TESTS FAILED. PLEASE CHECK THE OUTPUT ABOVE.\033[0m"
fi
echo "========================================"