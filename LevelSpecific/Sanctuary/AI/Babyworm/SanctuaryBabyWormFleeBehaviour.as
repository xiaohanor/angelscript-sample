
class USanctuaryBabyWormFleeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	AAISanctuaryBabyWorm BabyWorm;
	USanctuaryBabyWormSettings Settings;
	UBasicAICharacterMovementComponent MoveComp;

	FVector ForcedDir;
	float ForcedDirTime;
	float ForcedDirDuration = 1;
	float TargetDistance = 200;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BabyWorm = Cast<AAISanctuaryBabyWorm>(Owner);
		Settings = USanctuaryBabyWormSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
	}

	private TArray<FVector> GetTailLocations() const
	{
		TArray<FVector> Locations = UPlayerCentipedeComponent::Get(Game::Mio).GetBodyLocations();
		return Locations;
	}

	private bool WithinRange() const
	{
		TArray<FVector> Locations;
		Locations.Add(Game::Mio.ActorLocation);
		Locations.Add(Game::Zoe.ActorLocation);
		for(FVector Location: GetTailLocations())
			Locations.Add(Location);

		for(FVector Location: Locations)
		{
			if(Owner.ActorLocation.IsWithinDist(Location, Settings.FleeRange))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WithinRange())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(!WithinRange())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ForcedDir = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MioDir = (Owner.ActorLocation - Game::Mio.ActorLocation);
		MioDir = MioDir * (1 / MioDir.Size());
		FVector ZoeDir = (Owner.ActorLocation - Game::Zoe.ActorLocation);
		ZoeDir = ZoeDir * (1 / ZoeDir.Size());
		FVector Dir = MioDir + ZoeDir;

		TArray<FVector> TailLocs = GetTailLocations();
		for(FVector TailLoc: TailLocs)
		{
			FVector TailDir = (Owner.ActorLocation - TailLoc);
			Dir += TailDir * (1 / TailDir.Size()) * 0.5;
		}
		Dir = Dir.GetSafeNormal2D();

		if(Time::GetGameTimeSince(ForcedDirTime) < ForcedDirDuration)
			Dir = (Dir + ForcedDir).GetSafeNormal2D();
		else
			ForcedDirTime = 0;
		FVector TargetLocation = Owner.ActorLocation + Dir * TargetDistance;

		if(ForcedDirTime == 0 && !CanMove(TargetLocation))
		{
			ForcedDirTime = Time::GetGameTimeSeconds();
			ForcedDir = Dir * -1.05;
		}

		DestinationComp.MoveTowards(TargetLocation, Settings.FleeMoveSpeed);
	}

	private bool CanMove(FVector Dest)
	{
		if(DestinationComp.MoveFailed())
			return false;

		FVector DestNavMesh;
		FVector PathDest = Dest + (Dest - Owner.ActorLocation).GetSafeNormal() * BabyWorm.CapsuleComponent.CapsuleRadius;
		if(!Pathfinding::FindNavmeshLocation(PathDest, 0.0, 100.0, DestNavMesh))
			return false;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, DestNavMesh))
			return false;

		return true;
	}
}