use godot::prelude::*;

#[derive(GodotClass)]
#[class(base=Node)]
pub struct HelloNode {
    #[export]
    greeting: GString,
    #[base]
    base: Base<Node>,
}

#[godot_api]
impl HelloNode {
    #[func]
    fn say_hello(&self, name: GString) -> GString {
        let msg = format!("{} {}!", self.greeting.to_string(), name);
        godot_print!("{msg}");
        msg.into()
    }
}

#[godot_api]
impl INode for HelloNode {
    fn init(base: Base<Node>) -> Self {
        Self { greeting: "Hello".into(), base }
    }
}
