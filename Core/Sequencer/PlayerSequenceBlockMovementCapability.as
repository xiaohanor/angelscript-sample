class UPlayerSequenceBlockMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Sequencer");

	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		AHazeLevelSequenceActor SequenceActor = Player.GetActiveLevelSequenceActor();

		if (SequenceActor == nullptr)
			return false;

		if (Player.IsCapabilityTagBlocked(CapabilityTags::Movement) == false)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		AHazeLevelSequenceActor SequenceActor = Player.GetActiveLevelSequenceActor();

		if (SequenceActor == nullptr)
			return true;

		if (Player.IsCapabilityTagBlocked(CapabilityTags::Movement) == false)
			return true;
			
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.Mesh.ClearAllSubAnimationInstances();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.Mesh.ClearAllSubAnimationInstances();
		// TODO (JM): Only lerp in Z
		//Player.RootOffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.2, EInstigatePriority::Low);
		Player.ResetMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};