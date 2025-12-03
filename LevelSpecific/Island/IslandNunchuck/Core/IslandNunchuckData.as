struct FIslandNunchuckPercentageOrValueData
{
	// If the 'Value' should represent actual value of a percentage
	UPROPERTY(Category = "Value")
	bool bValueIsPercentage = false;

	// < 0; unused
	UPROPERTY(Category = "Value")
	float Value = -1;

	FIslandNunchuckPercentageOrValueData(float InValue = -1, bool bIsPercentage = false)
	{
		bValueIsPercentage = bIsPercentage;
		Value = InValue;
	}

	float GetFinalizedValue(float DefaultValue) const
	{
		if(Value < 0)
			return DefaultValue;

		if(!bValueIsPercentage)
			return Value;

		return DefaultValue * Value;
	}
}

struct FIslandNunchuckAnimationData
{
	// The move length
	// -1, uses the animation total length, else, the give value is used, controlling the animation instead
	UPROPERTY(Category = "Settings")
	private float PlayLength = -1;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData PlayerAnimation;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData WeaponAnimation;

	float GetPlayRateToReachExpectedAnimationLength() const
	{
		if(PlayLength >= 0)
			return PlayerAnimation.GetPlayRateToReachExpectedAnimationLength(PlayLength);
		else
			return 1;
	}

	float GetMovePlayLength() const
	{
		if(PlayLength >= 0)
			return PlayLength;

		if(PlayerAnimation.Sequence != nullptr)
			return PlayerAnimation.Sequence.SequenceLength;

		return -1;
	}

	bool IsValidForPlayer() const
	{
		if(GetMovePlayLength() <= 0)
			return false;

		if(PlayerAnimation.Sequence == nullptr)
			return false;

		return true;
	}

	bool IsValidForPlayerAndWeapon() const
	{
		if(GetMovePlayLength() <= 0)
			return false;
		
		if(PlayerAnimation.Sequence == nullptr)
			return false;

		if(WeaponAnimation.Sequence == nullptr)
			return false;

		return true;
	}
}

struct FIslandNunchuckAnimationWithSettleData
{
	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
	FIslandNunchuckAnimationData Move;

	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
	FIslandNunchuckAnimationData Settle;
}