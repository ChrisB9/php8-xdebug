#[macro_use]
pub extern crate serde_derive;
pub extern crate tinytemplate;
pub extern crate failure_derive;

mod dockerfiles;
mod structs;
mod template_parser;
mod generate;

use structs::*;
use generate::Generate;
use seahorse::{App, Context, Command};
use std::env;
use std::fmt::Display;
use terminal_color_builder::OutputFormatter as tcb;

pub fn main() {
    let args: Vec<String> = env::args().collect();
    let app = App::new(cmd(env!("CARGO_PKG_NAME")))
        .description(cmd("generate php 8.0 dockerfile by template"))
        .command(generate_prod())
        .command(generate_test());

    app.run(args);
}

fn success<T: Display>(t: T) -> () {
    println!("{}", tcb::new().fg().hex("#fff").bg().green().text(t.to_string()).print());
}

fn cmd(str: &str) -> String {
    tcb::new().fg().hex("#6f0").text_str(str).print()
}

fn generate_prod_action(_c: &Context) {
    let dockerfile: ProdDockerfile = Generate::new(Option::from(ContainerType::ALPINE));
    match dockerfile.to_file() {
        Err(e) => panic!(format!("{:?}", e)),
        _ => success("Successfully generated file"),
    }
}

fn generate_test_action(_c: &Context) {
    let dockerfile: DevDockerfile = Generate::new(Option::from(ContainerType::ALPINE));
    match dockerfile.to_file() {
        Err(e) => panic!(format!("{:?}", e)),
        _ => success("Successfully generated file"),
    }
}

fn generate_prod() -> Command {
    Command::new("prod")
        .description(cmd("generate prod-php dockerfile"))
        .alias(cmd("p"))
        .usage(cmd("cli prod"))
        .action(generate_prod_action)
}

fn generate_test() -> Command {
    Command::new("dev")
        .description(cmd("generate dev-php dockerfile"))
        .alias(cmd("d"))
        .usage(cmd("cli dev"))
        .action(generate_test_action)
}
