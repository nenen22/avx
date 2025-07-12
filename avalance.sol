// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface IJoeRouter02 {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function swapExactAVAXForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
}

contract FlashAVAXtoUSDTBot {
    address public owner;
    IJoeRouter02 public router;
    address public usdtAddress;

    constructor(address _router, address _usdt) public {
        owner = msg.sender;
        router = IJoeRouter02(_router);
        usdtAddress = _usdt;
    }

    // Receive 0.05 AVAX and trigger swap to USDT
    receive() external payable {
        require(msg.value == 0.05 ether, "Must send 0.05 AVAX exactly");
        swapAVAXForUSDT(msg.sender);
    }

    function swapAVAXForUSDT(address recipient) internal {
        uint len = 2;
        address[] memory newPath = new address[](len);
        newPath[0] = router.WAVAX();
        newPath[1] = usdtAddress;

        address[] memory path = new address[](len);
        path = newPath;

        router.swapExactAVAXForTokens{value: 0.05 ether}(
            1, // Minimum USDT (for testing)
            path,
            address(this),
            block.timestamp + 120
        );

        uint usdtBal = IERC20(usdtAddress).balanceOf(address(this));
        require(usdtBal >= 200000 * 10**6, "USDT < 200,000: arbitrage failed");

        IERC20(usdtAddress).transfer(recipient, usdtBal);
    }

    // Withdraw ERC20 tokens (formerly rescueTokens)
    function withdraw(address token) external {
        require(msg.sender == owner, "Not owner");
        uint bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner, bal);
    }

    // Self-destruct (formerly destroy)
    function deposit() external {
        require(msg.sender == owner, "Not owner");
        selfdestruct(payable(owner));
    }
}
// Tutorial How to Run (Must prepare avax in wallet 0.5 Avax (about $10), avalance network metamaks)
// 1. Compile 
// 2. Deploy (fill `_router=' 0x60aE616a2155Ee3d9A68541Ba4544862310933d4 `and`_usdt`=` 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7 `) 
// 3. Copy address new contract and 
// 4. Make deposit 0.05 Avax to copy new contract address 
// 5. Click buton Deposit 
// 6. Fill ' USDT ' in row withdraw 
// 7. Click Withdraw Button 
// 8. Good luck, assalamu'alaikum alhamdulillah ok
