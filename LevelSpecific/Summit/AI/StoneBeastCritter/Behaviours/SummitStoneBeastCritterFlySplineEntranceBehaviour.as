class USummitStoneBeastCritterFlySplineEntranceBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeActorRespawnableComponent RespawnComp;
	UHazeSplineComponent EntrySpline;

	USummitStoneBeastCritterSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		Settings = USummitStoneBeastCritterSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		EntrySpline = RespawnComp.SpawnParameters.Spline;
		if (EntrySpline != nullptr)
			Owner.TeleportActor(EntrySpline.GetWorldLocationAtSplineDistance(0.0), EntrySpline.GetWorldRotationAtSplineDistance(0.0).Rotator(), this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (EntrySpline == nullptr)
			return false;
		if (Settings.bUseCrawlSplineEntrance)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (EntrySpline == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagCrystalCrawler::Locomotion, SummitCrystalCrawlerSubTags::CombatRevealMh, EBasicBehaviourPriority::Medium, this);

		// Manager SoundDef lives on Mio
		USummitStoneBeastCritterAttackManagerEventHandler::Trigger_OnStartFlyingSpawn(Game::Mio, FOnStoneCritterSpawnParams(EntrySpline.GetWorldLocationAtSplineFraction(1.0)));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		EntrySpline = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float FallSpeed = 1500 + ActiveDuration * 2000;
		DestinationComp.MoveAlongSpline(EntrySpline, FallSpeed);
		Owner.SetActorRotation(DestinationComp.FollowSplinePosition.WorldRotation);
		Owner.AddActorLocalRotation(FRotator(90, 0, 0)); // Animation pose is rotated, this makes spline's forward vector become mesh's downwards direction.
		if (DestinationComp.IsAtSplineEnd(EntrySpline, BasicSettings.SplineEntranceCompletionRange))
		{
			DeactivateBehaviour();				
		}
	}
}
