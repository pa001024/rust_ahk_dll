#Requires AutoHotkey v2.0

isMap(_obj) => _obj is Map
isArray(_obj) => _obj is Array
isString(_obj) => _obj is String
isVarRef(_obj) => _obj is VarRef
isComObj(_obj) => _obj is ComObject
isFunction(_obj) => _obj is Func
isPrimitive(_obj) => _obj is Primitive

Array.DefineProp('from', { call: Array_From })
Array.DefineProp('isArray', { call: isArray })

arrProto := Array.Prototype
arrProto.DefineProp("concat", { call: Array_Concat })
arrProto.DefineProp("peek", { call: Array_Peek })
arrProto.DefineProp("at", { call: Array_At })
arrProto.DefineProp("every", { call: Array_Every })
arrProto.DefineProp("fill", { call: Array_Fill })
arrProto.DefineProp("flat", { call: Array_Flat })
arrProto.DefineProp("filter", { call: Array_Filter })
arrProto.DefineProp("find", { call: Array_Find })
arrProto.DefineProp("findIndex", { call: Array_FindIndex })
arrProto.DefineProp("findLast", { call: Array_FindLast })
arrProto.DefineProp("findLastIndex", { call: Array_FindLastIndex })
arrProto.DefineProp("forEach", { call: Array_ForEach })
arrProto.DefineProp("deepClone", { call: Array_DeepClone })
arrProto.DefineProp("includes", { call: Array_Includes })
arrProto.DefineProp("join", { call: Array_Join })
arrProto.DefineProp("map", { call: Array_Map })
arrProto.DefineProp("reduce", { call: Array_Reduce })
arrProto.DefineProp("reverse", { call: Array_Reverse })
arrProto.DefineProp("toReverse", { call: Array_ToReverse })
arrProto.DefineProp("shift", { call: Array_Shift })
arrProto.DefineProp("max", { call: Array_Max })
arrProto.DefineProp("min", { call: Array_Min })
arrProto.DefineProp("slice", { call: Array_Slice })
arrProto.DefineProp("splice", { call: Array_Splice })
arrProto.DefineProp("toString", { call: Array_ToString })

; 静态方法从字符串或数组创建一个新的**深拷贝**的数组实例。
Array_From(this, arrayLike, mapFn?) {
    if not (IsArray(arrayLike) or IsString(arrayLike))
        throw Error('invalid param')
    if IsSet(mapFn) {
        switch mapFn.MaxParams {
            case 1: _fn := (v, *) => mapFn(v)
            case 2: _fn := (v, index, *) => mapFn(v, index)
            default: throw Error('invalid callback function')
        }
    } else _fn := (v, *) => v
    arr := []
    if arrayLike is Array {
        for v in arrayLike
            arr.Push(_fn(v, A_Index))
    } else arr := arrayLike.ToCharArray()
    return arr
}

Array_ToString(this) {
    r := ""
    for v in this
        r .= String(v)
    return r
}

; 将两个或多个数组或值合并成一个新数组。
; 此方法不会更改现有数组，而是返回一个新数组。
Array_Concat(this, value*) {
    r := this.DeepClone()
    for v in value
        IsArray(v) ? r.Push(v*) : r.Push(v)
    return r
}

; 查看数组末尾元素
Array_Peek(this) => this[this.Length]

; 方法接收一个整数值并返回该索引对应的元素，允许正数和负数。
; 负整数从数组中的最后一个元素开始倒数，0是无效索引。
Array_At(this, index) => index > 0 ? this[index] : this[this.Length + index + 1]

; 测试一个数组内的所有元素是否都能通过指定函数的测试。
; 它返回一个布尔值。
Array_Every(this, cb) {
    copy := this
    switch cb.MaxParams {
        case 1: _fn := (v, *) => cb(v)
        case 2: _fn := (v, index, *) => cb(v, index)
        case 3: _fn := (v, index, arr) => cb(v, index, arr)
        default: throw Error('invalid callback function')
    }
    for v in copy {
        if !_fn(v, A_Index, copy)
            return false
    }
    return true
}

