{
    { }
    function abi_decode_t_address(offset) -> value
    {
        value := calldataload(offset)
        validator_revert_t_address(value)
    }
    function abi_decode_t_bool(offset) -> value
    {
        value := calldataload(offset)
        validator_revert_t_bool(value)
    }
    function abi_decode_t_string(offset, end) -> array
    {
        if iszero(slt(add(offset, 0x1f), end)) { revert(array, array) }
        let length := calldataload(offset)
        array := allocateMemory(array_allocation_size_t_string(length))
        mstore(array, length)
        if gt(add(add(offset, length), 0x20), end) { revert(0, 0) }
        calldatacopy(add(array, 0x20), add(offset, 0x20), length)
        mstore(add(add(array, length), 0x20), 0)
    }
    function abi_decode_t_uint112_fromMemory(offset) -> value
    {
        value := mload(offset)
        if iszero(eq(value, and(value, 0xffffffffffffffffffffffffffff))) { revert(0, 0) }
    }
    function abi_decode_tuple_t_address(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        let value := calldataload(headStart)
        validator_revert_t_address(value)
        value0 := value
    }
    function abi_decode_tuple_t_address_fromMemory(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        let value := mload(headStart)
        validator_revert_t_address(value)
        value0 := value
    }
    function abi_decode_tuple_t_addresst_address(headStart, dataEnd) -> value0, value1
    {
        if slt(sub(dataEnd, headStart), 64) { revert(value1, value1) }
        let value := calldataload(headStart)
        validator_revert_t_address(value)
        value0 := value
        let value_1 := calldataload(add(headStart, 32))
        validator_revert_t_address(value_1)
        value1 := value_1
    }
    function abi_decode_tuple_t_addresst_string_memory_ptrt_uint256(headStart, dataEnd) -> value0, value1, value2
    {
        if slt(sub(dataEnd, headStart), 96) { revert(value2, value2) }
        let value := calldataload(headStart)
        validator_revert_t_address(value)
        value0 := value
        let offset := calldataload(add(headStart, 32))
        if gt(offset, 0xffffffffffffffff) { revert(value2, value2) }
        value1 := abi_decode_t_string(add(headStart, offset), dataEnd)
        value2 := calldataload(add(headStart, 64))
    }
    function abi_decode_tuple_t_addresst_uint256(headStart, dataEnd) -> value0, value1
    {
        if slt(sub(dataEnd, headStart), 64) { revert(value0, value0) }
        let value := calldataload(headStart)
        validator_revert_t_address(value)
        value0 := value
        value1 := calldataload(add(headStart, 32))
    }
    function abi_decode_tuple_t_addresst_uint256t_uint256(headStart, dataEnd) -> value0, value1, value2
    {
        if slt(sub(dataEnd, headStart), 96) { revert(value0, value0) }
        let value := calldataload(headStart)
        validator_revert_t_address(value)
        value0 := value
        value1 := calldataload(add(headStart, 32))
        value2 := calldataload(add(headStart, 64))
    }
    function abi_decode_tuple_t_bool_fromMemory(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        let value := mload(headStart)
        validator_revert_t_bool(value)
        value0 := value
    }
    function abi_decode_tuple_t_contract$_IDAOMintingPool_$1785(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        let value := calldataload(headStart)
        validator_revert_t_address(value)
        value0 := value
    }
    function abi_decode_tuple_t_contract$_IidovoteContract_$1793(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        let value := calldataload(headStart)
        validator_revert_t_address(value)
        value0 := value
    }
    function abi_decode_tuple_t_string_memory_ptr(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        let offset := calldataload(headStart)
        if gt(offset, 0xffffffffffffffff) { revert(value0, value0) }
        value0 := abi_decode_t_string(add(headStart, offset), dataEnd)
    }
    function abi_decode_tuple_t_string_memory_ptr_fromMemory(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        let offset := mload(headStart)
        if gt(offset, 0xffffffffffffffff) { revert(value0, value0) }
        let _1 := add(headStart, offset)
        if iszero(slt(add(_1, 0x1f), dataEnd)) { revert(value0, value0) }
        let length := mload(_1)
        let array := allocateMemory(array_allocation_size_t_string(length))
        mstore(array, length)
        if gt(add(add(_1, length), 32), dataEnd) { revert(value0, value0) }
        copy_memory_to_memory(add(_1, 32), add(array, 32), length)
        value0 := array
    }
    function abi_decode_tuple_t_struct$_idoCoinInfoHead_$2002_memory_ptr(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        let offset := calldataload(headStart)
        let _1 := 0xffffffffffffffff
        if gt(offset, _1) { revert(value0, value0) }
        let _2 := add(headStart, offset)
        let _3 := 0x0220
        if slt(sub(dataEnd, _2), _3) { revert(value0, value0) }
        let value := allocateMemory(_3)
        mstore(value, abi_decode_t_address(_2))
        let offset_1 := calldataload(add(_2, 32))
        if gt(offset_1, _1) { revert(value0, value0) }
        mstore(add(value, 32), abi_decode_t_string(add(_2, offset_1), dataEnd))
        mstore(add(value, 64), calldataload(add(_2, 64)))
        mstore(add(value, 96), calldataload(add(_2, 96)))
        mstore(add(value, 128), calldataload(add(_2, 128)))
        mstore(add(value, 160), calldataload(add(_2, 160)))
        mstore(add(value, 192), abi_decode_t_bool(add(_2, 192)))
        mstore(add(value, 224), calldataload(add(_2, 224)))
        let _4 := 256
        mstore(add(value, _4), abi_decode_t_bool(add(_2, _4)))
        let _5 := 288
        mstore(add(value, _5), calldataload(add(_2, _5)))
        let _6 := 320
        mstore(add(value, _6), abi_decode_t_bool(add(_2, _6)))
        let _7 := 352
        mstore(add(value, _7), calldataload(add(_2, _7)))
        let _8 := 384
        mstore(add(value, _8), calldataload(add(_2, _8)))
        let _9 := 416
        mstore(add(value, _9), calldataload(add(_2, _9)))
        let _10 := 448
        mstore(add(value, _10), calldataload(add(_2, _10)))
        let _11 := 480
        mstore(add(value, _11), calldataload(add(_2, _11)))
        let _12 := 512
        mstore(add(value, _12), calldataload(add(_2, _12)))
        value0 := value
    }
    function abi_decode_tuple_t_uint112t_uint112t_uint32_fromMemory(headStart, dataEnd) -> value0, value1, value2
    {
        if slt(sub(dataEnd, headStart), 96) { revert(value2, value2) }
        value0 := abi_decode_t_uint112_fromMemory(headStart)
        value1 := abi_decode_t_uint112_fromMemory(add(headStart, 32))
        let value := mload(add(headStart, 64))
        if iszero(eq(value, and(value, 0xffffffff))) { revert(value2, value2) }
        value2 := value
    }
    function abi_decode_tuple_t_uint256(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        value0 := calldataload(headStart)
    }
    function abi_decode_tuple_t_uint256_fromMemory(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(value0, value0) }
        value0 := mload(headStart)
    }
    function abi_decode_tuple_t_uint256t_uint256(headStart, dataEnd) -> value0, value1
    {
        if slt(sub(dataEnd, headStart), 64) { revert(value0, value0) }
        value0 := calldataload(headStart)
        value1 := calldataload(add(headStart, 32))
    }
    function abi_decode_tuple_t_uint256t_uint256t_uint256(headStart, dataEnd) -> value0, value1, value2
    {
        if slt(sub(dataEnd, headStart), 96) { revert(value2, value2) }
        value0 := calldataload(headStart)
        value1 := calldataload(add(headStart, 32))
        value2 := calldataload(add(headStart, 64))
    }
    function abi_encode_t_address(value, pos)
    {
        mstore(pos, and(value, sub(shl(160, 1), 1)))
    }
    function abi_encode_t_array$_t_address_$dyn(value, pos) -> end
    {
        let length := mload(value)
        mstore(pos, length)
        let _1 := 0x20
        pos := add(pos, _1)
        let srcPtr := add(value, _1)
        let i := end
        for { } lt(i, length) { i := add(i, 1) }
        {
            mstore(pos, and(mload(srcPtr), sub(shl(160, 1), 1)))
            pos := add(pos, _1)
            srcPtr := add(srcPtr, _1)
        }
        end := pos
    }
    function abi_encode_t_bool(value, pos)
    {
        mstore(pos, iszero(iszero(value)))
    }
    function abi_encode_t_string(value, pos) -> end
    {
        let length := mload(value)
        mstore(pos, length)
        copy_memory_to_memory(add(value, 0x20), add(pos, 0x20), length)
        end := add(add(pos, and(add(length, 31), not(31))), 0x20)
    }
    function abi_encode_t_struct$_idoCoinInfoHead(value, pos) -> end
    {
        let _1 := 0x0220
        abi_encode_t_address(mload(value), pos)
        let memberValue0 := mload(add(value, 0x20))
        mstore(add(pos, 0x20), _1)
        let tail := abi_encode_t_string(memberValue0, add(pos, _1))
        mstore(add(pos, 0x40), mload(add(value, 0x40)))
        mstore(add(pos, 0x60), mload(add(value, 0x60)))
        mstore(add(pos, 0x80), mload(add(value, 0x80)))
        mstore(add(pos, 0xa0), mload(add(value, 0xa0)))
        let memberValue0_1 := mload(add(value, 0xc0))
        abi_encode_t_bool(memberValue0_1, add(pos, 0xc0))
        mstore(add(pos, 0xe0), mload(add(value, 0xe0)))
        let _2 := 0x0100
        let memberValue0_2 := mload(add(value, _2))
        abi_encode_t_bool(memberValue0_2, add(pos, _2))
        let _3 := 0x0120
        mstore(add(pos, _3), mload(add(value, _3)))
        let _4 := 0x0140
        let memberValue0_3 := mload(add(value, _4))
        abi_encode_t_bool(memberValue0_3, add(pos, _4))
        let _5 := 0x0160
        mstore(add(pos, _5), mload(add(value, _5)))
        let _6 := 0x0180
        mstore(add(pos, _6), mload(add(value, _6)))
        let _7 := 0x01a0
        mstore(add(pos, _7), mload(add(value, _7)))
        let _8 := 0x01c0
        mstore(add(pos, _8), mload(add(value, _8)))
        let _9 := 0x01e0
        mstore(add(pos, _9), mload(add(value, _9)))
        let _10 := 0x0200
        mstore(add(pos, _10), mload(add(value, _10)))
        end := tail
    }
    function abi_encode_tuple_packed_t_bytes1_t_address_t_bytes32_t_bytes32__to_t_bytes1_t_address_t_bytes32_t_bytes32__nonPadded_inplace_fromStack_reversed(pos, value3, value2, value1, value0) -> end
    {
        mstore(pos, and(value0, shl(248, 255)))
        mstore(add(pos, 1), and(shl(96, value1), not(0xffffffffffffffffffffffff)))
        mstore(add(pos, 21), value2)
        mstore(add(pos, 53), value3)
        end := add(pos, 85)
    }
    function abi_encode_tuple_packed_t_bytes_memory_ptr__to_t_bytes_memory_ptr__nonPadded_inplace_fromStack_reversed(pos, value0) -> end
    {
        let length := mload(value0)
        copy_memory_to_memory(add(value0, 0x20), pos, length)
        end := add(pos, length)
    }
    function abi_encode_tuple_packed_t_string_memory_ptr_t_uint256_t_uint256_t_uint256__to_t_string_memory_ptr_t_uint256_t_uint256_t_uint256__nonPadded_inplace_fromStack_reversed(pos, value3, value2, value1, value0) -> end
    {
        let length := mload(value0)
        copy_memory_to_memory(add(value0, 0x20), pos, length)
        let end_1 := add(pos, length)
        mstore(end_1, value1)
        mstore(add(end_1, 0x20), value2)
        mstore(add(end_1, 64), value3)
        end := add(end_1, 96)
    }
    function abi_encode_tuple_t_address__to_t_address__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
    }
    function abi_encode_tuple_t_address_payable__to_t_address__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
    }
    function abi_encode_tuple_t_address_payable_t_address_t_uint256_t_uint256_t_address__to_t_address_t_address_t_uint256_t_uint256_t_address__fromStack_reversed(headStart, value4, value3, value2, value1, value0) -> tail
    {
        tail := add(headStart, 160)
        let _1 := sub(shl(160, 1), 1)
        mstore(headStart, and(value0, _1))
        mstore(add(headStart, 32), and(value1, _1))
        mstore(add(headStart, 64), value2)
        mstore(add(headStart, 96), value3)
        mstore(add(headStart, 128), and(value4, _1))
    }
    function abi_encode_tuple_t_address_payable_t_contract$_IERC20_$400_t_uint256_t_address_t_uint256__to_t_address_t_address_t_uint256_t_address_t_uint256__fromStack_reversed(headStart, value4, value3, value2, value1, value0) -> tail
    {
        tail := add(headStart, 160)
        let _1 := sub(shl(160, 1), 1)
        mstore(headStart, and(value0, _1))
        mstore(add(headStart, 32), and(value1, _1))
        mstore(add(headStart, 64), value2)
        mstore(add(headStart, 96), and(value3, _1))
        mstore(add(headStart, 128), value4)
    }
    function abi_encode_tuple_t_address_payable_t_uint256_t_address__to_t_address_t_uint256_t_address__fromStack_reversed(headStart, value2, value1, value0) -> tail
    {
        tail := add(headStart, 96)
        let _1 := sub(shl(160, 1), 1)
        mstore(headStart, and(value0, _1))
        mstore(add(headStart, 32), value1)
        mstore(add(headStart, 64), and(value2, _1))
    }
    function abi_encode_tuple_t_address_payable_t_uint256_t_address_t_uint256__to_t_address_t_uint256_t_address_t_uint256__fromStack_reversed(headStart, value3, value2, value1, value0) -> tail
    {
        tail := add(headStart, 128)
        let _1 := sub(shl(160, 1), 1)
        mstore(headStart, and(value0, _1))
        mstore(add(headStart, 32), value1)
        mstore(add(headStart, 64), and(value2, _1))
        mstore(add(headStart, 96), value3)
    }
    function abi_encode_tuple_t_address_payable_t_uint256_t_uint256__to_t_address_t_uint256_t_uint256__fromStack_reversed(headStart, value2, value1, value0) -> tail
    {
        tail := add(headStart, 96)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
        mstore(add(headStart, 32), value1)
        mstore(add(headStart, 64), value2)
    }
    function abi_encode_tuple_t_address_t_address__to_t_address_t_address__fromStack_reversed(headStart, value1, value0) -> tail
    {
        tail := add(headStart, 64)
        let _1 := sub(shl(160, 1), 1)
        mstore(headStart, and(value0, _1))
        mstore(add(headStart, 32), and(value1, _1))
    }
    function abi_encode_tuple_t_address_t_address_t_uint256__to_t_address_t_address_t_uint256__fromStack_reversed(headStart, value2, value1, value0) -> tail
    {
        tail := add(headStart, 96)
        let _1 := sub(shl(160, 1), 1)
        mstore(headStart, and(value0, _1))
        mstore(add(headStart, 32), and(value1, _1))
        mstore(add(headStart, 64), value2)
    }
    function abi_encode_tuple_t_address_t_uint256__to_t_address_t_uint256__fromStack_reversed(headStart, value1, value0) -> tail
    {
        tail := add(headStart, 64)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
        mstore(add(headStart, 32), value1)
    }
    function abi_encode_tuple_t_address_t_uint256_t_uint256__to_t_address_t_uint256_t_uint256__fromStack_reversed(headStart, value2, value1, value0) -> tail
    {
        tail := add(headStart, 96)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
        mstore(add(headStart, 32), value1)
        mstore(add(headStart, 64), value2)
    }
    function abi_encode_tuple_t_bool__to_t_bool__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, iszero(iszero(value0)))
    }
    function abi_encode_tuple_t_contract$_IDAOMintingPool_$1785__to_t_address__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
    }
    function abi_encode_tuple_t_contract$_IERC20_$400__to_t_address__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
    }
    function abi_encode_tuple_t_contract$_IidovoteContract_$1793__to_t_address__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
    }
    function abi_encode_tuple_t_string_memory_ptr__to_t_string_memory_ptr__fromStack_reversed(headStart, value0) -> tail
    {
        mstore(headStart, 32)
        tail := abi_encode_t_string(value0, add(headStart, 32))
    }
    function abi_encode_tuple_t_stringliteral_07c33fefa4b5d2362ad472980c0e9ebd3e7a7554760455db5abbc9274443a845__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 32)
        mstore(add(headStart, 64), "cannot exceed the purchase scope")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_20eefb922b7db50fbb326210226291a2c9f960541d7388b838c4c552af8e2fc6__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 16)
        mstore(add(headStart, 64), "already withdraw")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_245f15ff17f551913a7a18385165551503906a406f905ac1c2437281a7cd0cfe__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 38)
        mstore(add(headStart, 64), "Ownable: new owner is the zero a")
        mstore(add(headStart, 96), "ddress")
        tail := add(headStart, 128)
    }
    function abi_encode_tuple_t_stringliteral_30cc447bcc13b3e22b45cef0dd9b0b514842d836dd9b6eb384e20dedfb47723a__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 27)
        mstore(add(headStart, 64), "SafeMath: addition overflow")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_34e4b6078b434f980e08dc0cfc5234edc578558d07ab3bd50d1449825c684350__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 15)
        mstore(add(headStart, 64), "zero take amout")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_45d2426e5989ffb85f9c92165656cb91e9803f38adc7582ec79672d234ede541__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 11)
        mstore(add(headStart, 64), "ipo not end")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_557681e31d6e473932f8416455381a3c998305fda857d825a490df871294bf75__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 20)
        mstore(add(headStart, 64), "can not zero address")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_5e04933fd09924c773e357322332f30a8c964e05bb24ed575e5f330ab446022d__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 15)
        mstore(add(headStart, 64), "ipo was expired")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_6c283ab9f3c6dd8a9a845390f8df7d5e7fcd9b9a3f9ac5f02bb9a55a78a99bab__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 23)
        mstore(add(headStart, 64), "make amount is negative")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_7670f03009af3a60af91c89ffa8f47055fc38b4a75a2db8e07a22a5f0dc5f8e1__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 10)
        mstore(add(headStart, 64), "no settled")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_8299d6ea0dde6e53181af90c7bd96060af9f57dfb379bedd9e5a2f65a0fbe06b__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 15)
        mstore(add(headStart, 64), "withdraw exceed")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_9113bb53c2876a3805b2c9242029423fc540a728243ce887ab24c82cf119fba3__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 33)
        mstore(add(headStart, 64), "SafeMath: multiplication overflo")
        mstore(add(headStart, 96), "w")
        tail := add(headStart, 128)
    }
    function abi_encode_tuple_t_stringliteral_9924ebdf1add33d25d4ef888e16131f0a5687b0580a36c21b5c301a6c462effe__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 32)
        mstore(add(headStart, 64), "Ownable: caller is not the owner")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_9bcecaac04cee3c5a54f4f56f2f753c274840439947484207b6ef39082e98a0d__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 21)
        mstore(add(headStart, 64), "zero withdraw balance")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_9ed995b0ea699d0ed62c73d091415d85e522fe688737dd9909d07ee43d0c2a61__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 15)
        mstore(add(headStart, 64), "ipo not expired")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_aa395b6a6f4d717a8f436942b6d1fe54bfa5998054fa89d964a0583cfff724ad__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 32)
        mstore(add(headStart, 64), "amount must be greater than zero")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_cc2e4e38850b7c0a3e942cfed89b71c77302df25bcb2ec297a0c4ff9ff6b90ad__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 29)
        mstore(add(headStart, 64), "Address: call to non-contract")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_d5b2033fa922277e78fbfb95ec09b7c73e0e1d0f08fbd8f0ec344cd02a971cc0__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 19)
        mstore(add(headStart, 64), "winning rate exceed")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_d974ee9850f47ef8c5f1b45cce882f92f9a7ba50c0e9ccb0faba8b54d31f8c1f__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 17)
        mstore(add(headStart, 64), "no authentication")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_da41c01f977a68d42c01e46e6e3e76dbdc822df87f49fe387348673fc3163d3b__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 20)
        mstore(add(headStart, 64), "unauthenticated user")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_df71ca00518b61b68f8cad69b6ed6fadc1741e22767f14eb54c36531ffc0500c__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 23)
        mstore(add(headStart, 64), "proposal has not passed")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_e11ad79d1e4a7f2e5f376964cb99e8e8f7904e3fc16a109f7a7ecb9aa7956dcd__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 42)
        mstore(add(headStart, 64), "SafeERC20: ERC20 operation did n")
        mstore(add(headStart, 96), "ot succeed")
        tail := add(headStart, 128)
    }
    function abi_encode_tuple_t_stringliteral_e3d33a1734e033bea95df2cb3b20d931e1d0bf49ba54789e3407cc686faa7d8f__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 34)
        mstore(add(headStart, 64), "must be within the validity peri")
        mstore(add(headStart, 96), "od")
        tail := add(headStart, 128)
    }
    function abi_encode_tuple_t_struct$_applyCoinInfo_$2135_memory_ptr__to_t_struct$_applyCoinInfo_$2135_memory_ptr__fromStack_reversed(headStart, value0) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), mload(value0))
        mstore(add(headStart, 64), and(mload(add(value0, 32)), sub(shl(160, 1), 1)))
        let memberValue0 := mload(add(value0, 64))
        mstore(add(headStart, 96), 0x80)
        let tail_1 := abi_encode_t_string(memberValue0, add(headStart, 160))
        mstore(add(headStart, 0x80), mload(add(value0, 96)))
        tail := tail_1
    }
    function abi_encode_tuple_t_struct$_idoCoinInfo_$2037_memory_ptr__to_t_struct$_idoCoinInfo_$2037_memory_ptr__fromStack_reversed(headStart, value0) -> tail
    {
        mstore(headStart, 32)
        let memberValue0 := mload(value0)
        let _1 := 0x0220
        mstore(add(headStart, 32), _1)
        let tail_1 := abi_encode_t_struct$_idoCoinInfoHead(memberValue0, add(headStart, 576))
        mstore(add(headStart, 64), mload(add(value0, 32)))
        let memberValue0_1 := mload(add(value0, 64))
        abi_encode_t_address(memberValue0_1, add(headStart, 96))
        mstore(add(headStart, 128), mload(add(value0, 96)))
        mstore(add(headStart, 160), mload(add(value0, 128)))
        mstore(add(headStart, 192), mload(add(value0, 160)))
        mstore(add(headStart, 224), mload(add(value0, 192)))
        let _2 := mload(add(value0, 224))
        let _3 := 256
        mstore(add(headStart, _3), _2)
        let _4 := mload(add(value0, _3))
        let _5 := 288
        mstore(add(headStart, _5), _4)
        let _6 := mload(add(value0, _5))
        let _7 := 320
        mstore(add(headStart, _7), _6)
        let _8 := mload(add(value0, _7))
        let _9 := 352
        mstore(add(headStart, _9), _8)
        let _10 := mload(add(value0, _9))
        let _11 := 384
        mstore(add(headStart, _11), _10)
        let memberValue0_2 := mload(add(value0, _11))
        let _12 := 416
        abi_encode_t_bool(memberValue0_2, add(headStart, _12))
        let _13 := mload(add(value0, _12))
        let _14 := 448
        mstore(add(headStart, _14), _13)
        let memberValue0_3 := mload(add(value0, _14))
        let _15 := 480
        abi_encode_t_address(memberValue0_3, add(headStart, _15))
        let _16 := mload(add(value0, _15))
        let _17 := 512
        mstore(add(headStart, _17), _16)
        let memberValue0_4 := mload(add(value0, _17))
        abi_encode_t_bool(memberValue0_4, add(headStart, _1))
        tail := tail_1
    }
    function abi_encode_tuple_t_struct$_userInfo_$2120_memory_ptr__to_t_struct$_userInfo_$2120_memory_ptr__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 288)
        mstore(headStart, mload(value0))
        mstore(add(headStart, 0x20), and(mload(add(value0, 0x20)), sub(shl(160, 1), 1)))
        mstore(add(headStart, 0x40), mload(add(value0, 0x40)))
        mstore(add(headStart, 0x60), mload(add(value0, 0x60)))
        let memberValue0 := mload(add(value0, 0x80))
        abi_encode_t_address(memberValue0, add(headStart, 0x80))
        mstore(add(headStart, 0xa0), mload(add(value0, 0xa0)))
        mstore(add(headStart, 0xc0), mload(add(value0, 0xc0)))
        mstore(add(headStart, 0xe0), mload(add(value0, 0xe0)))
        let _1 := 0x0100
        let memberValue0_1 := mload(add(value0, _1))
        abi_encode_t_bool(memberValue0_1, add(headStart, _1))
    }
    function abi_encode_tuple_t_uint256__to_t_uint256__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, value0)
    }
    function abi_encode_tuple_t_uint256_t_array$_t_address_$dyn_memory_ptr_t_address_t_uint256__to_t_uint256_t_array$_t_address_$dyn_memory_ptr_t_address_t_uint256__fromStack_reversed(headStart, value3, value2, value1, value0) -> tail
    {
        mstore(headStart, value0)
        mstore(add(headStart, 32), 128)
        tail := abi_encode_t_array$_t_address_$dyn(value1, add(headStart, 128))
        mstore(add(headStart, 64), and(value2, sub(shl(160, 1), 1)))
        mstore(add(headStart, 96), value3)
    }
    function abi_encode_tuple_t_uint256_t_bool__to_t_uint256_t_bool__fromStack_reversed(headStart, value1, value0) -> tail
    {
        tail := add(headStart, 64)
        mstore(headStart, value0)
        mstore(add(headStart, 32), iszero(iszero(value1)))
    }
    function abi_encode_tuple_t_uint256_t_rational_0_by_1_t_array$_t_address_$dyn_memory_ptr_t_address_t_uint256__to_t_uint256_t_uint256_t_array$_t_address_$dyn_memory_ptr_t_address_t_uint256__fromStack_reversed(headStart, value4, value3, value2, value1, value0) -> tail
    {
        mstore(headStart, value0)
        mstore(add(headStart, 32), value1)
        mstore(add(headStart, 64), 160)
        tail := abi_encode_t_array$_t_address_$dyn(value2, add(headStart, 160))
        mstore(add(headStart, 96), and(value3, sub(shl(160, 1), 1)))
        mstore(add(headStart, 128), value4)
    }
    function abi_encode_tuple_t_uint256_t_uint256_t_uint256__to_t_uint256_t_uint256_t_uint256__fromStack_reversed(headStart, value2, value1, value0) -> tail
    {
        tail := add(headStart, 96)
        mstore(headStart, value0)
        mstore(add(headStart, 32), value1)
        mstore(add(headStart, 64), value2)
    }
    function allocateMemory(size) -> memPtr
    {
        memPtr := mload(64)
        let newFreePtr := add(memPtr, size)
        if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr)) { invalid() }
        mstore(64, newFreePtr)
    }
    function array_allocation_size_t_string(length) -> size
    {
        if gt(length, 0xffffffffffffffff) { invalid() }
        size := add(and(add(length, 0x1f), not(31)), 0x20)
    }
    function copy_memory_to_memory(src, dst, length)
    {
        let i := 0
        for { } lt(i, length) { i := add(i, 32) }
        {
            mstore(add(dst, i), mload(add(src, i)))
        }
        if gt(i, length) { mstore(add(dst, length), 0) }
    }
    function validator_revert_t_address(value)
    {
        if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
    }
    function validator_revert_t_bool(value)
    {
        if iszero(eq(value, iszero(iszero(value)))) { revert(0, 0) }
    }
}