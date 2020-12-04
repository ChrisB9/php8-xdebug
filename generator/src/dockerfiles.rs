use crate::generate::Generate;
use crate::structs::*;

impl Generate for ProdDockerfile {
    fn new(container_type: Option<ContainerType>) -> ProdDockerfile {
        ProdDockerfile {
            base: Dockerfile {
                from: "php:8.0.0RC2-fpm-alpine".to_string(),
                container_type: container_type.unwrap_or(ContainerType::ALPINE),
                envs: "".to_string(),
            },
            is_dev: false,
        }
    }
}

impl Generate for DevDockerfile {
    fn new(container_type: Option<ContainerType>) -> DevDockerfile {
        DevDockerfile {
            base: Dockerfile {
                from: "php:8.0.0RC2-fpm-alpine".to_string(),
                container_type: container_type.unwrap_or(ContainerType::ALPINE),
                envs: "".to_string(),
            },
            is_dev: true,
        }
    }
}
