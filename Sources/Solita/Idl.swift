import Foundation
import Beet
import BeetSolana

public struct Idl: Decodable {
    let version: String
    let name: String
    let instructions: [IdlInstruction]
    let state: IdlState?
    let accounts: [IdlAccount]?
    let types: [IdlDefinedTypeDefinition]?
    let events: [IdlEvent]?
    let errors: [IdlError]?
    let metadata: IdlMetadata?
}

public struct IdlMetadata: Decodable {
    let address: String
}

public struct IdlEvent: Decodable {
    let name: String
    let fields: [IdlEventField]
}

public struct IdlEventField: Decodable {
    let name: String
    let type: IdlType
    let index: Bool
}

public struct IdlInstruction: Decodable {
    let name: String
    let accounts: [IdlInstructionAccountType]
    let args: [IdlInstructionArg]
}

public struct IdlState: Decodable {
    let `struct`: IdlDefinedTypeDefinition
    let methods: [IdlStateMethod]
}

public typealias IdlStateMethod = IdlInstruction

public enum IdlInstructionAccountType: Decodable {
    case idlAccount(IdlInstructionAccount)
    case idlAccounts(IdlInstructionAccounts)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(IdlInstructionAccount.self) {
            self = .idlAccount(x)
            return
        }
        if let x = try? container.decode(IdlInstructionAccounts.self) {
            self = .idlAccounts(x)
            return
        }
        throw DecodingError.typeMismatch(IdlInstructionAccountType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for IdlInstructionAccountType"))
    }
}

public struct IdlInstructionAccount: Decodable {
    let name: String
    let isMut: Bool
    let isSigner: Bool
    let desc: String?
    let optional: Bool?
}

public struct IdlInstructionAccounts: Decodable {
    let name: String
    let accounts: [IdlInstructionAccountType]
}

public struct IdlInstructionArg: Decodable {
    let name: String
    let type: IdlType
}

public struct IdlField: Decodable {
    let name: String
    let type: IdlType
    let attrs: [String]?
}

public struct IdlAccount: Decodable {
    let name: String
    let type: IdlDefinedType
}

public struct IdlDefinedTypeDefinition: Decodable {
    let name: String
    let type: IdlDefinedType
}

public enum IdlTypeDefTyKind: String, Decodable {
    case `struct`
    case `enum`
}

public struct IdlDefinedType: Decodable {
    let kind: IdlTypeDefTyKind
    let fields: IdlTypeDefStruct?
    let variants: [IdlEnumVariant]?
}

public typealias IdlTypeDefStruct = [IdlField]

public enum IdlTypeEnum: Decodable {
    case IdlTypeScalarEnum
    case IdlTypeDataEnum
}

public struct IdlTypeScalarEnum: Decodable {
    let kind: String = "enum"
    let variants: [IdlEnumVariant]
}

public struct IdlTypeDataEnum: Decodable {
    let kind: String = "enum"
    let variants: [IdlDataEnumVariant]
}

public struct IdlDataEnumVariant: Decodable {
  let name: String
  let fields: [IdlField]
}

public indirect enum IdlType: Decodable {
    case beetTypeMapKey(BeetTypeMapKey)
    case publicKey(BeetSolanaTypeMapKey)
    case idlTypeDefined(IdlTypeDefined)
    case idlTypeOption(IdlTypeOption)
    case idlTypeVec(IdlTypeVec)
    case idlTypeArray(IdlTypeArray)
    case idlTypeEnum(IdlTypeEnum)
    case idlTypeDataEnum(IdlTypeDataEnum)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self){
            self = try IdlType.init(fromKey: x, from: decoder)
            return
        }        
        if let x = try? container.decode(IdlTypeArray.self) {
            self = .idlTypeArray(x)
            return
        }
        if let x = try? container.decode(IdlTypeVec.self) {
            self = .idlTypeVec(x)
            return
        }
        if let x = try? container.decode(IdlTypeOption.self) {
            self = .idlTypeOption(x)
            return
        }
        if let x = try? container.decode(IdlTypeDefined.self) {
            self = .idlTypeDefined(x)
            return
        }
        
        throw DecodingError.typeMismatch(IdlType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for IdlType"))
    }
    
    fileprivate init(fromKey: String, from decoder: Decoder) throws {
        if let number = NumbersTypeMapKey(rawValue: fromKey){
            self = .beetTypeMapKey(.numbersTypeMapKey(number))
            return
        }
        if let string = StringTypeMapKey(rawValue: fromKey){
            self = .beetTypeMapKey(.stringTypeMapKey(string))
            return
        }
        
        if let composite = CompositesTypeMapKey(rawValue: fromKey){
            self = .beetTypeMapKey(.compositesTypeMapKey(composite))
            return
        }
        
        if let enums = EnumsTypeMapKey(rawValue: fromKey){
            self = .beetTypeMapKey(.enumsTypeMapKey(enums))
            return
        }
        
        if let aliases = AliasesTypeMapKey(rawValue: fromKey){
            self = .beetTypeMapKey(.aliasesTypeMapKey(aliases))
            return
        }
        if fromKey == "bytes" {
            self = .beetTypeMapKey(.aliasesTypeMapKey(.Uint8Array))
            return
        }
        if let publicKey = KeysTypeMapKey(rawValue: fromKey){
            self = .publicKey(.keysTypeMapKey(publicKey))
            return
        }
        throw DecodingError.typeMismatch(IdlType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Not a valid Key: \(fromKey)"))
    }
}

public struct IdlTypeArrayInner: Decodable {
    let idlType: IdlType
    let size: Int
}

public struct IdlTypeArray: Decodable {
    let array: [IdlTypeArrayInner]
    private enum CodingKeys: String, CodingKey { case array }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tempArray = try container.decode([Any].self, forKey: .array)
        if let string = tempArray[0] as? String {
            array = [IdlTypeArrayInner(idlType: try IdlType(fromKey: string, from: decoder), size: tempArray[1] as! Int)]
        } else {
            throw DecodingError.typeMismatch(IdlType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Inner nested Types not supported yet"))
        }
    }
}

public struct IdlTypeVec: Decodable {
    let vec: IdlType
}

public struct IdlTypeOption: Decodable {
    let option: IdlType
}

// User defined type.
public struct IdlTypeDefined: Decodable {
    let defined: String
}

public struct IdlEnumVariant: Decodable {
    let name: String
    let fields: IdlEnumFields?
}

public enum IdlEnumFields: Decodable {
    case idlEnumFieldsNamed(IdlEnumFieldsNamed)
    case idlEnumFieldsTuple(IdlEnumFieldsTuple)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(IdlEnumFieldsNamed.self) {
            self = .idlEnumFieldsNamed(x)
            return
        }
        if let x = try? container.decode(IdlEnumFieldsTuple.self) {
            self = .idlEnumFieldsTuple(x)
            return
        }
        throw DecodingError.typeMismatch(IdlEnumFields.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for TypeUnion"))
    }
}

public typealias IdlEnumFieldsNamed = [IdlField]

public typealias IdlEnumFieldsTuple = [IdlType]

public struct IdlError: Codable {
    let code: Int
    let name: String
    let msg: String?
}
