class URubyKnightDoubleInteractSinkOnCompleteCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ARubyKnightDoubleInteract DoubleInteract;

	bool bDeactivate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DoubleInteract = Cast<ARubyKnightDoubleInteract>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DoubleInteract.bComplete)
			return false;

		if (bDeactivate)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bDeactivate)
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
		DoubleInteract.OnDoubleInteractCompleted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / DoubleInteract.DownOnCompleteDuration);
		DoubleInteract.ActorLocation = Math::Lerp(DoubleInteract.StartLocation, DoubleInteract.TargetOnCompleteLocation, DoubleInteract.CompleteCurve.GetFloatValue(Alpha));
	
		if (Alpha >= 1.0)
			bDeactivate = true;
	}
};