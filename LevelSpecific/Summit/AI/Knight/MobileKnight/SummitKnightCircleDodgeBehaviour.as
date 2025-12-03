class USummitKnightCircleDodgeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitKnightComponent KnightComp;
	USummitKnightMobileCrystalBottom CrystalBottom;
	USummitKnightSettings Settings;

	FHazeAcceleratedFloat AccSpeed;
	float CirclingDistance;
	float CircleDir = 1.0;

	AHazePlayerCharacter TailDragonRider;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnightComp = USummitKnightComponent::Get(Owner);
		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (KnightComp.NumberOfSwoops < Settings.CircleDodgeAfterNumSwoops)
			return false;
		if (Time::GetGameTimeSince(KnightComp.LastSwoopEndTime) > Settings.CircleDodgeAfterSwoopTime)
			return false;
		if (!Game::Zoe.ActorLocation.IsWithinDist2D(Owner.ActorLocation, Settings.CircleDodgeRange))
			return false;
		if (!KnightComp.bCanDodge.Get())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.CircleDodgeDuration)
			return true;
		if (!KnightComp.bCanDodge.Get())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TailDragonRider = Game::Zoe;
		FVector TailAim = KnightComp.Arena.GetClampedToArena(TailDragonRider.ActorLocation + TailDragonRider.ViewRotation.ForwardVector * 1000.0);
		FVector ToCenter = (KnightComp.Arena.Center - Owner.ActorLocation).GetSafeNormal2D();
		if (ToCenter.IsNearlyZero(1.0))
			ToCenter = -Owner.ActorForwardVector;
		FVector CircleSide = ToCenter.CrossProduct(FVector::UpVector) * 10.0;
		CircleDir = 1.0;
		if (TailAim.DistSquared2D(Owner.ActorLocation + CircleSide) > TailAim.DistSquared2D(Owner.ActorLocation - CircleSide))
			CircleDir = -1.0;
		AccSpeed.SnapTo(0.0);
		KnightComp.bCanBeStunned.Apply(false, this);
		CrystalBottom.Retract(this);
		
		CirclingDistance = KnightComp.Arena.Radius - Settings.CircleDodgeInsideRadius;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		KnightComp.bCanBeStunned.Clear(this);
		CrystalBottom.Deploy(this);
		Cooldown.Set(Settings.CircleDodgeCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TailDragonRider);

		if (ActiveDuration > Settings.CircleDodgeDuration * 0.8)
			return; // Stop

		AccSpeed.AccelerateTo(Settings.CircleDodgeSpeed, Settings.CircleDodgeDuration * 0.5, DeltaTime);
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

