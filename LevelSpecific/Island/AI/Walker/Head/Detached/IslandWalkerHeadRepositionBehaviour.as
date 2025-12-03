class UIslandWalkerHeadRepositionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandWalkerHeadComponent HeadComp;
	AIslandWalkerArenaLimits Arena;
	UIslandWalkerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (Arena == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > 5.0)
			return true;
		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// It will look very ugly to have player on top of walker head in this behaviour, so throw them off even though there is no anim
		HeadComp.ThrowOffNonInteractingPlayers();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(2.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Dest = Arena.ActorLocation + FVector(0.0, 0.0, Settings.FireSwoopHeight + 400.0);
		if (!Owner.ActorLocation.IsWithinDist(Dest, 500.0))
			DestinationComp.MoveTowardsIgnorePathfinding(Dest, 3000.0);
	}
}