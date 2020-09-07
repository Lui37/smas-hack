ss:
	cp sfc/smas_u.sfc target/smashack_ss.sfc && cd src && asar -Dsavestates=1 main.asm ../target/smashack_ss.sfc && cd -
	
nss:
	cp sfc/smas_u.sfc target/smashack_emu.sfc && cd src && asar -Dsavestates=0 main.asm ../target/smashack_emu.sfc && cd -

all: ss nss

clean:
	rm -f target/*.sfc
	