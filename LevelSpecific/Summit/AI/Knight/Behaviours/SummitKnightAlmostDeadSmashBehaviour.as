class USummitKnightAlmostDeadSmashBehaviour : USummitKnightSmashGroundBehaviour
{
	// Stay in place and attack, never retract crystal bottom
	UFUNCTION(BlueprintOverride)
	void OnActivated() override
	{
		Super::OnActivated();
		RetractCrystalBottomTime = BIG_NUMBER;
	}

	FVector GetDestination() override
	{
		return KnightComp.Arena.DeathPosition.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		float Dist = Owner.ActorLocation.Dist2D(KnightComp.Arena.DeathPosition.WorldLocation);
		float NudgeSpeed = Math::GetMappedRangeValueClamped(FVector2D(2000.0, 0.0), FVector2D(1000.0, 1.0), Dist);
		DestinationComp.MoveTowardsIgnorePathfinding(KnightComp.Arena.DeathPosition.WorldLocation, NudgeSpeed);				
	}
}

