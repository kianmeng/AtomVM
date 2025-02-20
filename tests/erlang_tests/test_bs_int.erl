%
% This file is part of AtomVM.
%
% Copyright 2022 Fred Dushin <fred@dushin.net>
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% SPDX-License-Identifier: Apache-2.0 OR LGPL-2.1-or-later
%

-module(test_bs_int).

-export([start/0]).

start() ->
    Binaries = generate_binaries(10, 64, []),

    [test_bs_ints(Binaries, Size, Endianness, Signedness) ||
        Size <- [32, 16, 8],
        Endianness <- [big, little],
        Signedness <- [unsigned, signed]
    ],

    [test_bs_ints(Binaries, Size, Endianness, Signedness) ||
        Size <- [64],
        Endianness <- [big, little],
        Signedness <- [unsigned]
    ],

    0.


generate_binaries(0, _Size, Accum) ->
    Accum;
generate_binaries(I, Size, Accum) ->
    generate_binaries(I - 1, Size, [generate_binary(I, Size, []) | Accum]).

generate_binary(_I, 0, Accum) ->
    list_to_binary(Accum);
generate_binary(I, Size, Accum) ->
    %% semi-random numbers to ensure a distribution of values
    NextI = case I rem 2 of 0 -> I * 7; _ -> I rem 3 end,
    generate_binary(NextI, Size - 8, [I rem 256 | Accum]).


test_bs_ints(Binaries, Size, Endianness, Signedness) ->
    [test_bs_int(Binary, Size, Endianness, Signedness) || Binary <- Binaries].

test_bs_int(Binary, Size, Endianness, Signedness) ->
    IntValue = get_int_value(Binary, Size, Endianness, Signedness),
    ComputeValue = compute_value(Binary, Size, Endianness, Signedness),
    case IntValue of
        ComputeValue ->
            ByteSize = Size div 8,
            <<ChoppedBinary:ByteSize/binary, _/binary>> = Binary,
            PutBinary = put_int_value(IntValue, Size, Endianness, Signedness),
            case PutBinary of
                ChoppedBinary ->
                    {Binary, Size, Endianness, Signedness, IntValue, PutBinary};
                _ ->
                    throw({error_failed_put, [
                        {binary, Binary},
                        {size, Size},
                        {endianness, Endianness},
                        {signedness, Signedness},
                        {chopped_binary, ChoppedBinary},
                        {put_binary, PutBinary}
                    ]})
            end;
        _ ->
            throw({error_failed_get, [
                {binary, Binary},
                {size, Size},
                {endianness, Endianness},
                {signedness, Signedness},
                {int_value, IntValue},
                {compute_value, ComputeValue}
            ]})
    end.

get_int_value(Binary, Size, big, unsigned) ->
    <<Val:Size/integer-big-unsigned, _/binary>> = Binary,
    Val;
get_int_value(Binary, Size, big, signed) ->
    <<Val:Size/integer-big-signed, _/binary>> = Binary,
    Val;
get_int_value(Binary, Size, little, unsigned) ->
    <<Val:Size/integer-little-unsigned, _/binary>> = Binary,
    Val;
get_int_value(Binary, Size, little, signed) ->
    <<Val:Size/integer-little-signed, _/binary>> = Binary,
    Val.

put_int_value(Val, Size, big, unsigned) ->
    <<Val:Size/integer-big-unsigned>>;
put_int_value(Val, Size, big, signed) ->
    <<Val:Size/integer-big-signed>>;
put_int_value(Val, Size, little, unsigned) ->
    <<Val:Size/integer-little-unsigned>>;
put_int_value(Val, Size, little, signed) ->
    <<Val:Size/integer-little-signed>>.


compute_value(Bin, Size, Endianness, Signedness) when Size rem 8 =:= 0 ->
    Bytes = Size div 8,
    <<Data:Bytes/binary, _/binary>> = Bin,
    ByteList = binary_to_list(Data),
    NewByteList = case Endianness of
        big ->
            reverse(ByteList);
        little ->
            ByteList
    end,
    get_value(Signedness, accumulate(NewByteList, 0, 0), Size).

get_value(signed, Value, Size) ->
    %% https://en.wikipedia.org/wiki/Two%27s_complement#Converting_from_two's_complement_representation
    -1 * ho_bit(Value, Size) * raise_2(Size - 1) + lo_bits(Value, Size);
get_value(unsigned, Value, _Size) ->
    Value.

ho_bit(Value, Size) ->
    Value bsr (Size - 1).

raise_2(N) ->
    1 bsl N.

lo_bits(Value, Size) ->
    Value band ones(Size - 1).

ones(N) ->
    ones(N, 0).

ones(0, Accum) ->
    Accum bor 1;
ones(N, Accum) ->
    ones(N - 1, Accum bor (1 bsl (N-1))).

accumulate([], _I, Accum) ->
    Accum;
accumulate([H|T], I, Accum) ->
    %% NB. AtomVM treats H as a signed value, so we need to remove the signedness for this accumulator
    IntValue = case H < 0 of true -> (H band 16#7F) bor 16#80; _ -> H end,
    Addend = (IntValue bsl (I * 8)),
    accumulate(T, I + 1, Accum + Addend).

reverse(List) ->
    reverse(List, []).

reverse([], Accum) ->
    Accum;
reverse([H|T], Accum) ->
    reverse(T, [H|Accum]).