; 用一个固定值填充一个数组中从起始索引（默认为 0）到终止索引（默认为 array.length）内的全部元素。
; 它返回修改后的数组。
Array_Fill(this, value, start?, end?) {
    l := this.Length
    if IsSet(start) {
        if IsSet(end) {
            end := end > l ? l : end
            start := start > end ? end : start
            d := end - start
        } else d := start > l ? l : l - start
        loop d + 1
            this[start + A_Index - 1] := value
    } else loop l
        this[A_Index] := value
}

; 扁平化数组，传入-1表示无限
Array_Flat(this, depth) {
    stack := [this.map(item => [item, depth])*], res := []
    while (stack.Length > 0) {
        sub := stack.Pop(), _item := sub[1], _depth := sub[2]
        if (IsArray(_item) && (_depth > 0 || depth = -1))
            stack.Push(_item.map(el => [el, _depth - 1])*)
        else res.Push(_item)
    }
    return res.reverse()
}

; 创建给定数组一部分的**深拷贝**（与js不同），其包含通过所提供函数实现的测试的所有元素。
Array_Filter(this, cb) {
    r := []
    switch cb.MaxParams {
        case 1: _fn := (v, *) => cb(v)
        case 2: _fn := (v, index, *) => cb(v, index)
        case 3: _fn := (v, index, arr) => cb(v, index, arr)
        default: throw Error('invalid callback function')
    }
    for v in this {
        if _fn(v, A_Index, this)
            r.Push(v)
    }
    return r
}

; 返回数组中满足提供的测试函数的第一个元素的值。否则返回 空。
Array_Find(this, cb) {
    for v in this {
        if cb(v)
            return v
    }
}

; 返回数组中满足提供的测试函数的第一个元素的索引。
Array_FindIndex(this, cb) {
    for v in this {
        if cb(v)
            return A_Index
    }
    return 0
}

; 反向迭代数组，并返回满足提供的测试函数的第一个元素的值。
Array_FindLast(this, cb) {
    loop l := this.Length {
        if cb(v := this[l - A_Index + 1])
            return v
    }
}

; 反向迭代数组，并返回满足提供的测试函数的第一个元素的索引。
Array_FindLastIndex(this, cb) {
    loop l := this.Length {
        if cb(this[l - A_Index + 1])
            return l - A_Index + 1
    }
}

; 对数组的每个元素执行一次给定的函数。
; 仅执行，而不返回任何结果
Array_ForEach(this, cb) {
    switch cb.MaxParams {
        case 1: _fn := (v, *) => cb(v)
        case 2: _fn := (v, index, *) => cb(v, index)
        case 3: _fn := (v, index, arr) => cb(v, index, arr)
        default: throw Error('invalid callback function')
    }
    for v in this
        _fn(v, A_Index, this)
}

; 返回数组的深拷贝。
Array_DeepClone(this) {
    arr := []
    for v in this
        arr.Push(v)
    return arr
}

; 用指定分隔符连接数组元素。
; 返回一个字符串
Array_Join(this, separator := ',') {
    if this.Length {
        for v in this {
            if IsSet(v)
                r .= String(v) (A_Index != this.Length ? separator : '')
        }
        return r || ''
    }
}

