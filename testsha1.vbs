Option Explicit
Dim sha1
set sha1 =  GetObject("script:C:\sources\sha1.wsc")
    ' set a property
    sha1.hexcase = 1
Dim result
    ' call a function
    result = sha1.hex_hmac_sha1("0x0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b", "Hi There")
Set sha1 = Nothing