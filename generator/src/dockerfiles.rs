use crate::generate::Generate;
use crate::structs::*;
use std::collections::HashMap;

fn get_from(container_type: &ContainerType) -> String {
    String::from(match container_type {
        ContainerType::ALPINE => "php:8.0.0-fpm-alpine",
        ContainerType::DEBIAN => "php:8.0.0-fpm",
        ContainerType::CLI => "php:8.0.0-cli",
    })
}

fn get_is_alpine(container_type: &ContainerType) -> bool {
    *container_type == ContainerType::ALPINE
}

fn get_is_web(container_type: &ContainerType) -> bool {
    *container_type != ContainerType::CLI
}

impl Generate for ProdDockerfile {
    fn new(container_type: Option<ContainerType>) -> ProdDockerfile {
        let container_type: ContainerType = container_type.unwrap_or(ContainerType::ALPINE);
        let from: String = get_from(&container_type);
        let use_apk: bool = get_is_alpine(&container_type);
        let is_web: bool = get_is_web(&container_type);
        ProdDockerfile {
            base: Dockerfile {
                from,
                container_type,
                envs: HashMap::new(),
                use_apk,
                is_web,
            },
            is_dev: false,
        }
    }
}

impl Generate for DevDockerfile {
    fn new(container_type: Option<ContainerType>) -> DevDockerfile {
        let container_type: ContainerType = container_type.unwrap_or(ContainerType::ALPINE);
        let mut envs: HashMap<String, String> = HashMap::new();
        envs.insert(String::from("XDEBUG_VERSION"), String::from("3.0.0"));
        let from: String = get_from(&container_type);
        let use_apk: bool = get_is_alpine(&container_type);
        let is_web: bool = get_is_web(&container_type);
        DevDockerfile {
            base: Dockerfile {
                from,
                container_type,
                envs,
                use_apk,
                is_web,
            },
            is_dev: true,
        }
    }
}
