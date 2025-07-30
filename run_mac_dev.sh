#!/bin/bash

DEFAULT_CONTAINER_NAME="kong-dbless"
KONG_YAML_FILE="config/kong.yaml"
MY_KONG_YAML_FILE="config/my-kong.yaml"

destroy_container() {
  local container_name="$1" # Use local variable for the container name within the function

  if [ -z "$container_name" ]; then
    echo "Error: No container name provided to destroy_container function." >&2
    return 1 # Return error status
  fi

  echo "Attempting to destroy Docker container: $container_name"

  # Check if the container exists
  if [ -n "$(docker ps -a -f name=^/"$container_name"$ -q)" ]; then
    # echo "Container '$container_name' found."

    # Check if the container is running and stop it if it is
    if [ -n "$(docker ps -f name=^/"$container_name"$ -q)" ]; then
      # echo "Stopping container '$container_name'..."
      docker stop "$container_name"
      if [ $? -eq 0 ]; then
        echo "Container '$container_name' stopped successfully."
      else
        echo "Warning: Failed to stop container '$container_name'. It might have already stopped." >&2
        # Continue to removal attempt even if stop fails
      fi
    else
      echo "Container '$container_name' is not running."
    fi

    # Remove the container
    # echo "Removing container '$container_name'..."
    docker rm "$container_name"
    if [ $? -eq 0 ]; then
      echo "Container '$container_name' removed successfully."
      return 0 # Return success status
    else
      echo "Error: Failed to remove container '$container_name'." >&2
      return 1 # Return error status
    fi

  else
    echo "Container '$container_name' does not exist. No action needed."
    return 0 # Return success status (as the desired state is achieved)
  fi
}

destroy_container "$DEFAULT_CONTAINER_NAME"

# --- Kong Version Handling Script ---

# Default Kong version
DEFAULT_KONG_VERSION="2.8"
KONG_VERSION=$DEFAULT_KONG_VERSION

# Check if a command-line argument is provided
if [ -n "$1" ]; then
  # An argument is provided, validate it
  if [ "$1" == "2.8" ] || [ "$1" == "3.4" ] || [ "$1" == "3.10" ]; then
    # Valid version provided, use it
    KONG_VERSION="$1"
    echo "Using provided Kong version: $KONG_VERSION"
  else
    # Invalid version provided
    echo "Invalid kong_version specified: '$1'. Allowed values are '2.8', '3.4' or '3.10'." >&2 # Print error to stderr
    echo "Using default Kong version: $DEFAULT_KONG_VERSION"
    # Keep the default version
  fi
else
  # No argument provided, use the default
  echo "No kong_version specified. Using default: $KONG_VERSION"
fi

KONG_DOCKER_VERSION="2.8.4.14"
if [ $KONG_VERSION == "3.4" ]; then
  KONG_DOCKER_VERSION="3.4.3.16"
fi
if [ $KONG_VERSION == "3.10" ]; then
  KONG_DOCKER_VERSION="3.10.0.1"
fi

echo "-------------------------------------"
echo "Selected Kong Version: $KONG_VERSION"
echo "Selected Kong Docker Version: $KONG_DOCKER_VERSION"
echo "-------------------------------------"


# Get the IP address associated with the primary network interface (usually en0)
# en0 typically represents the built-in Ethernet or the first Wi-Fi interface.
# If you primarily use a different interface (like en1 for Wi-Fi on some models),
# you might need to change 'en0' below.
IP_ADDRESS=$(ipconfig getifaddr en0)

# Check if an IP address was found
if [ -z "$IP_ADDRESS" ]; then
  # If en0 didn't return an IP, try en1 as a fallback (common for Wi-Fi on some Macs)
  echo "No IP found for en0, trying en1..." >&2 # Print message to standard error
  IP_ADDRESS=$(ipconfig getifaddr en1)
fi

# Check again if an IP address was found
if [ -n "$IP_ADDRESS" ]; then
  # Print the found IP address
  echo "Your local IP address is: $IP_ADDRESS"

  echo "Checking $KONG_YAML_FILE..."
  if [ ! -f "$KONG_YAML_FILE" ]; then
    echo "Error: YAML file '$KONG_YAML_FILE' not found." >&2
    exit 1
  fi

  cp $KONG_YAML_FILE $MY_KONG_YAML_FILE
  chmod +x $MY_KONG_YAML_FILE

  echo "Updating $MY_KONG_YAML_FILE..."
  if [ ! -f "$MY_KONG_YAML_FILE" ]; then
    echo "Error: YAML file '$MY_KONG_YAML_FILE' not found." >&2
    exit 1
  fi

  PLACEHOLDER="MYIP"

  # Use sed for in-place replacement (macOS requires -i '')
  # Use '#' as delimiter to avoid issues with '/' in the URL
  sed -i '' "s#${PLACEHOLDER}#${IP_ADDRESS}#g" "$MY_KONG_YAML_FILE"

  if [ $? -eq 0 ]; then
    echo "Successfully updated '$MY_KONG_YAML_FILE'."
  else
    echo "Error: Failed to update '$MY_KONG_YAML_FILE'." >&2
    exit 1
  fi

