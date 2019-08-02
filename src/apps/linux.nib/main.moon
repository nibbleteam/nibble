export init

shprint = (str, bg) ->
  send_message(env.tty, { print: str, background: bg})

init = () ->
  help = false
  full = false

  for key, value in pairs env.params
    if value == "h" or value == "help"
      help = true
    if value == "f" or value == "full"
      full = true

  if help
    shprint "usage: linux [-f/--full]
The GNU/Linux interjection speech is copypasta that was cut together based on Stallman's rant and other pieces of his writings over the years.

optional arguments:
  -h, --help            show this help message and exit
  -f, --full            show the entire interjection\n"
    return stop_app(0)

  shprint "I'd just like to interject for a moment. What you're refering to as Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, GNU plus Linux. Linux is not an operating system unto itself, but rather another free component of a fully functioning GNU system made useful by the GNU corelibs, shell utilities and vital system components comprising a full OS as defined by POSIX.\n"

  if full
    shprint "Many computer users run a modified version of the GNU system every day, without realizing it. Through a peculiar turn of events, the version of GNU which is widely used today is often called Linux, and many of its users are not aware that it is basically the GNU system, developed by the GNU Project.\n"

    shprint "There really is a Linux, and these people are using it, but it is just a part of the system they use. Linux is the kernel: the program in the system that allocates the machine's resources to the other programs that you run. The kernel is an essential part of an operating system, but useless by itself; it can only function in the context of a complete operating system. Linux is normally used in combination with the GNU operating system: the whole system is basically GNU with Linux added, or GNU/Linux. All the so-called Linux distributions are really distributions of GNU/Linux!\n"

  stop_app(0)
