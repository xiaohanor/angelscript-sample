
// Move towards enemy
class UIslandDyadChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandDyadSettings DyadSettings;
	UIslandDyadLaserComponent LaserComp;
	FVector ChaseLocation;
	bool bUpdateLocation;
	float OffsetDistance;
	float OffsetDistanceMin = 1750;
	float OffsetDistanceMax = 2000;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
		DyadSettings = UIslandDyadSettings::GetSettings(Owner);
		LaserComp = UIslandDyadLaserComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (LaserComp.OtherDyad == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (LaserComp.OtherDyad == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bUpdateLocation = true;

		if(HasControl())
			OffsetDistance = Math::RandRange(OffsetDistanceMin, OffsetDistanceMax);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bUpdateLocation)
		{
			FVector TargetDir = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
			FVector DyadDir = (Owner.ActorLocation - LaserComp.OtherDyad.ActorLocation).GetSafeNormal2D();
			FVector Offset = DyadDir * OffsetDistance + TargetDir * OffsetDistance;
			FVector TargetLoc = TargetComp.Target.ActorLocation;
			TargetLoc.Z = Owner.ActorLocation.Z;
			ChaseLocation = TargetLoc + Offset;
		}

		if(bUpdateLocation)
		{
			bUpdateLocation = !Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, 2000);
		}

		if(!bUpdateLocation && Owner.ActorLocation.IsWithinDist(ChaseLocation, 100))
		{
			DeactivateBehaviour();
		}
		
		float Speed = Math::Clamp(Owner.ActorLocation.Distance(ChaseLocation) * 2, 125, 900);

		FVector MoveLocation = Owner.ActorLocation + (ChaseLocation - Owner.ActorLocation).GetSafeNormal2D() * 100;
		DestinationComp.MoveTowards(MoveLocation, Speed);

		if(!GetDest(MoveLocation))
			DeactivateBehaviour();
	}

	private bool GetDest(FVector& Dest)
	{
		FVector PathDest = Dest + (Dest - Owner.ActorLocation).GetSafeNormal() * Radius;
		if(!Pathfinding::FindNavmeshLocation(PathDest, 0.0, 200.0, Dest))
			return false;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, Dest))
			return false;

		return true;
	}
}