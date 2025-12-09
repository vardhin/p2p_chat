use local_ip_address::{local_ip, local_ipv6};
use network_interface::{NetworkInterface, NetworkInterfaceConfig, Addr};

#[derive(Debug, Clone)]
pub struct NetworkInfo {
    pub local_ipv4: Option<String>,
    pub local_ipv6: Option<String>,
    pub public_ipv4: Option<String>,
    pub public_ipv6: Option<String>,
    pub subnet_mask: Option<String>,
    pub gateway: Option<String>,
    pub network_prefix: Option<String>,
    pub interface_name: Option<String>,
    pub mac_address: Option<String>,
    pub broadcast_address: Option<String>,
}

/// Gets the local IPv4 address of the device
#[flutter_rust_bridge::frb(sync)]
pub fn get_local_ipv4_address() -> Option<String> {
    match local_ip() {
        Ok(ip) => Some(ip.to_string()),
        Err(_) => None,
    }
}

/// Gets the local IPv6 address of the device
#[flutter_rust_bridge::frb(sync)]
pub fn get_local_ipv6_address() -> Option<String> {
    match local_ipv6() {
        Ok(ip) => Some(ip.to_string()),
        Err(_) => None,
    }
}

/// Gets the public IPv4 address by querying external services
#[flutter_rust_bridge::frb(sync)]
pub fn get_public_ipv4_address() -> Option<String> {
    let services = [
        "https://api.ipify.org",
        "https://icanhazip.com",
        "https://ipinfo.io/ip",
    ];

    for service in services.iter() {
        if let Ok(response) = ureq::get(service).call() {
            if let Ok(ip) = response.into_string() {
                let ip = ip.trim().to_string();
                if !ip.is_empty() {
                    return Some(ip);
                }
            }
        }
    }
    None
}

/// Gets the public IPv6 address by querying external services
#[flutter_rust_bridge::frb(sync)]
pub fn get_public_ipv6_address() -> Option<String> {
    let services = [
        "https://api6.ipify.org",
        "https://ipv6.icanhazip.com",
    ];

    for service in services.iter() {
        if let Ok(response) = ureq::get(service).call() {
            if let Ok(ip) = response.into_string() {
                let ip = ip.trim().to_string();
                if !ip.is_empty() && ip.contains(':') {
                    return Some(ip);
                }
            }
        }
    }
    None
}

/// Calculate network prefix from IP and netmask
fn calculate_network_prefix(ip: &str, netmask: &str) -> Option<String> {
    let ip_parts: Vec<u8> = ip.split('.').filter_map(|s| s.parse().ok()).collect();
    let mask_parts: Vec<u8> = netmask.split('.').filter_map(|s| s.parse().ok()).collect();
    
    if ip_parts.len() == 4 && mask_parts.len() == 4 {
        let network: Vec<String> = ip_parts
            .iter()
            .zip(mask_parts.iter())
            .map(|(i, m)| (i & m).to_string())
            .collect();
        Some(network.join("."))
    } else {
        None
    }
}

/// Calculate broadcast address from IP and netmask
fn calculate_broadcast_address(ip: &str, netmask: &str) -> Option<String> {
    let ip_parts: Vec<u8> = ip.split('.').filter_map(|s| s.parse().ok()).collect();
    let mask_parts: Vec<u8> = netmask.split('.').filter_map(|s| s.parse().ok()).collect();
    
    if ip_parts.len() == 4 && mask_parts.len() == 4 {
        let broadcast: Vec<String> = ip_parts
            .iter()
            .zip(mask_parts.iter())
            .map(|(i, m)| (i | !m).to_string())
            .collect();
        Some(broadcast.join("."))
    } else {
        None
    }
}

/// Gets all network information (local and public IPs with LAN details)
#[flutter_rust_bridge::frb(sync)]
pub fn get_network_info() -> NetworkInfo {
    let mut info = NetworkInfo {
        local_ipv4: get_local_ipv4_address(),
        local_ipv6: get_local_ipv6_address(),
        public_ipv4: get_public_ipv4_address(),
        public_ipv6: get_public_ipv6_address(),
        subnet_mask: None,
        gateway: None,
        network_prefix: None,
        interface_name: None,
        mac_address: None,
        broadcast_address: None,
    };

    // Get detailed interface information
    if let Ok(interfaces) = NetworkInterface::show() {
        for iface in interfaces {
            // Skip loopback and inactive interfaces
            if iface.name.starts_with("lo") || iface.addr.is_empty() {
                continue;
            }

            for addr in &iface.addr {
                match addr {
                    Addr::V4(v4) => {
                        let ip_str = v4.ip.to_string();
                        if Some(ip_str.clone()) == info.local_ipv4 {
                            info.interface_name = Some(iface.name.clone());
                            
                            if let Some(netmask) = v4.netmask {
                                let netmask_str = netmask.to_string();
                                info.subnet_mask = Some(netmask_str.clone());
                                info.network_prefix = calculate_network_prefix(&ip_str, &netmask_str);
                                info.broadcast_address = calculate_broadcast_address(&ip_str, &netmask_str);
                            }
                            
                            if let Some(mac) = &iface.mac_addr {
                                info.mac_address = Some(mac.clone());
                            }
                        }
                    }
                    Addr::V6(_) => {}
                }
            }
        }
    }

    // Try to get default gateway (platform-specific, best effort)
    #[cfg(target_os = "android")]
    {
        // On Android, we can try to read from system properties or use commands
        // This is a simplified approach - might need refinement
        if let Ok(output) = std::process::Command::new("ip")
            .args(&["route", "show", "default"])
            .output()
        {
            if let Ok(route) = String::from_utf8(output.stdout) {
                if let Some(gateway) = route
                    .split_whitespace()
                    .skip_while(|&s| s != "via")
                    .nth(1)
                {
                    info.gateway = Some(gateway.to_string());
                }
            }
        }
    }

    info
}

/// Check if two IP addresses are on the same subnet
#[flutter_rust_bridge::frb(sync)]
pub fn are_on_same_subnet(ip1: String, ip2: String, subnet_mask: String) -> bool {
    let ip1_parts: Vec<u8> = ip1.split('.').filter_map(|s| s.parse().ok()).collect();
    let ip2_parts: Vec<u8> = ip2.split('.').filter_map(|s| s.parse().ok()).collect();
    let mask_parts: Vec<u8> = subnet_mask.split('.').filter_map(|s| s.parse().ok()).collect();
    
    if ip1_parts.len() == 4 && ip2_parts.len() == 4 && mask_parts.len() == 4 {
        for i in 0..4 {
            if (ip1_parts[i] & mask_parts[i]) != (ip2_parts[i] & mask_parts[i]) {
                return false;
            }
        }
        true
    } else {
        false
    }
}