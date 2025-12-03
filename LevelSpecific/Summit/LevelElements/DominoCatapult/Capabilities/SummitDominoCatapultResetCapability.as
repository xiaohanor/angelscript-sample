class USummitDominoCatapultResetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitDominoCatapult Catapult;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Catapult = Cast<ASummitDominoCatapult>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		float TimeSinceLastFired = Time::GetGameTimeSince(Catapult.TimeLastFired);
		if(TimeSinceLastFired < Catapult.ResetDelay)
			return false;

		if(TimeSinceLastFired > Catapult.ResetDuration + Catapult.ResetDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Catapult.ResetDuration)
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
		Catapult.bIsPrimed = true;

		Catapult.CatapultRotatePivot.RelativeRotation = FQuat::Identity.Rotator();		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ResetAlpha = ActiveDuration / Catapult.ResetDuration;

		Catapult.CatapultRotatePivot.RelativeRotation = FQuat::Slerp(Catapult.FireTargetQuat, FQuat::Identity, ResetAlpha).Rotator();
	}
};