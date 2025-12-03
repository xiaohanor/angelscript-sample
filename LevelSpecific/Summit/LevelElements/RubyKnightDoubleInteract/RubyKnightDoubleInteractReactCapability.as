class URubyKnightDoubleInteractReactCapability : UHazeCapability
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
		if (!DoubleInteract.bIsReacting)
			return false;
		
		if (DoubleInteract.bComplete)
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
		bDeactivate = false;
		URubyKnightDoubleInteractEventHandler::Trigger_OnReact(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DoubleInteract.bIsReacting = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / DoubleInteract.DownReactDuration);
		DoubleInteract.ActorLocation = Math::Lerp(DoubleInteract.StartLocation, DoubleInteract.TargetOnReactLocation, DoubleInteract.ReactCurve.GetFloatValue(Alpha));
		if (Alpha >= 1.0)
			bDeactivate = true;
	}
};