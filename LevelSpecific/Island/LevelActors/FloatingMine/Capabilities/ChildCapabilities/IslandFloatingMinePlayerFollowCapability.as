struct FIslandFloatingMinePlayerFollowActivationParams
{
	AHazePlayerCharacter PlayerToFollow;
}

class UIslandFloatingMinePlayerFollowCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AIslandFloatingMine Mine;

	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	AHazePlayerCharacter PlayerToFollow;

	UNiagaraComponent LaserEffect;

	float SpeedTowardsPlayer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mine = Cast<AIslandFloatingMine>(Owner);

		MoveComp = UHazeMovementComponent::Get(Mine);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandFloatingMinePlayerFollowActivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		for(auto Player : Game::Players)
		{
			float DistSqrd = Player.ActorCenterLocation.DistSquared(Mine.BobRoot.WorldLocation);
			if(DistSqrd <= Math::Square(Mine.DistanceToFindPlayer))
			{
				Params.PlayerToFollow = Player;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		float DistSqrd = PlayerToFollow.ActorCenterLocation.DistSquared(Mine.BobRoot.WorldLocation);
		if(DistSqrd <= Math::Square(Mine.DistanceToFindPlayer + Mine.LosePlayerAdditionalDistance))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandFloatingMinePlayerFollowActivationParams Params)
	{
		PlayerToFollow = Params.PlayerToFollow;

		FVector DirToPlayer = (PlayerToFollow.ActorCenterLocation - Mine.BobRoot.WorldLocation).GetSafeNormal();
		SpeedTowardsPlayer = Mine.ActorVelocity.DotProduct(DirToPlayer);

		LaserEffect = Niagara::SpawnLoopingNiagaraSystemAttachedAtLocation(Mine.TargetLaserEffect, Mine.BobRoot, Mine.BobRoot.WorldLocation);
		SetLaserParams();
		LaserEffect.Activate(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LaserEffect.Deactivate();
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector DirToPlayer = (PlayerToFollow.ActorCenterLocation - Mine.BobRoot.WorldLocation).GetSafeNormal();
				FQuat QuatFacingPlayer = FQuat::MakeFromX(DirToPlayer);
				Movement.InterpRotationTo(QuatFacingPlayer, Mine.PlayerFollowRotationSpeed);

				SpeedTowardsPlayer = Math::FInterpTo(SpeedTowardsPlayer, Mine.PlayerFollowMaxSpeed, DeltaTime, Mine.PlayerFollowAcceleration);
				FVector Velocity = Mine.ActorForwardVector * SpeedTowardsPlayer;
				Movement.AddVelocity(Velocity);

				SetLaserParams();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}

	private void SetLaserParams()
	{
		LaserEffect.SetVectorParameter(n"BeamStart", Mine.BobRoot.WorldLocation);
		LaserEffect.SetVectorParameter(n"BeamEnd", PlayerToFollow.ActorCenterLocation);
	}
}