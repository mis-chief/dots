if status is-interactive
    # Commands to run in interactive sessions can go here
    function fish_greeting
    	if test "$TERM" = xterm-kitty; and type -q fastfetch
        	fastfetch
    	end
    end
end
