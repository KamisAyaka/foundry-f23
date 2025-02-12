//0x6080604052348015600e575f80fd5b5060a58061001b5f395ff3fe6080604052348015600e575f80fd5b50600436106030575f3560e01c8063cdfead2e146034578063e026c017146045575b5f80fd5b6043603f3660046059565b5f55565b005b5f5460405190815260200160405180910390f35b5f602082840312156068575f80fd5b503591905056fea26469706673582212205175aaf855aa11cb07e2f92af07a31c0b0b87009a9a56a8d97df3b8e39c7353c64736f6c63430008140033

// 1.Contract Creation Code
// Free Memory Pointer
PUSH1 0x80 // [0x80]
PUSH1 0x40 // [0x40,0x80]
MSTORE  // 在0x40的memory中储存指向0x80的指针 []  // Memory 0x40 -> 0x80

// If someone sent value with this call, revert
// Otherwise, jump to the 0x0E JumpDest,continue exectuion
CALLVALUE       // [msg.value]
DUP1            // [msg.value,msg.value]
ISZERO          // [msg.value == 0,msg.value]
PUSH1 0x0e      // [0x0E,msg.value == 0,msg.value]
JUMPI           // [msg.value]
PUSH0           // [0x00,msg.value]
DUP1            // [0x00,0x00,msg.value]
REVERT          // [msg.value]

// Jump dest if msg.value == 0
// Sticks the runtime code to the blockchain
JUMPDEST        // [msg.value]
POP             // []
PUSH1 0xa5      // [0xa5]
DUP1            // [0xa5,0xa5]
PUSH2 0x001b    // [0x001b,0xa5,0xa5]
PUSH0           // [0x00,0x001b,0xa5,0xa5] 
//复制INVALID之后需要储存的代码到区块链上，储存到memory中.
//0x00指在memory上的偏移量，0x001b指的是从0x001b开始复制，长度为0xa5
CODECOPY        // [0xa5] Memory:[runtime code]
PUSH0           // [0x00, 0xa5]
RETURN          // []
INVALID         // []

// 2. Runtime Code
// Entry point of all calls
// Free Memory Pointer
PUSH1 0x80      // [0x80]
PUSH1 0x40      // [0x40,0x80]
MSTORE

// Checking for msg.value, and if given, revert
CALLVALUE       // [msg.value]
DUP1            // [msg.value,msg.value]
ISZERO          // [msg.value == 0,msg.value]
PUSH1 0x0e      // [0x0e,msg.value == 0,msg.value]
JUMPI           // [msg.value]
// Jump to "Continue"

PUSH0           // [0x00,msg.value]
DUP1            // [0x00,0x00,msg.value]
REVERT          // [msg.value]

// If msg.value == 0, jump to here JumpDest
// Continue
// This is checking to see if there is enough calldata for a function selector
JUMPDEST        // [msg.value]
POP             // []
PUSH1 0x04      // [0x04]
CALLDATASIZE    // [callDataSize,0x04]
LT              // < // [callDataSize < 0x04]
PUSH1 0x30      // [0x30,callDataSize < 0x04]
JUMPI           // []
// if calldata_size < 0x04 -> calldata_jump

// function dispatching in solidity
PUSH0           // [0x00]
CALLDATALOAD    // [calldata]
PUSH1 0xe0      // [0xe0,calldata]
SHR             // [calldata[0:4]] // function selector

// function dispatching for setNumberOfHorses
DUP1            // [function_selector,function_selector]
PUSH4 0xcdfead2e// [0xcdfead2e,function_selector,function_selector]
EQ              // [function_selector == 0xcdfead2e,function_selector]
PUSH1 0x34      // [0x34,function_selector == 0xcdfead2e,function_selector]
JUMPI           // [function_selector]
// if function_selector == 0xcdfead2e -> set_number_of_horses

// function dispatching for readNumberOfHorses
DUP1            // [function_selector,function_selector]
PUSH4 0xe026c017// [0xe026c017,function_selector,function_selector]
EQ              // [function_selector == 0xe026c017,function_selector]
PUSH1 0x45      // [0x45,function_selector == 0xe026c017,function_selector]
JUMPI           // [function_selector]
// if function_selector == 0xe026c017 -> get_number_of_horses
// else continue execution will revert

//calldata_jump
// Revert Jumpdest
JUMPDEST        //[]
PUSH0           //[0]
DUP1            //[0,0]
REVERT

// update number of horses jump dest 1
// Setup jumping program counters in the stack
JUMPDEST        // [function_selector]
PUSH1 0x43      // [0x43,function_selector]
PUSH1 0x3f      // [0x3f,0x43,function_selector]
CALLDATASIZE    // [callDataSize,0x3f,0x43,function_selector]
PUSH1 0x04      // [0x04,callDataSize,0x3f,0x43,function_selector]
PUSH1 0x59      // [0x59,0x04,callDataSize,0x3f,0x43,function_selector]
JUMP            // [0x04,callDataSize,0x3f,0x43,function_selector]

