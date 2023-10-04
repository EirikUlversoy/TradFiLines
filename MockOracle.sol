

contract MockOracle {

    uint80 public mockRoundId = 18446744073709551927;
    int256 public mockAnswer = 28723218970000000000;
    uint256 public mockStartedAt = 1692072551;
    uint256 public mockUpdatedAt = 1692072551;
    uint80 public mockAnsweredInRound = 18446744073709551927;

    function insertUpdatedData(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) external {
        mockRoundId = roundId;
        mockAnswer = answer;
        mockStartedAt = startedAt;
        mockUpdatedAt = updatedAt;
        mockAnsweredInRound = answeredInRound;
    }
    constructor() {}
    function latestRoundData()
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        )
    {
        roundId = mockRoundId;
        answer = mockAnswer;
        startedAt = mockStartedAt;
        updatedAt = mockUpdatedAt;
        answeredInRound = mockAnsweredInRound;
    }
}