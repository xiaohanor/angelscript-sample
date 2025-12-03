class UPrisonGuardIdleBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UPrisonGuardAnimationComponent GuardAnimComp;
	UHazeTeam Team;
	float ReactionTime;
	float DoneTime;
	bool bMove;
	FVector Destination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GuardAnimComp = UPrisonGuardAnimationComponent::Get(Owner);
		Team = UPrisonGuardComponent::Get(Owner).JoinTeam();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > DoneTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		ReactionTime = Math::RandRange(0.4, 1.5);

		float Dist = Math::RandRange(100.0, 400.0);
		FVector2D Dir2D = Math::RandPointInCircle(Dist);
		Destination = Owner.ActorLocation + FVector(Dir2D.X, Dir2D.Y, 0.0);
		bMove = Math::RandRange(0.0, 1.0) < 0.75;
		if (bMove)
		{
			// Walk somewhere if there's room
			FVector ToDest = Destination - Owner.ActorLocation;
			FVector Center = (Owner.ActorLocation + Destination) * 0.5;
			for (AHazeActor Coworker : Team.GetMembers())
			{
				if (Coworker == Owner)
					continue; // Myself
				if (!Coworker.ActorLocation.IsWithinDist(Center, Dist + 100.0))
					continue; // Far away		
				if (ToDest.DotProduct(Coworker.ActorLocation - Owner.ActorLocation) < 0.0)
					continue; // Behind
				FVector LineLoc;
				float Dummy;
				Math::ProjectPositionOnLineSegment(Owner.ActorLocation, Destination, Coworker.ActorLocation, LineLoc, Dummy);
				if (!LineLoc.IsWithinDist(Coworker.ActorLocation, 60.0))
					continue;
				// Co-worker is in the way, turn in place instead
				bMove = false;
			}
		}

		DoneTime = Math::RandRange(1.0, 2.0) + ReactionTime;
		if (bMove)
			DoneTime += 2.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Math::RandRange(0.8, 2.0));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < ReactionTime)
			return;

		if (bMove)
		{
			if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, 40.0))
				DestinationComp.MoveTowards(Destination, 400.0);
		}
		else
		{
			DestinationComp.RotateTowards(Destination);
		}
	}
}
