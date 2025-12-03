

class UTrainFlyingEnemyTargetPlayerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 10;

	ATrainFlyingEnemy Enemy;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<ATrainFlyingEnemy>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTrainFlyingEnemyTargetingParams& Params) const
	{
		if (!Enemy.bRetarget && Enemy.Target.TargetPlayer != nullptr)
			return false;
		if (Enemy.bDestroyedByPlayer)
			return false;

		// Target the player that is closest to the car
		AHazePlayerCharacter ClosestPlayer;
		float ClosestPlayerDist = MAX_flt;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!CanTargetPlayer(Player))
				continue;

			float Dist = Player.GetDistanceTo(Enemy);
			if (Dist < ClosestPlayerDist)
			{
				ClosestPlayer = Player;
				ClosestPlayerDist = Dist;
			}
		}

		if (ClosestPlayer == nullptr)
			return false;

		ACoastTrainCart Cart = Enemy.TrainCart.Driver.GetCartClosestToPlayer(ClosestPlayer);
		if (Cart == nullptr)
			return false;

		Params.TargetPlayer = ClosestPlayer;
		Params.TargetCart = Cart;
		Params.TargetOffset = Cart.CurrentPosition.WorldTransform.InverseTransformPositionNoScale(ClosestPlayer.ActorLocation);
		return true;
	}

	bool CanTargetPlayer(AHazePlayerCharacter Player) const
	{
		if (Enemy.Target.TargetPlayer != nullptr)
		{
			if (!Enemy.IsPlayerInLineOfSight(Player))
				return false;
		}
		if (Enemy.IsPlayerOnTopOfCar(Player))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTrainFlyingEnemyTargetingParams Params)
	{
		Enemy.bRetarget = false;
		Enemy.Target = Params;
	}
}