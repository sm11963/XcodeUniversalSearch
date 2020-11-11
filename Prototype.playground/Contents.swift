import Cocoa
import XcodeUniversalSearchFoundation

var urlStrings = [
    "string",
    "www.example.com/host",
    "www.example.com/pathwith?[];/test?query=s"
]

var urls = urlStrings
    .map {
        URL(string: $0)
    }

print(urls)

let cs = URLComponents(string: urlStrings[2])

print(String(describing: cs))

extension CharacterSet {
    var characters: Set<String> {
        (self as NSCharacterSet).characters
    }
}

let encodedUrlTemplate = "https://sourcegraph.com/search?q=repo:%5Egithub%5C.com/ReactiveX/RxSwift%24+/%28typealias%7Cstruct%7Cclass%7Cprotocol%7Cenum%29+%s/&patternType=regexp"

print("Removing percent encoding:")
print(URLUtil.removePercentEncoding(from: encodedUrlTemplate) ?? "<removing percent encoding failed>")


extension NSCharacterSet {

    var characters: Set<String> {
        /// An array to hold all the found characters
        var characters: Set<String> = []

        /// Iterate over the 17 Unicode planes (0..16)
        for plane:UInt8 in 0..<17 {
            /// Iterating over all potential code points of each plane could be expensive as
            /// there can be as many as 2^16 code points per plane. Therefore, only search
            /// through a plane that has a character within the set.
            if self.hasMemberInPlane(plane) {

                /// Define the lower end of the plane (i.e. U+FFFF for beginning of Plane 0)
                let planeStart = UInt32(plane) << 16
                /// Define the lower end of the next plane (i.e. U+1FFFF for beginning of
                /// Plane 1)
                let nextPlaneStart = (UInt32(plane) + 1) << 16

                /// Iterate over all possible UTF32 characters from the beginning of the
                /// current plane until the next plane.
                for char: UTF32Char in planeStart..<nextPlaneStart {

                    /// Test if the character being iterated over is part of this
                    /// `NSCharacterSet`
                    if self.longCharacterIsMember(char) {

                        /// Convert `UTF32Char` (a typealiased `UInt32`) into a
                        /// `UnicodeScalar`. Otherwise, converting `UTF32Char` directly
                        /// to `String` would turn it into a decimal representation of
                        /// the code point, not the character.
                        if let unicodeCharacter = UnicodeScalar(char) {
                            characters.insert(String(unicodeCharacter))
                        }
                    }
                }
            }
        }
        
        return characters
    }
}

let urlHostAllowed = CharacterSet.urlHostAllowed.characters
let urlPathAllowed = CharacterSet.urlPathAllowed.characters
let urlQueryAllowed = CharacterSet.urlQueryAllowed.characters
let urlFragmentAllowed = CharacterSet.urlFragmentAllowed.characters

let allowedInAll = [urlPathAllowed, urlQueryAllowed, urlFragmentAllowed].reduce(urlHostAllowed) { $0.intersection($1) }
let allowedInOne = [urlPathAllowed, urlQueryAllowed, urlFragmentAllowed].reduce(urlHostAllowed) { $0.union($1) }

print("Allowed in all")
print(allowedInAll.sorted().joined(separator: ", "))

print("Allowed in host")
print(urlHostAllowed.subtracting(allowedInAll).sorted())

print("Allowed in path")
print(urlPathAllowed.subtracting(allowedInAll).sorted())

print("Allowed in query")
print(urlQueryAllowed.subtracting(allowedInAll).sorted())

print("Allowed in host")
print(urlFragmentAllowed.subtracting(allowedInAll).sorted())

print("Not allowed in host")
print(allowedInOne.subtracting(urlHostAllowed).sorted())

print("Not allowed in path")
print(allowedInOne.subtracting(urlPathAllowed).sorted())

print("Not allowed in query")
print(allowedInOne.subtracting(urlQueryAllowed).sorted())

print("Not allowed in host")
print(allowedInOne.subtracting(urlFragmentAllowed).sorted())

