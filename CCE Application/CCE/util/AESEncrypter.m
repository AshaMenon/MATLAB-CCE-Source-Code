classdef AESEncrypter < handle
    %AESEncrypter Wraps the .NET SimpleAES Encryption class
    %   Use this class to encrypt and decrypt strings for protected storage
    %
    %   Typically, this class must be p-coded 
    
    properties
        TextEncryptor (1,1) % .NET TextEncryptor class. generated in constructor
    end
    
    methods
        function obj = AESEncrypter
            %AESEncrypter  Construct an AESEncrypter object
            %   No arguments because we set the key internally
            NET.addAssembly(fullfile(fileparts(mfilename("fullpath")),"private","SimpleAES.dll"));
            obj.TextEncryptor = SimpleAES.TextEncrypter(";%*nb>z$JDhk2OJ]cg:`^0,O{@X6g8Pb");
        end
        
        function encrypted = encrypt(obj, plainText)
            %encrypt  Encrypt plain text
            %   encryptedText = encrypt(aesObj, plainText) encrypts the string in plainText.
            arguments
                obj (1,1) AESEncrypter
                plainText(1,1) string;
            end
            encrypted = obj.TextEncryptor.Encrypt(plainText);
        end
        
        function decrypted = decrypt(obj, encText)
            %decrypt  Decrypt encrypted text
            %   decryptedText = decrypt(aesObj, encryptedText) decrypts the string in encryptedText.
            arguments
                obj (1,1) AESEncrypter
                encText(1,1) string;
            end
            decrypted = obj.TextEncryptor.Decrypt(encText);
        end
    end
end

