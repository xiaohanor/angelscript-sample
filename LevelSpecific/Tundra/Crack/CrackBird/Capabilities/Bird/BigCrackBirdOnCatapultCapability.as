class UBigCrackBirdOnCatapultCapability : UBigCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Bird.bIsPrimed)
			return false;

		if(!Bird.bAttached)
			return false;

		if(Bird.GetState() != ETundraCrackBirdState::InNest)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Bird.bAttached)
			return true;

		if(Bird.GetState() != ETundraCrackBirdState::InNest)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float CurrentCatapultRotationRad = Bird.CatapultToAttachTo.FauxAxisRotator.CurrentRotation;
		float CurrentCatapultVelocityRad = (CurrentCatapultRotationRad - Bird.OldCatapultRotationRad) / Time::GlobalWorldDeltaSeconds;
		Bird.OldCatapultRotationRad = CurrentCatapultRotationRad;

		// The catapult were on positive rotation angles and were headed towards negative and this frame it reached 0 or negative
		if(HasControl() && !Bird.bIsLaunched && Bird.CatapultToAttachTo.bJustSlammed && Bird.PreviousRotationOfCatapultRad > 0.0 && CurrentCatapultRotationRad <= 0.0 && CurrentCatapultVelocityRad < 0.0)
		{
			NetOnLaunch();
		}

		Bird.PreviousRotationOfCatapultRad = CurrentCatapultRotationRad;
	}

	UFUNCTION(NetFunction)
	private void NetOnLaunch()
	{
		Bird.bAttached = false;
		Bird.bIsLaunched = true;
	}
};