// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Raffle Contract
 * @author Arush Singh
 * @notice This contract is for creating a raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {

    /* =============== TYPE DECLERATIONS ============== */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
  

    /* ================ STATE VARIABLES =============== */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;  // How many confirmations the Chainlink node should wait. longer wait => more secure random value
    uint32 private constant NUM_WORDS = 1;  // Number of random words we want
    uint256 private immutable I_INTERVAL;   // Duration of the lottery draw in seconds 
    bytes32 private immutable I_KEY_HASH;   // The maximum gas price you are willing to pay for a request in wei
    uint256 private immutable I_SUBSCRIPTION_ID;    // The Chainlink Subscription ID that this contract uses for funding requests
    uint32 private immutable I_CALLBACK_GAS_LIMIT;  // The limit for how much gas to use for the callback request to your contract's `fulfillRandomWords` function 
    uint256 private immutable I_ENTRANCE_FEE;
    address payable[] private sParticipants;
    uint256 private sLastTimeStamp;
    address private sRecentWinner;
    RaffleState private sRaffleState;
    

    /* ==================== EVENTS ==================== */
    event RaffleEntered(address indexed participant);
    event WinnerPicked(address indexed winner);


    /* ==================== ERRORS ==================== */
    error Raffle__NotEnoughETH();
    error Raffle__PayoutFailed();
    error Raffle__RaffleClosed();


    /* ================= CONSTRUCTORS ================= */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;
        I_KEY_HASH = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;

        sLastTimeStamp = block.timestamp;
        sRaffleState = RaffleState.OPEN;
    }


    /* =================== FUNCTIONS ================== */

    /* -------------- External Functions -------------- */

    /**
     * @notice Function to pick a random winner from the participants
     * @dev get's a random number using Chainlink VRFv2.5
     * @dev Prvents new people from entering the raffle before the calculation finishes and a winner is picked -
     * @dev - by switching RaffleState to Calculating (opens after `fulfillRandomWords` function is called by VRF)
     */
    function pickWinner() external {

        if ((block.timestamp - sLastTimeStamp) < I_INTERVAL) {
            revert();
        }

        sRaffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: I_KEY_HASH,
            subId: I_SUBSCRIPTION_ID,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: I_CALLBACK_GAS_LIMIT,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }


    /* --------------- Public Functions --------------- */

    /**
     * @notice Function to enter the Raffle Contest with necessary security checks
     * @dev Checks if amount paid is more or enough as the required fee and then pushes into s_participants array
     */
    function enterRaffle() public payable {
        if (msg.value < I_ENTRANCE_FEE) {
            revert Raffle__NotEnoughETH();
        }
        if (sRaffleState != RaffleState.OPEN) {
            revert Raffle__RaffleClosed();
        }

        sParticipants.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @notice Getter function
     */
    function getEntranceFee() public view returns (uint256) {
        return I_ENTRANCE_FEE;
    }


    /* -------------- Internal Functions -------------- */

    /** 
     * @notice Slices out a random winner from the participants list
     * @dev Overrides the `fulfillRandomWords` function from the `VRFConsumerBaseV2Plus` contract
     * @dev THIS FUNCTION RUNS IS CALLED BY `VRFConsumerBaseV2Plus` CONTRACT ITSELF
     * @dev - Raffle opens again for new participants to enter (closed in `pickWinner` function)
     * @dev - Resets the participants array for fresh new contest
     * @dev - Resets the timestamp for next contest
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % sParticipants.length;
        address payable recentWinner = sParticipants[indexOfWinner];
        sRecentWinner = recentWinner;
        sRaffleState = RaffleState.OPEN;
        sParticipants = new address payable[](0);
        sLastTimeStamp = block.timestamp;
        emit WinnerPicked(sRecentWinner);

        (bool sucess, ) = recentWinner.call{ value: address(this).balance }("");
        if (!sucess) {
            revert Raffle__PayoutFailed();
        }
    }

}