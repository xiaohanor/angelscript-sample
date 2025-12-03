struct FTargetableResult
{
	// Total scoring number for this targetable
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float Score = 1.0;

	// Whether it is possible for this to become the primary target, note that Score = 0 also implies not a possible target
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPossibleTarget = true;

	// Whether there should be any visuals for this targetable
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bVisible = true;

	// Arbitrary visual progress meter. Can mean different things for different targetables
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float VisualProgress = 1.0;

	// FilterScore is applied before Score, and all targetables whose FilterScore is lower than the highest FilterScore - FilterScoreThreshold are ignored
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float FilterScore = 0.0;

	// Threshold to use to ignore targets based on FilterScore
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float FilterScoreThreshold = 0.0;
};

enum EPlayerTargetingMode
{
	ThirdPerson,
	SideScroller,
	TopDown,
	MovingTowardsCamera,
};
