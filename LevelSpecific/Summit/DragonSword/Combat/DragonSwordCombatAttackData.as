struct FDragonSwordRecoilData
{
	float StartTimestamp = -1.0;
	float Duration = -1.0;
	FVector Direction = FVector::ZeroVector;

	float GetEndTimestamp() const property
	{
		return StartTimestamp + Duration;
	}
}

enum EDragonSwordAttackMovementType
{
	StillAttack,
	Ground,
	Air,
	Dash,
	Sprint,
	Charge
}

enum EDragonSwordCombatAttackDataType
{
	Invalid,
	Pending,
	Active,
	Previous
}

enum EDragonSwordCombatAttackDataHitType
{
	Swipe,
	Stab,
	Sphere
}

// The active (or pending) attacking state
// Used for selecting what Rush/Attack capability to run
struct FDragonSwordCombatAttackData
{
	EDragonSwordCombatAttackDataType AttackDataType;

	private bool bIsValid = false;
	private FDragonSwordCombatAttackTypeData AttackTypeData_Internal;
	private FDragonSwordCombatAttackAnimationData AnimationData_Internal;

	FDragonSwordCombatAttackData(FDragonSwordCombatAttackTypeData InAttackTypeData, FDragonSwordCombatAttackAnimationData InAnimationData)
	{
		if (!InAnimationData.IsValid())
			return;

		AttackTypeData_Internal = InAttackTypeData;
		AnimationData_Internal = InAnimationData;

		bIsValid = true;
	}

	bool IsValid() const
	{
		if (!bIsValid)
			return false;

		if (!AttackTypeData_Internal.IsValid())
			return false;

		if (!AnimationData_Internal.IsValid())
			return false;

		return true;
	}

	void Invalidate()
	{
		check(bIsValid);

		bIsValid = false;
	}

	FDragonSwordCombatAttackTypeData GetAttackTypeData() const property
	{
		check(IsValid());
		return AttackTypeData_Internal;
	}

	EDragonSwordCombatAttackType GetAttackType() const property
	{
		check(IsValid());
		return AttackTypeData_Internal.ToType();
	}

	FDragonSwordCombatAttackAnimationData GetAnimationData() const property
	{
		check(IsValid());
		return AnimationData_Internal;
	}
}