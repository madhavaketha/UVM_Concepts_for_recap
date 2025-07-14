//Factory over riding 
//🔸 1. When we define a custom (derived) class:
class my_custom_seq extends my_base_seq;
  `uvm_object_utils(my_custom_seq)
endclass
//✅ We register it using uvm_object_utils, which:
//1.Makes it visible to the factory
//2.Enables it to be created via type_id::create()
//3.Enables it to be used in overrides

//🔸 2. At the time of override:
factory.set_type_override_by_type(
  my_base_seq::get_type(),
  my_custom_seq::get_type()
);
//✅ You're telling the factory:
//“Whenever someone tries to create my_base_seq, give them my_custom_seq instead.”

//🔸 3. Later in the code:
my_base_seq seq = my_base_seq::type_id::create("seq");
//✅ This asks the factory to create a my_base_seq, and the factory intercepts and checks:
//     ❓ Is there an override for this type?
//     ✅ Yes → Replace it with my_custom_seq
//📌 So even though the handle is my_base_seq, the actual object is my_custom_seq.

//🔸 4. When the sequence runs:
seq.start(sequencer);
//✅ The body() method of my_custom_seq executes, because that's the actual object created.

//⚠️ Just Remember:
//❌ If you use new instead of type_id::create(), factory cannot intercept — no override will happen.
//✅ Always use type_id::create() for objects and sequences to take full advantage of the factory.
