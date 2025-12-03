class USummitStoneBeastCritterFlySplineEntranceLandingBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeActorRespawnableComponent RespawnComp;

	bool bHasFinishedLanding = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
	}

	UFUNCTION()
	private void Reset()
	{
		bHasFinishedLanding = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bHasFinishedLanding)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > 1.5)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagCrystalCrawler::Locomotion, SummitCrystalCrawlerSubTags::CombatRevealEnter, EBasicBehaviourPriority::Medium, this);
		bHasFinishedLanding = true;	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);
		bHasFinishedLanding = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Owner.SetActorRelativeRotation(FRotator(0, 0, 0)); // Resets relative location set for entrance spline entry
	}

}
