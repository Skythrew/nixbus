use zbus::{conn::Builder, interface, message::Header, Connection, Result};
use zbus_polkit::policykit1::{AuthorityProxy, CheckAuthorizationFlags, Subject};
use std::process::Command;

struct ConfigurationManager;

#[interface(name = "io.github.skythrew.nixbus.ConfigurationManager")]
impl ConfigurationManager {
    async fn write(&self, #[zbus(header)] header: Header<'_>, from: &str, to: &str) -> bool {
        if !check_authorization(&header, "io.github.skythrew.nixbus.ConfigurationManager.write").await { return false }
        if !from.ends_with(".nix") || !to.ends_with(".nix") { return false }

        match std::fs::copy(from, to) {
            Ok(_) => return true,
            Err(_) => return false
        }
    }

    async fn rebuild(&self, #[zbus(header)] header: Header<'_>) -> i32 {
        if !check_authorization(&header, "io.github.skythrew.nixbus.ConfigurationManager.rebuild").await { return -1 }

        let output = Command::new("/run/current-system/sw/bin/nixos-rebuild switch")
            .output();

        match output {
            Ok(out) => out.status.code().unwrap(),
            Err(e) => e.raw_os_error().unwrap()
        }
    }
}

async fn check_authorization(header: &Header<'_>, action_id: &str) -> bool {
    let connection = Connection::system().await.expect("failed to connect to system bus");

    let proxy = AuthorityProxy::new(&connection).await.expect("failed to connect to proxy.");
    
    let subject = Subject::new_for_message_header(header).expect("failed to create polkit subject.");

    proxy.check_authorization(
        &subject,
        action_id,
        &std::collections::HashMap::new(),
        CheckAuthorizationFlags::AllowUserInteraction.into(),
        ""
    ).await.unwrap().is_authorized
}

#[tokio::main]
async fn main() -> Result<()> {
    
    let connection = Builder::system()?
        .name("io.github.skythrew.nixbus")?
        .serve_at("/io/github/skythrew/nixbus/ConfigurationManager", ConfigurationManager)?
        .build()
        .await?;

    connection
        .request_name("io.github.skythrew.nixbus")
        .await?;

    loop {}
}