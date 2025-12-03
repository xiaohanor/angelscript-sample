class ASanctuaryWellDynamicDonutCollision : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DonutMeshComp;

	UPROPERTY(EditAnywhere)
	float LerpHeightStart = 4000.0;

	UPROPERTY(EditAnywhere)
	float CenterRadiusScale = 0.6;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams StumbleAnim;

	UPROPERTY(EditInstanceOnly)
	ASlidingDisc SlidingDisc;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPoint;

	FVector StartScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		StartScale = DonutMeshComp.WorldScale;
	}

	UFUNCTION()
	void Activate()
	{
		Timer::SetTimer(this, n"DelayedRemoveDisabler", 1.0);

		for (auto Player : Game::GetPlayers())
		{
			//Player.SmoothTeleportActor(RespawnPoint.GetPositionForPlayer(Player).Location, Player.ActorRotation, this, 4.0);
			
			auto MoveComp = UHazeMovementComponent::Get(Player);

			FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, 
							RespawnPoint.GetPositionForPlayer(Player).Location, 
							MoveComp.GravityForce, 
							300.0);

			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			Player.BlockCapabilities(PlayerMovementTags::Jump, this);
			Player.BlockCapabilities(PlayerMovementTags::Dash, this);

			Player.SetActorVelocity(FVector::ZeroVector);
			Player.AddMovementImpulse(LaunchVelocity * 1.5);

			Player.PlaySlotAnimation(StumbleAnim);
		}
		
		Timer::SetTimer(this, n"UnblockCapabilities", 1.5);
	}

	UFUNCTION()
	private void DelayedRemoveDisabler()
	{
		RemoveActorDisable(this);
	}

	UFUNCTION()
	private void UnblockCapabilities()
	{
		for (auto Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
			Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto ClosestPlayer = Game::GetClosestPlayer(SlidingDisc.ActorLocation);

		float CurrentDistance = ClosestPlayer.ActorLocation.Z - SlidingDisc.ActorLocation.Z;

		if (CurrentDistance < LerpHeightStart)
		{
			float NewRadius = Math::Lerp(CenterRadiusScale, StartScale.X, CurrentDistance / LerpHeightStart);

			DonutMeshComp.SetWorldScale3D(FVector(NewRadius, NewRadius, StartScale.Z));
		}
	}
};