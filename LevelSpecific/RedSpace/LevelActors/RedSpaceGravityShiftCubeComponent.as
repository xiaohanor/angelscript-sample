class URedSpaceGravityShiftCubeComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	bool bRotateOnImpact = false;

	ARedSpaceCube Cube;

	TArray<AHazePlayerCharacter> PlayersOnCube;

	bool bRotating = false;

	TPerPlayer<bool> PlayersWithJumpBlocked;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cube = Cast<ARedSpaceCube>(Owner);

		UMovementImpactCallbackComponent MovementImpactCallbackComp = UMovementImpactCallbackComponent::Create(Cube);
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");

		Cube.OnStartedRotating.AddUFunction(this, n"StartedRotating");
		Cube.OnFinishedRotating.AddUFunction(this, n"FinishedRotating");
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		PlayersOnCube.Add(Player);
		if (bRotateOnImpact)
		{
			Cube.StartRotating();
		}
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		PlayersOnCube.Remove(Player);

		FVector TargetGravDir = Player.GetGravityDirection();
		FVector GravDir = Player.GetGravityDirection();

		FVector CurWorldUp = -Player.GetGravityDirection();
		FVector AbsWorldUp = CurWorldUp.Abs;

		FVector NewWorldUp;

		if (AbsWorldUp.X > AbsWorldUp.Y && AbsWorldUp.X > AbsWorldUp.Z)
			NewWorldUp = FVector(Math::RoundToInt(CurWorldUp.X), 0.0, 0.0);
		if (AbsWorldUp.Y > AbsWorldUp.X && AbsWorldUp.Y > AbsWorldUp.Z)
			NewWorldUp = FVector(0.0, Math::RoundToInt(CurWorldUp.Y), 0.0);
		if (AbsWorldUp.Z > AbsWorldUp.X && AbsWorldUp.Z > AbsWorldUp.Y)
			NewWorldUp = FVector(0.0, 0.0, Math::RoundToInt(CurWorldUp.Z));

		Player.OverrideGravityDirection(-NewWorldUp,Player);

		UnblockJump(Player);
	}
	
	UFUNCTION()
	private void StartedRotating()
	{
		bRotating = true;

		for (AHazePlayerCharacter Player : PlayersOnCube)
		{
			PlayersWithJumpBlocked[Player] = true;
			Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		}
	}

	UFUNCTION()
	private void FinishedRotating()
	{
		bRotating = false;

		for (AHazePlayerCharacter Player : PlayersOnCube)
		{
			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
			FMovementHitResult GroundImpact = MoveComp.GroundContact;
			Player.OverrideGravityDirection(-GroundImpact.ImpactNormal, Player);

			UnblockJump(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bRotating)
			return;

		for (AHazePlayerCharacter Player : PlayersOnCube)
		{
			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
			FMovementHitResult GroundImpact = MoveComp.GroundContact;
			Player.OverrideGravityDirection(-GroundImpact.ImpactNormal, Player);
		}
	}

	void UnblockJump(AHazePlayerCharacter Player)
	{
		if (PlayersWithJumpBlocked[Player])
		{
			PlayersWithJumpBlocked[Player] = false;
			Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		}
	}
}