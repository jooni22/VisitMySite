#!/bin/bash

PROXYLIST_FILE_PATH="res/proxy_list.txt"
CONFIG_FILE_PATH="cfg.conf"
LAST_UPDATE_FILE_PATH="res/last_update.txt"
WORKING_PROXY_FILE_PATH="res/working_proxy.txt"
# Function to read configuration
read_config() {
    if [[ -f "$CONFIG_FILE_PATH" ]]; then
        PROXY_URL=$(grep "^PROXY_URL:" "$CONFIG_FILE_PATH" | cut -d' ' -f2-)
        NEW_PROXY_URL=$(grep "^NEW_PROXY_URL:" "$CONFIG_FILE_PATH" | cut -d' ' -f2-)
        NEW_PROXY_FILE=$(grep "^NEW_PROXY_FILE:" "$CONFIG_FILE_PATH" | cut -d' ' -f2-)
    else
        echo "Error: Configuration file not found."
        exit 1
    fi
}

# Function to download proxy list
download_proxy_list() {
    if [[ "$PROXY_URL" == *"TheSpeedX/PROXY-List"* ]]; then
        if ! curl -s https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks5.txt > $PROXYLIST_FILE_PATH; then
            echo "Error: Failed to download proxy list from TheSpeedX/PROXY-List."
            exit 1
        fi
    elif [[ "$PROXY_URL" == "NONE" ]]; then
        NEW_PROXY_URL=$(grep "^NEW_PROXY_URL:" "$CONFIG_FILE_PATH" | cut -d' ' -f2-)
        NEW_PROXY_FILE=$(grep "^NEW_PROXY_FILE:" "$CONFIG_FILE_PATH" | cut -d' ' -f2-)
        
        if [[ "$NEW_PROXY_URL" == "NONE" && "$NEW_PROXY_FILE" == "NONE" ]]; then
            echo "Error: No proxy list available. Both NEW_PROXY_URL and NEW_PROXY_FILE are set to NONE."
            exit 1
        elif [[ "$NEW_PROXY_URL" != "NONE" ]]; then
            if ! curl -s "$NEW_PROXY_URL" >> $PROXYLIST_FILE_PATH; then
                echo "Error: Failed to download proxy list from NEW_PROXY_URL."
                exit 1
            fi
        elif [[ "$NEW_PROXY_FILE" != "NONE" ]]; then
            if ! cat "$NEW_PROXY_FILE" >> $PROXYLIST_FILE_PATH; then
                echo "Error: Failed to read proxy list from NEW_PROXY_FILE."
                exit 1
            fi
        fi
    else
        echo "Error: Invalid PROXY_URL in configuration."
        exit 1
    fi
}

# Function to check for updates
check_for_updates() {
    local last_update=$(curl -s https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/README.md | grep "Last Updated:")
    if [[ -z "$last_update" ]]; then
        echo "Error: Failed to fetch last update information."
        return 1
    fi

    if [[ -f "$LAST_UPDATE_FILE_PATH" ]]; then
        local stored_update=$(cat "$LAST_UPDATE_FILE_PATH")
        if [[ "$last_update" == "$stored_update" ]]; then
            echo "No updates available."
            return 1
        fi
    fi

    echo "$last_update" > "$LAST_UPDATE_FILE_PATH"
    echo "Update available. Continuing with the script."
    return 0
}

# New function to get a random User-Agent
get_random_user_agent() {
    local IFS=$'\n'
    local user_agents=($(grep "^USER_AGENT:" "$CONFIG_FILE_PATH" | sed 's/^USER_AGENT: //'))
    local array_length=${#user_agents[@]}
    local random_index=$((RANDOM % array_length))
    echo "${user_agents[$random_index]}"
}

# New function to check proxies
check_proxies() {
    echo "Checking proxies..."
    echo "Getting proxies from $PROXYLIST_FILE_PATH"
    > $WORKING_PROXY_FILE_PATH;  # Clear the working proxy file
    cat $PROXYLIST_FILE_PATH | \
    xargs -P 50 -I {} bash -c '
      ip_port="{}";
      ip=$(echo $ip_port | cut -d: -f1);
      port=$(echo $ip_port | cut -d: -f2);
      if timeout 5 curl -s -k -x socks5h://$ip:$port https://www.google.com >/dev/null 2>&1; then
        echo "$ip:$port";
      fi
    ' | tee $WORKING_PROXY_FILE_PATH
   echo "Proxy check completed. Working proxies saved to $WORKING_PROXY_FILE_PATH"
}

# Function to execute curl requests
execute_curl_requests() {
    local view_urls=($(grep "^VIEW_URL:" "$CONFIG_FILE_PATH" | cut -d' ' -f2-))
    local proxies=($(cat "$WORKING_PROXY_FILE_PATH"))
    local total_success_count=0
    local total_error_count=0

    for view_url in "${view_urls[@]}"; do
        local success_count=0
        local error_count=0

        echo "Processing URL: $view_url"

        for proxy in "${proxies[@]}"; do
            local ip=$(echo $proxy | cut -d: -f1)
            local port=$(echo $proxy | cut -d: -f2)
            local user_agent=$(get_random_user_agent)
            
            local start_time=$(($(date +%s%N)/1000000))
            local response=$(curl -s -k -x socks5h://$ip:$port \
                -H "User-Agent: $user_agent" \
                -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
                -H "Accept-Language: en-US,en;q=0.5" \
                -H "Accept-Encoding: gzip, deflate, br" \
                -H "DNT: 1" \
                -H "Connection: keep-alive" \
                -H "Upgrade-Insecure-Requests: 1" \
                -o /dev/null -w "%{http_code}" \
                -m 5 \
                "$view_url" 2>/dev/null)
            local end_time=$(($(date +%s%N)/1000000))
            
            local execution_time=$((end_time - start_time))
            
            local status
            if [ "$response" = "200" ]; then
                status="SUCCESS"
                ((success_count++))
                ((total_success_count++))
            else
                status="ERROR"
                ((error_count++))
                ((total_error_count++))
            fi
            
            echo "$view_url $ip:$port $status ${execution_time}ms"
        done
        echo "########################" 
        echo "  Results for $view_url:"
        echo "  Successful requests: $success_count"
        echo "  Failed requests: $error_count"
        echo "  Total requests: $((success_count + error_count))"
        echo "########################" 
    done

    echo "Overall results:"
    echo "Total successful requests: $total_success_count"
    echo "Total failed requests: $total_error_count"
    echo "Total requests: $((total_success_count + total_error_count))"
}

# Main function
main() {
    read_config
    if check_for_updates; then
        download_proxy_list
        echo "Proxy list updated successfully."
        check_proxies
        execute_curl_requests
    else
        echo "No update needed. Executing curl requests with existing proxies."
        execute_curl_requests
    fi
}

# Run the main function
main