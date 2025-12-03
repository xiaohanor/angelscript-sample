class USummitCrystalChaserTargetingBehaviour : UBasicBehaviour
{
	AHazePlayerCharacter DragonRider;
	USummitCrystalSkullSettings FlyerSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		DragonRider = Game::Mio;
		Owner.SetActorControlSide(DragonRider);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TargetComp.HasValidTarget())
			return false;

		// Start attacking as soon as either player is in range
		if (!Game::Mio.ActorLocation.IsWithinDist(Owner.ActorLocation, FlyerSettings.TargetingRange) &&
			!Game::Zoe.ActorLocation.IsWithinDist(Owner.ActorLocation, FlyerSettings.TargetingRange))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TargetComp.SetTarget(DragonRider);
		DeactivateBehaviour();
	}
}

