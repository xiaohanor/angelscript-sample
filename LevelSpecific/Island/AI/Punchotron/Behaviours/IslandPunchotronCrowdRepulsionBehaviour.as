
// Shy away from other Ais
class UIslandPunchotronCrowdRepulsionBehaviour : UBasicBehaviour
{
	// This will only affect movement acceleration on control side. 
	// Any resulting movement will be separately replicated.
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	// Note that since this uses impulses it does not require movement.
	default CapabilityTags.Add(n"CrowdRepulsion");

	TArray<AHazeActor> ActorsToAvoid;
	int CurrentTeamIndex = 0.0;
	UHazeMovementComponent MoveComp;

	// Use this instead of cooldown, since we don't really need to activate/deactivate 
	// this behaviour and want to minimize number of network messages 
	float PauseTime = 0.0;

	UIslandPunchotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CurrentTeamIndex = Math::RandRange(0, 10);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
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
			PotentialAvoidee.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, Settings.CrowdAvoidanceMaxRange * 2.0))
			ActorsToAvoid.AddUnique(PotentialAvoidee);

		if (ActorsToAvoid.Num() == 0)
		{
			// Check again in a while
			PauseTime = Time::GameTimeSeconds + 1.0 / PotentialAvoiders.Num();
			return;
		}

		// Check all confirmed to be close enough for consideration
		FVector OwnLoc = Owner.ActorCenterLocation;
		float RangeSqr = Math::Square(Settings.CrowdAvoidanceMaxRange);
		FVector2D AvoidRanges = FVector2D(Settings.CrowdAvoidanceMinRange, Math::Max(Settings.CrowdAvoidanceMaxRange, Settings.CrowdAvoidanceMinRange + 1.0));
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
			float AvoidForce = Math::Square(Fraction) * Settings.CrowdAvoidanceForce;
			Repulsion += (AwayDir * AvoidForce);
			// Debug::DrawDebugSphere(AvoidLoc, AvoidRanges[0], 12, FLinearColor::Red, 1.0);
			// Debug::DrawDebugSphere(AvoidLoc, AvoidRanges[1], 12, FLinearColor::Yellow);
			// Debug::DrawDebugLine(AvoidLoc, AvoidLoc + AwayDir * AvoidForce, FLinearColor::Red);
		}

		if (!Repulsion.IsNearlyZero())
		{
			// Never repulse stronger than max avoidance (e.g. in case there were many repulsers at the same location)
			Repulsion = Repulsion.ProjectOnTo(Owner.ActorForwardVector);
			FVector ClampedRepulsion = Repulsion.GetClampedToMaxSize(Settings.CrowdAvoidanceForce);
			DestinationComp.AddCustomAcceleration(ClampedRepulsion);
		}
	}
}

