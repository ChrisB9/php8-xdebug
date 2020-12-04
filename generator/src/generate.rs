use std::path::Path;
use std::fs;
use crate::template_parser::Parsing;
use serde::Serialize;
use std::fs::File;
use std::io::prelude::*;
use crate::structs::ContainerType;
use config::Config;
use std::collections::HashMap;

pub trait Generate: Serialize {
    fn new(container_type: Option<ContainerType>) -> Self;

    fn load_config(&self) -> HashMap<String, String> {
        let mut settings: Config = Config::default();
        settings.merge(config::File::with_name("settings")).unwrap();
        settings.try_into::<HashMap<String, String>>().unwrap()
    }

    fn generate(&self) -> Result<String, Box<dyn failure::Fail>> {
        let config = self.load_config();
        let parser = Parsing::new(config);
        match parser.render(&self) {
            Err(e) => Err(e),
            Ok(r) => Ok(r),
        }
    }

    fn to_file(&self) -> Result<(), failure::Error> {
        let filename: &str = "Dockerfile";
        if Path::new(filename).exists() {
            fs::remove_file(filename)?;
        }
        let mut file = File::create(filename)?;
        let result = self.generate()?;
        file.write_all(result.as_bytes())?;
        Ok(())
    }
}