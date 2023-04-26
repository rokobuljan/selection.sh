# selection.sh
Create a terminal navigable checkbox list

```txt
Select your desired actions:
(Use [Arrows] to navigate, [Space] to toggle, [Enter] to proceed)

   [ ] say_hi
   [■] say_hello
➜ [■] sing
   [ ] reboot
```

or by using the `-r` (radio) flag:

```txt
Pick your choice:
(Use [Arrows] to navigate, [Enter] to proceed)

    yes
➜  no
    maybe
```

A common use case are:

- installer scripts, where you have a procedure of executing functions and you want to allow the user to pick a subset
- allow the user to pick an option from the list of options (`-r` *radio* option flag)

### Return

Returns a public `selection` **array** with a filtered set of names in their original order.
Returns a public `selection` **string** with the selected item name (when using the `-r` option flag)


### Usage

For usage help see: `./selection.sh -h`

<sub>index.sh</sub>
```sh
#!/bin/bash

say_hi() {
    echo "Hi!!!!"
}

say_hello() {
    echo "Hello, world!"
}

sing() {
    echo "La, la-la la!"
}

reboot() {
    echo "Rebooting..."
}

# Prompt selections:
source ./selection.sh -t "Select your desired actions:" say_hi:1 say_hello:1 sing:0 reboot

for arg in "${selection[@]}"; do
    # Trigger function:
    "$arg"
done
```

as you can see, both using `someName:0` or `sameName` will make the ckeckbox unchecked by default.  
To make a checkbox default checked use always the `:1` suffix.

### Licence

MIT
