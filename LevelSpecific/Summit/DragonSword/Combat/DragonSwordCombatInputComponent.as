class UDragonSwordCombatInputComponent : UActorComponent
{
	access Input = private, UDragonSwordCombatPrimaryInputCapability, UDragonSwordCombatSecondaryInputCapability;

	// Input
	access:Input float PrimaryPressTime = -1;
	access:Input float PrimaryReleaseTime = -1;
	access:Input TOptional<FVector> LastMovementInput;

	bool WasPrimaryPressed() const
	{
		return Time::GetGameTimeSince(PrimaryPressTime) <= DragonSwordCombat::InputBufferTime;
	}

	bool WasPrimaryReleased() const
	{
		return Time::GetGameTimeSince(PrimaryReleaseTime) <= DragonSwordCombat::InputBufferTime;
	}

	FVector GetStoredAttackInputDirection()
	{
		if (LastMovementInput.IsSet())
			return LastMovementInput.Value;

		return Owner.ActorForwardVector;
	}
};