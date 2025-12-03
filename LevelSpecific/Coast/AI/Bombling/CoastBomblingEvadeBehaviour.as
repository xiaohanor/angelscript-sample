class UCoastBomblingEvadeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAICharacterMovementComponent MoveComp;

	bool bWait;
	float Radius;
	const float OverlapInterval = 0.2;
	float OverlapTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
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
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move away from target until at proper distance or duration is up
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector AwayFromTarget = (OwnLoc - TargetLoc);
		AwayFromTarget.Z = 0; // Don't try to dig a hole!
		FVector AwayLoc = OwnLoc + AwayFromTarget.GetSafeNormal() * (DestinationComp.MinMoveDistance + 80.0);
		
		DestinationComp.MoveTowardsIgnorePathfinding(AwayLoc, BasicSettings.EvadeMoveSpeed);
		DestinationComp.RotateTowards(TargetComp.Target);

		if(DoStop(AwayLoc))
			Cooldown.Set(2.0);
	}

	private bool DoStop(FVector Dest)
	{
		if(DestinationComp.MoveFailed())
			return true;

		if(Time::GetGameTimeSince(OverlapTime) > OverlapInterval)
		{
			OverlapTime = Time::GetGameTimeSeconds();
			auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseSphereShape(Radius);
			FVector OverlapLocation = Dest;
			FOverlapResultArray Result = Trace.QueryOverlaps(OverlapLocation);
			bWait = !Result.HasBlockHit();
			// Debug::DrawDebugSphere(OverlapLocation, LineColor = FLinearColor::Red, Duration = OverlapInterval);
			// Debug::DrawDebugSphere(OverlapLocation, Duration = OverlapInterval);
		}

		if(bWait)
			return true;
		
		return false;
	}
}