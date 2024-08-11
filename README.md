# Proxy Checker

## Overview

The Proxy Checker is a Bash script that allows users to check the functionality of proxy servers by sending requests to specified URLs. It supports loading proxy lists from a URL or a local file, and it can handle multiple user agents to simulate different browser requests.

## Features

- **Proxy List Management**: Automatically downloads a list of proxies or uses a user-provided list.
- **User Agent Rotation**: Randomly selects a user agent from a predefined list for each request.
- **Proxy Checking**: Validates proxies by attempting to connect to specified URLs.
- **Update Checking**: Checks for updates to the proxy list and downloads a new list if available.
- **Detailed Reporting**: Outputs the results of the proxy checks, including success and error counts.

## Configuration

The configuration is managed through a `cfg.conf` file. Below are the key parameters:

- **PROXY_URL**: URL to fetch the proxy list. If set to `NONE`, the script will look for a new proxy list in the `NEW_PROXY_URL` or `NEW_PROXY_FILE`.
- **NEW_PROXY_URL**: An alternative URL for a proxy list if the primary URL fails.
- **NEW_PROXY_FILE**: A local file containing a list of proxies in the format `IP:PORT`.
- **USER_AGENT**: A list of user agents to be used for requests. Multiple user agents can be specified.
- **VIEW_URL**: The URLs to which requests will be sent to test the proxies.

### Example Configuration

Add you URL in the VIEW_URL: section

```cfg.conf
VIEW_URL: https://www.example.com
VIEW_URL: https://www.google.com
```

## Usage

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Make the script executable**:
   ```bash
   chmod +x allinone.sh
   ```

3. **Run the script**:
   ```bash
   ./allinone.sh
   ```

## Output

The script will output the results of the proxy checks, including:

- The URL being processed
- The proxy used
- The status of the request (SUCCESS or ERROR)
- The execution time for each request

At the end of the execution, a summary of successful and failed requests will be displayed.

## Requirements

- Bash
- curl
- A Unix-like environment (Linux, macOS, etc.)

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.