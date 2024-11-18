{ lib, stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation rec {
  pname = "uvgrtp";
  version = "fix/rtcp-fc";

  src = ./.;

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    "-DUVGRTP_DISABLE_TESTS=ON"
  ];

  doCheck = false;

  # Update the git ID to match your fork's commit
  NIX_CFLAGS_COMPILE = [
    "-DUVGRTP_GIT_ID=\"${version}\""
    "-DUVGRTP_BRANCH_NAME=\"fix/rtcp-fc\""
  ];

  meta = with lib; {
    description = "An open-source library for RTP/SRTP media delivery";
    longDescription = ''
      uvgRTP is an Real-Time Transport Protocol (RTP) library written in C++ with a focus on simple to use and high-efficiency media delivery over the Internet.
    '';
    homepage = "https://github.com/ultravideo/uvgRTP/blob/master/USAGE.md";
    license = licenses.bsd2;
    mainProgram = "uvgrtp";
    platforms = platforms.unix;
  };
}