; 用来判断一个数组是否包含一个指定的值，根据情况，如果包含则返回 true，否则返回 false。
Array_Includes(this, searchElement, fromIndex?) {
    if IsSet(fromIndex) {
        l := this.Length
        if fromIndex > 0 {
            if fromIndex > l
                return false
            i := fromIndex
        } else {
            if fromIndex < -l || fromIndex = 0
                return this.FindIndex((v) => v = searchElement)
            i := l + fromIndex + 1
        }
        c := l - i + 1
        loop c {
            if this[i + A_Index - 1] = searchElement
                return true
        }
        return false
    } else {
        return this.FindIndex((v) => v = searchElement)
    }
}
; 创建一个新数组，这个新数组由原数组中的每个元素都调用一次提供的函数后的返回值组成。
Array_Map(this, cb) {
    switch cb.MaxParams {
        case 1: _fn := (v, *) => cb(v)
        case 2: _fn := (v, index, *) => cb(v, index)
        case 3: _fn := (v, index, arr) => cb(v, index, arr)
        default: throw Error('invalid callback function')
    }
    res := []
    for v in this
        res.push(_fn(v, A_Index, this))
    return res
}
; 对数组中的每个元素按序执行一个提供的 reducer 函数，每一次运行 reducer 会将先前元素的计算结果作为参数传入。
; 最后将其结果汇总为单个返回值。
Array_Reduce(this, cb, initialValue?) {
    if !this.Length and !IsSet(initialValue)
        throw TypeError('Reduce of empty array with no initial value')
    switch cb.MaxParams {
        case 1: _fn := (accumulator, *) => cb(accumulator)
        case 2: _fn := (accumulator, curVal, *) => cb(accumulator, curVal)
        case 3: _fn := (accumulator, curVal, index, *) => cb(accumulator, curVal, index)
        case 4: _fn := (accumulator, curVal, index, arr) => cb(accumulator, curVal, index, arr)
        default: throw Error('invalid callback function')
    }
    accumulator := initialValue ?? this[1], i := IsSet(initialValue) ? 1 : 2
    loop this.Length - i + 1
        accumulator := _fn(accumulator, this[i], i, this), i++
    return accumulator
}

; 就地反转数组中的元素，并返回同一数组的引用。
Array_Reverse(this) {
    l := this.Length
    loop l / 2 {
        temp := this[A_Index]
        this[A_Index] := this[l - A_Index + 1]
        this[l - A_Index + 1] := temp
    }
    return this
}
; 反转数组中的元素，并返回新数组的引用。
Array_ToReverse(this) {
    l := this.Length, arr := []
    loop l
        arr.Push(this[l - A_Index + 1])
    return arr
}
; 从数组中删除第一个元素，并返回该元素的值。此方法更改数组的长度。
Array_Shift(this) => this.RemoveAt(1)

Array_Max(this) {
    if !this.Length
        return
    ans := this[1]
    for v in this
        ans := Max(v, ans)
    return ans
}
Array_Min(this) {
    if !this.Length
        return
    ans := this[1]
    for v in this
        ans := Min(v, ans)
    return ans
}

_deepEquals(this, other) {
    if this.Length != other.Length {
        return false
    }
}

; 包左包右
Array_Slice(arr, start := 0, end := arr.length) {

    if (start < 0) {
        start := arr.length + start + 1
    }
    if (end < 0) {
        end := arr.length + end + 1
    }

    ; 如果 start 或 end 超过了数组长度
    start := max(start, 1)
    end := min(end, arr.length)

    ; 返回数组的切片部分
    slicedArray := []

    i := start
    while i <= end
        slicedArray.push(arr[i]), i++

    return slicedArray
}

Array_Splice(arr, start, deleteCount, itemsToAdd*) {
    ; 处理 start 位置如果为负数的情况
    if (start < 0) {
        start := arr.length + start + 1
    }

    ; 如果 start 超出了数组范围
    if (start > arr.length) {
        start := arr.length
    }

    ; 删除部分的元素（从 start 开始的 deleteCount 个元素）
    deletedItems := arr.slice(start, start + deleteCount - 1)
    restItems := arr.slice(start + deleteCount)
    ; 从数组中删除元素
    arr.length := start - 1
    ; 添加新的元素
    arr.push(itemsToAdd*)
    ; 添加原数组剩下的部分
    arr.push(restItems*)
    ; 返回被删除的元素
    return deletedItems
}

