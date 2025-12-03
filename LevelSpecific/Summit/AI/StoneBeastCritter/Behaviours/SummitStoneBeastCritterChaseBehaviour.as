
// Move towards enemy
class USummitStoneBeastCritterChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAICharacterMovementComponent MoveComp;
	
	TArray<AHazeActor> ActorsToAvoid;
	// Use this instead of cooldown, since we don't really need to activate/deactivate 
	// this behaviour and want to minimize number of network messages 
	float PauseTime = 0.0;
	int CurrentTeamIndex = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.ChaseMinRange))
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
	void OnActivated()
	{
		Super::OnActivated();
		PauseTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PauseTime -= DeltaTime;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.ChaseMinRange))
		{
			if (PauseTime > 0)
				return;
		}
		else
		{
			PauseTime = 0.5;
		}

		FVector TargetLocation = TargetComp.Target.ActorLocation;		

		// Try to stay clear of any avoid points
		TListedActors<ASummitStoneBeastCritterAvoidScenepointActor> AvoidPoints;
		TArray<ASummitStoneBeastCritterAvoidScenepointActor> InfluencingAvoidPoints;
		
		// Check for points for which we are within radius of influence
		for (ASummitStoneBeastCritterAvoidScenepointActor AvoidPoint : AvoidPoints)
		{
			float Radius = AvoidPoint.GetScenepoint().Radius;
			if (Owner.ActorLocation.Dist2D(AvoidPoint.ActorLocation) < Radius)
			{
				InfluencingAvoidPoints.Add(AvoidPoint);
			}
		}
		
		// Find a new target location based on avoid points
		if (InfluencingAvoidPoints.Num() > 0)
		{
			FVector AdjustedTargetLocation = FVector::ZeroVector;
			for (ASummitStoneBeastCritterAvoidScenepointActor AvoidPoint : InfluencingAvoidPoints)
			{
				float Offset = AvoidPoint.GetScenepoint().Radius + 500;
				AdjustedTargetLocation += AvoidPoint.ActorLocation + AvoidPoint.ActorForwardVector * Offset;
				//Debug::DrawDebugSphere(AvoidPoint.ActorLocation, 10, 12, FLinearColor::Green);
				//Debug::DrawDebugArrow(AvoidPoint.ActorLocation, AvoidPoint.ActorLocation + AvoidPoint.ActorForwardVector * Offset, 5, FLinearColor::Red);
			}			
			AdjustedTargetLocation /= InfluencingAvoidPoints.Num(); // Average location
			
			// 
			FVector ToTargetLocation = (TargetLocation - Owner.ActorLocation).ConstrainToPlane(FVector::UpVector);

			// Heuristic offset the target location by aiming for the middle of the opposite side of the triangle.
			// Will still manage to fall off when multiple critters are avoiding each other.
			if (!Owner.ActorLocation.IsWithinDist2D(AdjustedTargetLocation, 100))
			{
				FVector ToAdjustedTargetLocationDir = (AdjustedTargetLocation - Owner.ActorLocation).GetSafeNormal2D();
				TargetLocation = Owner.ActorLocation + (ToTargetLocation + ToAdjustedTargetLocationDir * ToTargetLocation.Size2D()) * 0.5;
			}
		}
		
		//Debug::DrawDebugSphere(TargetLocation, 100);

		// Keep moving towards target, if not falling.
		if (MoveComp.IsInAir())
			DestinationComp.ReportStopping();
		else
			DestinationComp.MoveTowards(TargetLocation, BasicSettings.ChaseMoveSpeed);

		// Crowd avoidance
		if (Time::GameTimeSeconds < PauseTime)
			return;

		// Check if some team members are close enough for avoidance consideration
		// Only check one member each tick
		TArray<AHazeActor> PotentialAvoiders = BehaviourComp.Team.GetMembers();
		if (PotentialAvoiders.Num() < 2) 
		{
			// We're one of them so need two or more to have to avoid.
			PauseTime = Time::GameTimeSeconds + 1.0;
			return;
		}
		CurrentTeamIndex = (CurrentTeamIndex + 1) % PotentialAvoiders.Num();
		AHazeActor PotentialAvoidee = PotentialAvoiders[CurrentTeamIndex];
		if ((PotentialAvoidee != nullptr) && (PotentialAvoidee != Owner) && 
			PotentialAvoidee.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, BasicSettings.CrowdAvoidanceMaxRange * 2.0))
			ActorsToAvoid.AddUnique(PotentialAvoidee);

		if (ActorsToAvoid.Num() == 0)
		{
			// Check again in a while
			PauseTime = Time::GameTimeSeconds + 1.0 / PotentialAvoiders.Num();
			return;
		}

		// Check all confirmed to be close enough for consideration
		FVector OwnLoc = Owner.ActorCenterLocation;
		float RangeSqr = Math::Square(BasicSettings.CrowdAvoidanceMaxRange);
		FVector2D AvoidRanges = FVector2D(BasicSettings.CrowdAvoidanceMinRange, Math::Max(BasicSettings.CrowdAvoidanceMaxRange, BasicSettings.CrowdAvoidanceMinRange + 1.0));
		FVector Repulsion = FVector::ZeroVector;
		for (int i = ActorsToAvoid.Num() - 1; i >= 0; i--)
		{
			AHazeActor Avoidee = ActorsToAvoid[i];
			if (Avoidee == nullptr)
			{
				ActorsToAvoid.RemoveAtSwap(i);		
				continue;
			}

			FVector AvoidLoc = Avoidee.ActorCenterLocation;
			float DistSqr = OwnLoc.DistSquared(AvoidLoc); 
			if (DistSqr > RangeSqr)
			{
				if (DistSqr > RangeSqr * 9.0)
					ActorsToAvoid.RemoveAtSwap(i);		
				continue;
			}

			float Dist = Math::Sqrt(DistSqr);
			float DistClamped = Math::Max(1.0, Dist);
			FVector AwayDir = (OwnLoc - AvoidLoc) / DistClamped;
			if (AwayDir.IsNearlyZero(0.8))
				AwayDir = Math::GetRandomPointOnCircle_XY();
			AwayDir = AwayDir.ConstrainToPlane(MoveComp.WorldUp);
			float Fraction = Math::GetMappedRangeValueClamped(AvoidRanges, FVector2D(1.0, 0.0), DistClamped);
			float AvoidForce = Math::Square(Fraction) * BasicSettings.CrowdAvoidanceForce;
			Repulsion += (AwayDir * AvoidForce);
			// Debug::DrawDebugSphere(AvoidLoc, AvoidRanges[0], 12, FLinearColor::Red, 1.0);
			// Debug::DrawDebugSphere(AvoidLoc, AvoidRanges[1], 12, FLinearColor::Yellow);
			// Debug::DrawDebugLine(AvoidLoc, AvoidLoc + AwayDir * AvoidForce, FLinearColor::Red);
		}

		if (!Repulsion.IsNearlyZero())
		{
			// Never repulse stronger than max avoidance (e.g. in case there were many repulsers at the same location)
			FVector ClampedRepulsion = Repulsion.GetClampedToMaxSize(BasicSettings.CrowdAvoidanceForce);
			DestinationComp.AddCustomAcceleration(ClampedRepulsion);
		}
	}
}