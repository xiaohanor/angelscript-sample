class UDanceShowdownThrowableMonkeyOnPillarCapability : UDanceShowdownThrowableMonkeyChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::OnPillar)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::OnPillar)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Monkey.PlaySlotAnimation(Monkey.LandAnim);
		Monkey.SetActorRelativeLocation(FVector::ZeroVector);
	}
};