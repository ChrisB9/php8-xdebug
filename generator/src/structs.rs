#[derive(Serialize)]
pub enum ContainerType {
    ALPINE,
    UBUNTU,
}

#[derive(Serialize)]
pub struct Dockerfile {
    pub from: String,
    pub container_type: ContainerType,
    pub envs: String,
}

#[derive(Serialize)]
pub struct ProdDockerfile {
    pub base: Dockerfile,
    pub is_dev: bool,
}

#[derive(Serialize)]
pub struct DevDockerfile {
    pub base: Dockerfile,
    pub is_dev: bool,
}