#!/usr/bin/ruby

#i686-w64-mingw32-gcc -fno-asynchronous-unwind-tables -s -c -o mba2.o mba.
#while read -r line; do rep=`echo $line | awk -F':' '{ $NF=""; print }'`; sed -i "s/$line/$rep/" test.txt; done< <(cat test.txt | grep global); cat test.txt

#cat _mba.asm | sed '/^.text/d' | sed 's/align.*$//g'

def mname
	"casm"
end

def cmds
	[ "generate" ]
end

def vars
	[ "fname", "nocomm" ]
end

def use
	[]
end

def generate(vhash)

	file = vhash["fname"]
	comm = vhash["nocomm"]
	
	rd = "#{Dir.pwd}/.runtime"

	system("bash", "-c", <<~EOS
		cd #{rd}/

		if [ ! -d ~/.genesis/lang/c ]; then
			mkdir -p ~/.genesis/lang/c/raw/
			mkdir -p ~/.genesis/lang/c/obj/
			mkdir -p ~/.genesis/lang/c/bin/
		fi

		if [ ! -d ~/.genesis/lang/nasm ]; then
			mkdir -p ~/.genesis/lang/nasm/raw/
			mkdir -p ~/.genesis/lang/nasm/obj/
			mkdir -p ~/.genesis/lang/nasm/bin/
		fi

		if [ ! -f ~/.genesis/lang/c/raw/#{file}.c ]; then
			echo "File not found: #{file}.c"
		else
			i686-w64-mingw32-gcc -m32 -fno-asynchronous-unwind-tables -s -c -o ~/.genesis/lang/c/obj/#{file}.o ~/.genesis/lang/c/raw/#{file}.c
			cd ~/.genesis/lang/c/obj/

			wine #{rd}/objconv.exe -fnasm32 #{file}.o
			mv *.asm ~/.genesis/lang/nasm/raw/#{file}.asm
			
			sed -i '/^.text/d' ~/.genesis/lang/nasm/raw/#{file}.asm
			sed -i 's/align.*$//g' ~/.genesis/lang/nasm/raw/#{file}.asm
			
			while read -r line; do
				rep=`echo $line | awk -F':' '{ $NF=""; print }'`
				sed -i "s/$line/$rep/" ~/.genesis/lang/nasm/raw/#{file}.asm
			done< <(cat ~/.genesis/lang/nasm/raw/#{file}.asm | grep global)
			
			if [[ "#{comm}" == "1" ]] || [[ "#{comm}" == "true" ]]; then
				sed -i 's/;.*$//g' ~/.genesis/lang/nasm/raw/#{file}.asm
				sed -i '/./,$!d' ~/.genesis/lang/nasm/raw/#{file}.asm
			fi

			cat ~/.genesis/lang/nasm/raw/#{file}.asm
			echo
		fi
	EOS
	)
end	
