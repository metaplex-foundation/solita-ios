import Foundation
import Beet
import Solana

/**
 * De/Serializer for solana {@link PublicKey}s aka `publicKey`.
 *
 * ## Using PublicKey Directly
 *
 * @category beet/solana
 */
public class BeetPublicKey: ScalarFixedSizeBeet {
    public var description: String = "PublicKey"
    public var byteSize: UInt
    private let beet = FixedSizeUint8Array(len: 32)
    public init(){
        byteSize = beet.byteSize
    }

    public func write<T>(buf: inout Data, offset: Int, value: T) {
        let val = value as! PublicKey
        beet.write(buf: &buf, offset: offset, value: val.data)
    }
    
    public func read<T>(buf: Data, offset: Int) -> T {
        let data: Data = beet.read(buf: buf, offset: offset)
        return PublicKey(data: data) as! T
    }
}