//update number of horses jump dest 4
// we can finally run an sstore to save our value to storage
// 1. Function dispatch
// 2. Checked for msg.value
// 3. Checked that calldata is long enough
// 4. Received the number to use from the calldata
JUMPDEST        // [calldata(of numberToUpdate),0x43,function_selector]
PUSH0           // [0x00,calldata(of numberToUpdate),0x43,function_selector]
SSTORE          // [0x43,function_selector]
JUMP            // [function_selector]
// Jump dest 5

// update number of horses jump dest 5
JUMPDEST        // [function_selector]
STOP            // []


// readNumberOfHorses jump dest 1
// the only jump dest
JUMPDEST        // [function_selector]
PUSH0           // [0x00,function_selector]
SLOAD           // [numHorses,function_selector]
PUSH1 0x40      // [0x40,numHorses,function_selector]
MLOAD           // [0x80,numHorses,function_selector] // Memory [0x40:0x80] (free memory pointer)
SWAP1           // [numHorses,0x80,function_selector]
DUP2            // [0x80,numHorses,0x80,function_selector]
MSTORE          // [0x80,function_selector] Memory: 0x80: numHorses
PUSH1 0x20      // [0x20,0x80,function_selector]
ADD             // [0x80 + 0x20 = 0xa0,function_selector]
PUSH1 0x40      // [0x40,0xa0,function_selector]
MLOAD           // [0x80,0xa0,function_selector]
DUP1            // [0x80,0x80,0xa0,function_selector]
SWAP2           // [0xa0,0x80,0x80,function_selector]
SUB             // [0xa0 - 0x80,0x80,function_selector]
SWAP1           // [0x80,0xa0 - 0x80,function_selector]
// Return a value of size 32 bytes, that's located at position 0x80 in memory
RETURN          // [function_selector]

// update number of horses jump dest 2
// Check to see if there is a value to update the horse number to
// 4 bytes for function selector, 32 bytes for horse number
JUMPDEST            // [0x04,callDataSize,0x3f,0x43,function_selector]
PUSH0               // [0x00,0x04,callDataSize,0x3f,0x43,function_selector]
PUSH1 0x20          // [0x20,0x00,0x04,callDataSize,0x3f,0x43,function_selector]
DUP3                // [0x04,0x20,0x00,0x04,callDataSize,0x3f,0x43,function_selector]
DUP5                // [callDataSize,0x04,0x20,0x00，0x04,callDataSize,0x3f,0x43,function_selector]
SUB                 // [callDataSize - 0x04, 0x20 , 0x00 ,0x04,callDataSize,0x3f,0x43,function_selector]
// is there more calldata than just the function selector?
// function selector + data (bytes32)
SLT                 // [callDataSize - 0x04 < 0x20,0x00,0x04,callDataSize,0x3f,0x43,function_selector]
ISZERO              // [callDataSize - 0x04 < 0x20 == true,0x00,0x04,callDataSize,0x3f,0x43,function_selector]
PUSH1 0x68          // [0x68,callDataSize - 0x04 < 0x20 == true,0x00,0x04,callDataSize,0x3f,0x43,function_selector]
JUMPI               // [0x00,0x04,callDataSize,0x3f,0x43,function_selector]
// We are going to jump to jump dest 3 if there is more calldata than just the function selector
// function selector + 0x20 bytes of data

// Revert if there is no enough calldata
PUSH0               // [0,0x00,0x04,callDataSize,0x3f,0x43,function_selector]
DUP1                // [0,0,0x00,0x04,callDataSize,0x3f,0x43,function_selector]
REVERT              // [0x00,0x04,callDataSize,0x3f,0x43,function_selector]

// update number of horses jump dest 3
// grab the calldata for updating the horse number
JUMPDEST            // [0x00,0x04,callDataSize,0x3f,0x43,function_selector]
POP                 // [0x04,callDataSize,0x3f,0x43,function_selector]
CALLDATALOAD        // [calldata(of numberToUpdate),callDataSize,0x3f,0x43,function_selector]
SWAP2               // [0x3f,callDataSize,calldata(of numberToUpdate),0x43,function_selector]
SWAP1               // [callDataSize,0x3f,calldata(of numberToUpdate),0x43,function_selector]
POP                 // [0x3f,calldata(of numberToUpdate),0x43,function_selector]
JUMP                // [calldata(of numberToUpdate),0x43,function_selector]
// jump to jump dest 4


// 3. Metadata
INVALID
LOG2
PUSH5 0x6970667358
INVALID
SLT
KECCAK256
MLOAD
PUSH22 0xaaf855aa11cb07e2f92af07a31c0b0b87009a9a56a8d
SWAP8
INVALID
EXTCODESIZE
DUP15
CODECOPY
INVALID
CALLDATALOAD
EXTCODECOPY
PUSH5 0x736f6c6343
STOP
ADDMOD
EQ
STOP
CALLER