DefProp := {}.DefineProp
DefProp("".base, "at", { call: String_At })
DefProp("".base, "charAt", { call: String_CharAt })
DefProp("".base, "charCodeAt", { call: String_CharCodeAt })
DefProp("".base, "toCharArray", { call: StrSplit })
DefProp("".base, "concat", { call: String_Concat })
DefProp("".base, "startsWith", { call: String_StartsWith })
DefProp("".base, "endsWith", { call: String_EndsWith })
DefProp("".base, "repeat", { call: String_Repeat })
DefProp("".base, "replace", { call: (this, str, rt) => StrReplace(this, str, rt, true, , 1) })
DefProp("".base, "replaceAll", { call: (this, str, rt) => StrReplace(this, str, rt, true) })
DefProp("".base, "trim", { call: Trim })
DefProp("".base, "trimEnd", { call: RTrim })
DefProp("".base, "trimRight", { call: RTrim })
DefProp("".base, "trimStart", { call: LTrim })
DefProp("".base, "trimLeft", { call: LTrim })
DefProp("".base, "toLowerCase", { call: StrLower })
DefProp("".base, "toUpperCase", { call: StrUpper })
DefProp("".base, "toTitleCase", { call: StrTitle })
DefProp("".base, "split", { call: StrSplit })
DefProp("".base, "subString", { call: String_SubStr })
DefProp("".base, "length", { get: StrLen })
DefProp("".base, "padStart", { call: String_PadStart })
DefProp("".base, "padEnd", { call: String_PadEnd })
DefProp("".base, "count", { call: String_CharCount })
DefProp("".base, "__item", { get: String__item })
DefProp("".base, "__Enum", { call: String__Enum })
DefProp("".base, "match", { call: String_Match })
DefProp("".base, "indexOf", { call: String_IndexOf })
DefProp("".base, "slice", { call: String_Slice })

String_Match(this, regex) {
    RegExMatch(this, regex, &m)
    res := [m[0]]
    res.index := m.Pos
    res.input := this
    return res
}

String_IndexOf(this, regex) {
    return this ~= regex
}

String_Slice(this, start, end?) {
    strLen := this.Length

    if (start < 0) {
        start := strLen + start + 1
    }
    if (end < 0) {
        end := strLen + end + 1
    }

    return SubStr(this, start, end - start)
}

String__Enum(this, paramCnt) => this.toCharArray().__Enum()

String__item(this, index) => this.CharAt(index)

String_At(this, index) => this.toCharArray()[index]

String_CharAt(this, index) {
    charArr := StrSplit(this)
    return index > 0 ? charArr[index] : charArr[charArr.Length + index + 1]
}

String_CharCodeAt(this, index) {
    char := this.CharAt(index)
    return Ord(char)
}

String_Concat(this, str*) {
    r := this
    for v in str {
        r .= v
    }
    return r
}

String_StartsWith(this, searchString, caseSense := false) {
    flag := caseSense ? '' : 'i)'
    return this ~= flag '^' searchString
}

String_EndsWith(this, searchString, endPostion?) {
    sl := searchString.Length
    if IsSet(endPostion) {
        if sl < endPostion {
            target := SubStr(this, endPostion - sl + 1, sl)
            if target = searchString
                return true
        }
        return false
    } else {
        return searchString = SubStr(this, this.Length - sl + 1)
    }
}

String_SubStr(this, startPos, length?) {
    if IsSet(length) && length > startPos
        length := length - startPos
    return SubStr(this, startpos, length?)
}

String_Repeat(this, count) {
    if count < 0
        throw Error('RangeError')
    else if count = 0
        return ''
    else if count = 1
        return this
    count := Floor(count)
    loop count {
        r .= this
    }
    return r
}

String_PadStart(this, len, str) {
    if this.Length >= len
        return this
    len := len >> 0, l := len - this.length, str := str.Length ? str : '0'
    if (l > str.length)
        str .= str.repeat(l / str.length)
    return (SubStr(str, 1, l) this)
}

String_PadEnd(this, len, str) {
    if this.Length >= len
        return this
    len := len >> 0, l := len - this.length, str := str.Length ? str : '0'
    if (l > str.length)
        str .= str.repeat(l / str.length)
    return (this SubStr(str, 1, l))
}

String_CharCount(this, ch) {
    _c := 0
    for v in StrSplit(this)
        if v = ch
            _c++
    return _c
}