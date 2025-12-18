use wesl::Wesl;

fn main() {
    let wesl = Wesl::new("src/shaders");
    wesl.build_artifact(&"package::tube".parse().unwrap(), "tube");
    wesl.build_artifact(&"package::instances".parse().unwrap(), "instances");
}
