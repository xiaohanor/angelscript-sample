class UControllableDropShipFollowPlayersCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"EnemyControlled");

	default TickGroup = EHazeTickGroup::Gameplay;

	AControllableDropShip DropShip;

	float DistanceFromPlayers = 4000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DropShip = Cast<AControllableDropShip>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DropShip.bFollowingPlayers)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DropShip.bFollowingPlayers)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DropShip.SyncedShipPosition.HasControl())
		{
			AHazePlayerCharacter ClosestPlayer = Game::Mio;
			if (DropShip.GetDistanceTo(Game::Mio) > DropShip.GetDistanceTo(Game::Zoe))
				ClosestPlayer = Game::Zoe;

			float SplineDist = DropShip.ShootAtPlayersSplineComp.GetClosestSplineDistanceToWorldLocation(ClosestPlayer.ActorLocation);
			FVector Loc = Math::VInterpTo(DropShip.ActorLocation, DropShip.ShootAtPlayersSplineComp.GetWorldLocationAtSplineDistance(SplineDist + DistanceFromPlayers), DeltaTime, 2.0);
			DropShip.SetActorLocation(Loc);
		}
		else
		{
			DropShip.SetActorLocationAndRotation(DropShip.SyncedShipPosition.Position.WorldLocation, DropShip.SyncedShipPosition.Position.WorldRotation);
		}
	}
}