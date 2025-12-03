struct FDragonSwordCombatAnimData
{
	UDragonSwordCombatUserComponent CombatComp;

	// Attack
	uint LastAttackFrame = 0;
	uint LastAttackEndFrame = 0;
	FDragonSwordCombatAttackTypeData AttackTypeData;
	float AttackDuration = 0.0;
	int AttackIndex = 0;
	int SequenceIndex = 0;

	bool WasAttackStarted() const
	{
		return (LastAttackFrame == Time::FrameNumber);
	}

	bool IsGroundAttack() const
	{
		if (!AttackTypeData.IsValid())
			return false;

		return AttackTypeData.GetMovementType() == EDragonSwordAttackMovementType::Ground;
	}

	bool IsChargeAttack() const
	{
		if (!AttackTypeData.IsValid())
			return false;

		return AttackTypeData.GetMovementType() == EDragonSwordAttackMovementType::Charge;
	}

	bool IsAirAttack() const
	{
		if (!AttackTypeData.IsValid())
			return false;

		return AttackTypeData.GetMovementType() == EDragonSwordAttackMovementType::Air;
	}

	bool IsSprintAttack() const
	{
		if (!AttackTypeData.IsValid())
			return false;

		return AttackTypeData.GetMovementType() == EDragonSwordAttackMovementType::Sprint;
	}

	bool IsDashAttack() const
	{
		if (!AttackTypeData.IsValid())
			return false;

		return AttackTypeData.GetMovementType() == EDragonSwordAttackMovementType::Dash;
	}


	bool AttackIsRightHand() const
	{
		return (AttackIndex % 2) == 0;
	}

	// // Rush

	// bool WasRushStarted() const
	// {
	// 	return RushStartFrame == Time::FrameNumber;
	// }

	// // Recoil

	// bool RecoiledThisFrame() const
	// {
	// 	return (LastRecoilFrame == Time::FrameNumber);
	// }
}