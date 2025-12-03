class UTundraFloatingPoleClimbTargetable : UTargetableComponent
{
	default TargetableCategory = ActionNames::Interaction;

	UPROPERTY()
	float TargetableRange = 500.0;

	UPROPERTY()
	float VisibleRange = 2000.0;

	ATundraFloatingPoleClimbActor FloatingPole;

	
	bool bDoTrace = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		FloatingPole = Cast<ATundraFloatingPoleClimbActor>(Owner);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(FloatingPole.Collision.WorldLocation.Distance(Query.PlayerLocation) > FloatingPole.CableMaxLengthUntilReleasing)
			return false;

		Targetable::ApplyTargetableRange(Query, TargetableRange);
		Targetable::ApplyVisibleRange(Query, VisibleRange);
		
		if(bDoTrace)
		{
			Targetable::RequirePlayerCanReachUnblocked(Query);
		}

		TListedActors<ATundraFloatingPoleClimbBlockingVolume> ListedBlockingVolumes;
		for(int i = 0; i < ListedBlockingVolumes.Num(); i++)
		{
			ATundraFloatingPoleClimbBlockingVolume BlockingVolume = ListedBlockingVolumes.Array[i];
			FHazeTraceSettings Trace = Trace::InitAgainstComponent(BlockingVolume.BrushComponent);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceComponent(Query.PlayerLocation, WorldLocation);
			if(Hit.bBlockingHit)
				return false;
		}

		return true;
	}
}