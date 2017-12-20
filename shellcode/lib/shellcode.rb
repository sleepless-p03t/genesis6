#!/usr/bin/ruby

def mname
	"shellcode"
end

def cmds
	[ "generate" ]
end

def vars
	[ "fname", "olang" ]
end

def use
	[]
end

def generate(vhash)
	
	file = vhash["fname"]
	lang = vhash["olang"]
	
	system("bash", "-c", <<~EOS
		
		if [ ! -d ~/.genesis/lang/nasm ]; then
			mkdir -p ~/.genesis/lang/nasm/raw/
			mkdir -p ~/.genesis/lang/nasm/obj/
			mkdir -p ~/.genesis/lang/nasm/bin/
		fi
		
		if [ ! -f ~/.genesis/lang/nasm/raw/#{file}.asm ]; then
			echo "File not found: #{file}.asm"
		else
			cd ~/.genesis/lang/nasm/raw/
			nasm -fwin32 -o #{file}.o #{file}.asm
			mv #{file}.o ~/.genesis/lang/nasm/obj/
			cd ~/.genesis/lang/nasm/obj/

			for i in `objdump -d #{file}.o | tr '\t' ' ' | tr ' ' '\n' | egrep '^[0-9a-f]{2}$'`; do
				echo -n "\\x$i"
			done
			echo
		fi
	EOS
	)
end
