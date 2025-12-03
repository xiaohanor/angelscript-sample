class USummitKnightCircleArenaBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitKnightComponent KnightComp;
	USummitKnightMobileCrystalBottom CrystalBottom;
	UBasicAIHealthComponent HealthComp;
	USummitKnightSettings Settings;

	FHazeAcceleratedFloat AccSpeed;
	float CirclingDistance;
	float CircleDir = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnightComp = USummitKnightComponent::Get(Owner);
		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		CircleDir *= -1.0;
		AccSpeed.SnapTo(0.0);
		KnightComp.bCanBeStunned.Apply(false, this);
		CrystalBottom.Retract(this);
		
		CirclingDistance = KnightComp.Arena.Radius + Settings.CirclingOutsideDistance;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		KnightComp.bCanBeStunned.Clear(this);
		HealthComp.ClearStunned();
		CrystalBottom.Deploy(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Face center of arena
		DestinationComp.RotateTowards(KnightComp.Arena.Center);

		AccSpeed.AccelerateTo(Settings.CirclingSpeed, 5.0, DeltaTime);
		FVector OwnLoc = Owner.ActorLocation;
		FVector ArenaCenter = KnightComp.Arena.Center;
		if (OwnLoc.IsWithinDist2D(ArenaCenter, 1.0))
			OwnLoc -= Owner.ActorForwardVector;
		FVector FromCenter = (OwnLoc - ArenaCenter).GetSafeNormal2D();
		if (Owner.ActorLocation.IsWithinDist2D(ArenaCenter, CirclingDistance * 0.5))
		{
			// Move out from arena center
			DestinationComp.MoveTowardsIgnorePathfinding(ArenaCenter + FromCenter * CirclingDistance, AccSpeed.Value);
		}
		else
		{
			// Circle around arena
			FVector CircleDest = ArenaCenter + (FromCenter * CirclingDistance).RotateAngleAxis(10.0 * CircleDir, FVector::UpVector);
			DestinationComp.MoveTowardsIgnorePathfinding(CircleDest, AccSpeed.Value);
		}
	}
}