else
  # Print an error message if no IP was found on common interfaces
  echo "Could not determine the local IP address for en0 or en1." >&2 # Print message to standard error
  exit 1 # Exit with a non-zero status to indicate failure
fi


if ! docker network ls | grep -q "kong-net"; then
  docker network create kong-net
fi

docker run -d --name kong-dbless \
--network=kong-net \
-v "$(pwd):/kong/declarative/" \
-e "KONG_DATABASE=off" \
-e "KONG_DECLARATIVE_CONFIG=/kong/declarative/$MY_KONG_YAML_FILE" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
-e "KONG_ADMIN_GUI_URL=http://localhost:8002" \
-p 8000:8000 \
-p 8443:8443 \
-p 8001:8001 \
-p 8444:8444 \
-p 8002:8002 \
-p 8445:8445 \
-p 8003:8003 \
-p 8004:8004 \
kong/kong-gateway:$KONG_DOCKER_VERSION

# wait for the container to be fully up and running
echo "Waiting for Kong to start..."
until $(curl --output /dev/null --silent --head --fail http://localhost:8002); do
  printf '.'
  sleep 1
done


# Specify the path to your Node.js server script
NODE_SERVER_SCRIPT="server/server.js" # <-- Make sure this path is correct

# Check if the Node server script exists
if [ ! -f "$NODE_SERVER_SCRIPT" ]; then
  echo "Error: Node server script not found at '$NODE_SERVER_SCRIPT'" >&2
  exit 1
fi

echo "Starting Node.js server ($NODE_SERVER_SCRIPT) in the background..."

# Check if a Node.js server is already running on the specified IP and port, and terminate it if found
if lsof -i :8088 | grep -q "node"; then
  echo "A Node.js server is already running on port 8088. Terminating it..."
  lsof -ti :8088 | xargs kill -9
fi

# Start the Node.js server in the background and capture its PID
node "$NODE_SERVER_SCRIPT" --ip $IP_ADDRESS &
NODE_PID=$!



echo "Node.js server started with PID: $NODE_PID"

# wait for the server to start
echo "Waiting for Node Server to start..."
until $(curl --output /dev/null --silent --head --fail http://localhost:8001); do
  printf '.'
  sleep 10
done

# Check if the server started successfully
if ! kill -0 $NODE_PID 2>/dev/null; then
  echo "Error: Node server failed to start." >&2
  exit 1
fi

echo "Node.js server is running."
echo "-------------------------------------"
echo "Running tests against the Node.js server..."
echo "-------------------------------------"

./test-script/script.sh


# # --- Cleanup function and trap ---
# # This function will be called when the script exits (normally or via interrupt)
# cleanup() {
#   echo "Cleaning up..."
#   # Check if the Node process is still running by checking if the PID exists
#   # kill -0 $NODE_PID checks if the process exists without sending a signal
#   if kill -0 $NODE_PID 2>/dev/null; then
#     echo "Stopping Node.js server (PID: $NODE_PID)..."
#     # Send SIGTERM first (graceful shutdown), then SIGKILL if it doesn't stop
#     kill $NODE_PID
#     # Optional: Wait a moment and check if it stopped, then force kill if needed
#     sleep 2
#     if kill -0 $NODE_PID 2>/dev/null; then
#         echo "Node server did not stop gracefully, sending SIGKILL..."
#         kill -9 $NODE_PID
#     fi
#     echo "Node.js server stopped."
#   else
#     echo "Node.js server (PID: $NODE_PID) already stopped."
#   fi
# }

# # Set up the trap: call the cleanup function on EXIT signal (normal exit, Ctrl+C, errors)
# trap cleanup EXIT

# # --- Run your other commands here ---

# # --- Script finishes ---
# # The 'trap cleanup EXIT' will automatically call the cleanup function now
# # No need to explicitly call kill here unless you remove the trap

# destroy_container "$DEFAULT_CONTAINER_NAME"

exit 0 # Exit successfully