
class UCoastBomblingStrafeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAICharacterMovementComponent MoveComp;

	bool bStrafeLeft = false;
	bool bTriedBothDirections = false;
	float Radius;
	ACoastTrainCart TrainCart;
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
		if (Super::ShouldDeactivate() == true)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bStrafeLeft = Math::RandBool();
		bTriedBothDirections = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc);
		Side = Side.GetClampedToSize(DestinationComp.MinMoveDistance, DestinationComp.MinMoveDistance + 80.0);
		if (bStrafeLeft)
			Side *= -1.0;
		float CircleDist = OwnLoc.Distance(TargetLoc);
		FVector CircleOffset = (OwnLoc + Side - TargetLoc).GetClampedToMaxSize(CircleDist);
		FVector StrafeDest = TargetLoc + CircleOffset;
		DestinationComp.MoveTowardsIgnorePathfinding(StrafeDest, BasicSettings.CircleStrafeSpeed);

		DestinationComp.RotateTowards(TargetComp.Target);
		
		if (DoChangeDirection(TargetLoc + CircleOffset))
		{
			if (bTriedBothDirections)
				Cooldown.Set(2.0); // Stuck, try again in a while
			bStrafeLeft = !bStrafeLeft;
			bTriedBothDirections = true;
		}
	}
	
	private bool DoChangeDirection(FVector StrafeDest)
	{
		if(DestinationComp.MoveFailed())
			return true;

		if(MoveComp.HasWallContact())
			return true;

		if(Time::GetGameTimeSince(OverlapTime) > OverlapInterval)
		{
			OverlapTime = Time::GetGameTimeSeconds();
			auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseSphereShape(Radius);
			FVector OverlapLocation = StrafeDest;
			FOverlapResultArray Result = Trace.QueryOverlaps(OverlapLocation);
			if(!Result.HasBlockHit())
			{
				// Debug::DrawDebugSphere(OverlapLocation, LineColor = FLinearColor::Red, Duration = OverlapInterval);
				return true;
			}
			// Debug::DrawDebugSphere(OverlapLocation, Duration = OverlapInterval);
		}
		
		return false;
	}
}