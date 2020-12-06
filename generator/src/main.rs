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
use seahorse::{App, Context, Command, Flag, FlagType};
use std::env;
use std::fmt::Display;
use terminal_color_builder::OutputFormatter as tcb;
use seahorse::error::FlagError;

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

fn error<T: Display>(t: T) -> String {
    format!("{}", tcb::new().fg().hex("#fff").bg().red().text(t.to_string()).print())
}

fn cmd(str: &str) -> String {
    tcb::new().fg().hex("#6f0").text_str(str).print()
}

fn parse_container_type(c: &Context) -> ContainerType {
    match c.string_flag("type") {
        Ok(t) => match &*t {
            "alpine" => ContainerType::ALPINE,
            "debian" => ContainerType::DEBIAN,
            "cli" => ContainerType::CLI,
            _ => panic!("{} {} {}", error("undefined container-type"), t, ": available types are debian, alpine, cli")
        }
        Err(e) => match e {
            FlagError::NotFound => ContainerType::ALPINE,
            _ => panic!("{} {:?}", error("Flag-Error"), e),
        }
    }
}

fn generate_prod_action(c: &Context) {
    let container_type = parse_container_type(c);
    let dockerfile: ProdDockerfile = Generate::new(Option::from(container_type));
    match dockerfile.to_file() {
        Err(e) => panic!(format!("{:?}", e)),
        _ => success("Successfully generated file"),
    }
}

fn generate_test_action(c: &Context) {
    let container_type = parse_container_type(c);
    let dockerfile: DevDockerfile = Generate::new(Option::from(container_type));
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
        .flag(
            Flag::new("type", FlagType::String)
                .description(cmd("Build either a debian-based or a alpine-based image (--type=debian or --type=alpine)"))
                .alias("t")
        )
}

fn generate_test() -> Command {
    Command::new("dev")
        .description(cmd("generate dev-php dockerfile"))
        .alias(cmd("d"))
        .usage(cmd("cli dev"))
        .action(generate_test_action)
        .flag(
            Flag::new("type", FlagType::String)
                .description(cmd("Build either a debian-based or a alpine-based image (--type=debian or --type=alpine)"))
                .alias("t")
        )
}
