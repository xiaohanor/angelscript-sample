struct FSummitSeeSawSwingStatueDeactivateSwingActivationParams
{
	bool bLeftSide = true;
}

class USummitSeeSawSwingStatueDeactivateSwingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitSeeSawSwingStatue Statue;

	bool bLeftSide = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Statue = Cast<ASummitSeeSawSwingStatue>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitSeeSawSwingStatueDeactivateSwingActivationParams& Params) const
	{
		if(Statue.CurrentRotationDegrees > Statue.DropSwingDegrees)
		{
			Params.bLeftSide = true;
			return true;
		}
		if(Statue.CurrentRotationDegrees < -Statue.DropSwingDegrees)
		{
			Params.bLeftSide = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bLeftSide)
		{
			if(Statue.CurrentRotationDegrees < Statue.ReEnableSwingsDegrees)
				return true;
		}
		else
		{
			if(Statue.CurrentRotationDegrees > -Statue.ReEnableSwingsDegrees)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitSeeSawSwingStatueDeactivateSwingActivationParams Params)
	{
		bLeftSide = Params.bLeftSide;
		if(bLeftSide)
			Statue.LeftSwingPointComp.Disable(this);
		else
			Statue.RightSwingPointComp.Disable(this);

		Statue.bSwingsDeactivated = true;
		Statue.bHasReEnabledRespawnAfterSwingsDeactivating = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bLeftSide)
			Statue.LeftSwingPointComp.Enable(this);
		else
			Statue.RightSwingPointComp.Enable(this);

		Statue.bSwingsDeactivated = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};