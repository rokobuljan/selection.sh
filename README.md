# selection.sh

Create a CLI selection menu or checkbox list



## Single selection

To create a menu with options:

```sh
source ./selection.sh Yes No "Remind me later"
echo "$selection"
```

outputs:

> ```txt
> Select an option:
> (Use [Arrows] to navigate, [Enter] to proceed)
> 
> > Yes
>   No
>   Remind me later
> ```

`$selection` returns the name string i.e: `Remind me later`.  
To return the index instead, use the `-i` flag. Such will give you i.e: `2` instead of `Remind me later`

## Multiple selection (checkboxes)

Create a menu with a list of checkboxes.  

The checkboxes are all unchecked by default.  
Use the `:1` **suffix** to make the option checked. Use (optionally) `:0` to make an option unchecked.  

To invert the above logic pass the `-c` (*default checked*) flag.  
Use the `:0` **suffix** to make an option unchecked. Use (optionally) `:1` to make it checked.  

```sh
source ./selection.sh -m "Install packages:1" "Subscribe:1" "Reboot"
for arg in "${selection[@]}"; do
    echo "$arg"
done
```

outputs:

> ```txt
> Select the desired options:
> (Use [Arrows] to navigate, [Space] to toggle, [Enter] to proceed)
> 
> > [■] Install packages
>   [■] Subscribe
>   [ ] Reboot
> ```

`$selection` returns the names Array of the checked options (i.e: *("Install packages" "Subscribe")*).  
To return the indexes instead, use the `-i` flag.

### Custom title

To customise the title use the `-t` option like i.e:

```sh
source ./selection.sh -i -t "Welcome.\nSelect an action:" "Reboot server" "Cleanup" "Review logs"
echo "$selection"  # The selected index
```

___

Tip:  
Run functions depending on a selection:  

```sh
#!/bin/bash

fn_0() {
    echo "Rebooting server..."
}

fn_1() {
    echo "Cleanup in process..."
}

fn_2() {
    echo "Log files sent to your inbox."
}

# Prompt selections:
source ./selection.sh -i -m -t "Welcome $USER.\nSelect some actions:" "Reboot server" Cleanup "Review logs"
for i in "${selection[@]}"; do
    "fn_$i" # Trigger function/s:
done
```

### Licence

MIT
