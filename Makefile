



all: compile

compile:
	 #mpasmx -p12F629  main.asm -d__DEBUG=1
	 gpasm --mpasm-compatible -p12F629  main.asm 

link:
	mplink -p12F629 main.O -o main.cof -W -x

flash:
	pk2cmd -PPIC12F629 -M -F main.HEX
	pk2cmd -PPIC12F629 -Y -F main.HEX	

