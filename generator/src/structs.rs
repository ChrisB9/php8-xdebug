use std::collections::HashMap;

#[derive(PartialOrd, PartialEq, Debug, Serialize)]
pub enum ContainerType {
    ALPINE,
    DEBIAN,
    CLI,
}

#[derive(Debug, Serialize)]
pub struct Dockerfile {
    pub from: String,
    pub container_type: ContainerType,
    pub envs: HashMap<String, String>,
    pub use_apk: bool,
    pub is_web: bool,
}

#[derive(Debug, Serialize)]
pub struct ProdDockerfile {
    pub base: Dockerfile,
    pub is_dev: bool,
}

#[derive(Debug, Serialize)]
pub struct DevDockerfile {
    pub base: Dockerfile,
    pub is_dev: bool,
}