class USlidingDiscAutoDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASlidingDisc SlidingDisc;

	bool bHasKilled = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlidingDisc = Cast<ASlidingDisc>(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;

		if(!SlidingDisc.bIsSliding)
			return false;

		if (SlidingDisc.ActorVelocity.Size() > 500.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SlidingDisc.bIsSliding)
			return true;

		if (SlidingDisc.ActorVelocity.Size() > 500.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasKilled = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > 3.0)
		{
			if (!bHasKilled)
			{
				bHasKilled = true;
				CrumbKill();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbKill()
	{
		for (auto Player : Game::Players)
			Player.KillPlayer();
	}
};