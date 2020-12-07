use tinytemplate::TinyTemplate;
use std::{fs::{File, read_dir}, io::prelude::*, collections::HashMap, path::Path, io};
use failure::Fail;
use serde::Serialize;
use serde::export::fmt::Debug;

#[derive(Fail, Debug)]
#[fail(display = "An error occurred while parsing the template: {}.", _0)]
pub struct TemplatingError(String);

pub struct Parsing {
    config: HashMap<String, String>
}

struct TemplateFileCollection {
    template_content: HashMap<String, String>
}

impl TemplateFileCollection {
    pub fn new() -> TemplateFileCollection {
        TemplateFileCollection {
            template_content: HashMap::new(),
        }
    }

    fn read_dirs(dir: &str) -> io::Result<Vec<String>> {
        let path = Path::new(dir);
        let mut collection: Vec<String> = vec![];
        if path.is_dir() {
            for file in read_dir(path)? {
                let file = file?;
                if !file.path().is_dir() {
                    collection.push(file.path().as_os_str().to_str().unwrap().to_string());
                }
            }
        }
        Ok(collection)
    }

    pub fn read_for_dir(&mut self, dir: &str) -> io::Result<()> {
        let collection = TemplateFileCollection::read_dirs(dir)?;
        for file in &collection {
            self.add_file_content(file)?;
        }
        Ok(())
    }

    pub fn read_file(file: &str) -> io::Result<String> {
        let mut handle = File::open(file)?;
        let mut contents = String::new();
        handle.read_to_string(&mut contents)?;
        Ok(contents)
    }

    pub fn add_file_content(&mut self, file: &str) -> io::Result<()> {
        let contents = TemplateFileCollection::read_file(file).unwrap();
        let filename = Path::new(&file).file_name().unwrap();
        let mut filename = String::from(filename.to_str().unwrap());
        filename = filename.replace(".", "_");
        self.template_content.insert(filename, contents);
        Ok(())
    }
}

impl Parsing {
    pub fn new(config: HashMap<String, String>) -> Parsing {
        Parsing {
            config,
        }
    }

    fn get_error(&self, message: &str) -> Box<TemplatingError> {
        Box::new(TemplatingError(String::from(message)))
    }

    pub fn render<S>(&self, context: &S) -> Result<String, Box<TemplatingError>> where S: Serialize + Debug {
        let mut template = TinyTemplate::new();
        let mut collection = TemplateFileCollection::new();
        match collection.read_for_dir(&self.config["template_path"]) {
            Ok(_r) => (),
            Err(_e) => return Err(self.get_error("Failed parsing template directory")),
        };
        for file in &collection.template_content {
            match template.add_template(file.0, file.1) {
                Ok(_r) => (),
                Err(_e) => return Err(self.get_error(&format!("Failed parsing template directory for dockerfile {:?} {:?}", _e, context))),
            };
        }

        return match template.render(&self.config["base_template"], &context) {
            Err(e) => {
                println!("{}", e);
                Err(self.get_error("Rendering Template failed"))
            },
            Ok(r) => Ok(r),
        };
    }
}