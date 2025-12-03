
// Shy away from other Ais
class UIslandBuzzerWalkerRepulsionBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	// Note that since this uses impulses it does not require movement.
	default CapabilityTags.Add(n"CrowdRepulsion");

	TArray<AHazeActor> ActorsToAvoid;
	int CurrentTeamIndex = 0.0;
	UHazeMovementComponent MoveComp;
	UIslandBuzzerSettings BuzzerSettings;

	// Use this instead of cooldown, since we don't really need to activate/deactivate 
	// this behaviour and want to minimize number of network messages 
	float PauseTime = 0.0; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CurrentTeamIndex = Math::RandRange(0, 10);
		MoveComp = UHazeMovementComponent::Get(Owner);
		BuzzerSettings = UIslandBuzzerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds < PauseTime)
			return;

		UHazeTeam WalkerTeam = HazeTeam::GetTeam(IslandWalkerTags::IslandWalkerTeam);
		if(WalkerTeam == nullptr)
			return;
		
		// Check if some team members are close enough for avoidance consideration
		// Only check one member each tick
		TArray<AHazeActor> PotentialAvoiders = WalkerTeam.GetMembers();
		if (PotentialAvoiders.Num() == 0) 
		{
			// We're one of them so need two or more to have to avoid.
			PauseTime = Time::GameTimeSeconds + 1.0;
			return;
		}
		CurrentTeamIndex = (CurrentTeamIndex + 1) % PotentialAvoiders.Num();
		AHazeActor PotentialAvoidee = PotentialAvoiders[CurrentTeamIndex];
		if ((PotentialAvoidee != nullptr) && (PotentialAvoidee != Owner) && 
			PotentialAvoidee.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, BuzzerSettings.WalkerRepulsionMaxRange * 2.0))
		{
			ActorsToAvoid.AddUnique(PotentialAvoidee);
		}

		if (ActorsToAvoid.Num() == 0)
		{
			// Check again in a while
			PauseTime = Time::GameTimeSeconds + 1.0 / PotentialAvoiders.Num();
			return;
		}

		// Check all confirmed to be close enough for consideration
		FVector OwnLoc = Owner.ActorCenterLocation;
		float RangeSqr = Math::Square(BuzzerSettings.WalkerRepulsionMaxRange);
		FVector2D AvoidRanges = FVector2D(BuzzerSettings.WalkerRepulsionMinRange, Math::Max(BuzzerSettings.WalkerRepulsionMaxRange, BuzzerSettings.WalkerRepulsionMinRange + 1.0));
		FVector Repulsion = FVector::ZeroVector;
		for (int i = ActorsToAvoid.Num() - 1; i >= 0; i--)
		{
			AHazeActor Avoidee = ActorsToAvoid[i];
			float RepulsionLength = BuzzerSettings.WalkerRepulsionLength / 2;
			FVector CenterLoc = Avoidee.ActorCenterLocation + Avoidee.ActorUpVector * 100;
			FVector AvoidLoc = Math::ClosestPointOnLine(CenterLoc - Avoidee.ActorForwardVector * RepulsionLength, CenterLoc + Avoidee.ActorForwardVector * RepulsionLength, OwnLoc);

			// Debug::DrawDebugCapsule(CenterLoc, BuzzerSettings.WalkerRepulsionLength + BuzzerSettings.WalkerRepulsionMaxRange, BuzzerSettings.WalkerRepulsionMaxRange, FRotator::MakeFromZ(Avoidee.ActorForwardVector), Thickness = 10, LineColor = FLinearColor::Red);
			// Debug::DrawDebugCapsule(CenterLoc, BuzzerSettings.WalkerRepulsionLength + BuzzerSettings.WalkerRepulsionMinRange, BuzzerSettings.WalkerRepulsionMinRange, FRotator::MakeFromZ(Avoidee.ActorForwardVector), Thickness = 10, LineColor = FLinearColor::Blue);

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
			float Fraction = Math::GetMappedRangeValueClamped(AvoidRanges, FVector2D(1.0, 0.0), DistClamped);
			float AvoidForce = Math::Square(Fraction) * BuzzerSettings.WalkerRepulsionForce;
			Repulsion += (AwayDir * AvoidForce);
		}

		if (!Repulsion.IsNearlyZero())
		{
			// Never repulse stronger than max avoidance (e.g. in case there were many repulsers at the same location)
			FVector ClampedRepulsion = Repulsion.GetClampedToMaxSize(BuzzerSettings.WalkerRepulsionForce);
			DestinationComp.AddCustomAcceleration(ClampedRepulsion);
		}
	}
}
