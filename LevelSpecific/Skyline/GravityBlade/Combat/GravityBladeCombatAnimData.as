struct FGravityBladeCombatAnimData
{
	UGravityBladeCombatUserComponent CombatComp;

	// Attack
	uint LastAttackFrame = 0;
	uint LastAttackEndFrame = 0;
	EGravityBladeAttackMovementType MovementType;
	EGravityBladeAttackAnimationType AnimationType;
	float AttackDuration = 0.0;
	int AttackIndex = 0;
	int SequenceIndex = 0;

	// Rush
	uint RushStartFrame = 0;
	bool bIsRushing = false;
	float RushAlpha = 0;

	// Recoil
	uint LastRecoilFrame = 0;
	float RecoilDuration = 0.0;
	FVector RecoilDirection = FVector::ZeroVector;

	bool bFirstFrameHasRightFootForward = false;

	// Speed up
	float CurrentSpeedUpPlayRate = 1.0;
	float CurrentSpeedUpStartTime = 0.0;
	float CurrentSpeedUpRushSpeedMultiplier = 1.0;

	float AngleLeftToRotate;

	bool WasAttackStarted() const
	{
		return (LastAttackFrame == Time::FrameNumber);
	}

	/* Will be true from was attack started until the attack actually ends */
	bool IsAttacking() const
	{
		// New attack has started that hasn't ended
		if(LastAttackFrame > LastAttackEndFrame)
			return true;

		return false;
	}

	bool IsGroundAttack() const
	{
		return MovementType == EGravityBladeAttackMovementType::Ground;
	}

	bool IsAirAttack() const
	{
		return MovementType == EGravityBladeAttackMovementType::Air
			|| MovementType == EGravityBladeAttackMovementType::AirHover;
	}

	bool IsRushAttack() const
	{
		return MovementType == EGravityBladeAttackMovementType::GroundRush || MovementType == EGravityBladeAttackMovementType::AirRush;
	}

	bool AttackIsRightHand() const
	{
		return (AttackIndex % 2) == 0;
	}

	// Rush

	bool WasRushStarted() const
	{
		return RushStartFrame == Time::FrameNumber;
	}

	// Recoil

	bool RecoiledThisFrame() const
	{
		return (LastRecoilFrame == Time::FrameNumber);
	}
}