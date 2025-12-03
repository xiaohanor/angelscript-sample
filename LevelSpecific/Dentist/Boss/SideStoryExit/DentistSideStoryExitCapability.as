class UDentistSideStoryExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"DentistSideStoryExiting");

	default TickGroup = EHazeTickGroup::Gameplay;

	ADentistSideStoryExitActor ExitPortal;

	FHazeAcceleratedTransform AccPlayerTransform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		TListedActors<ADentistSideStoryExitActor> ListedActors;
		auto TempExitPortal = ListedActors.Single;
		if (TempExitPortal == nullptr)
		{
			return false;
		}
		if (TempExitPortal.bPlayerInRange[Player])
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<ADentistSideStoryExitActor> ListedActors;
		ExitPortal = ListedActors.Single;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		AccPlayerTransform.SnapTo(Player.ActorTransform, Player.ActorVelocity);

		Player.BlockCapabilities(CapabilityTags::Death, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccPlayerTransform.SpringTo(ExitPortal.ActorTransform, 20.0, 1.0, DeltaTime);
		Player.SetActorTransform(AccPlayerTransform.Value);
	}
};