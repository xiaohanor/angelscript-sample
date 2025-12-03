class AMedallionHydraFlyingProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;

	AHazePlayerCharacter TargetPlayer;
	float HomingMultiplier = 1.0;
	FHazeAcceleratedVector AccTargetLocation;
	FHazeAcceleratedVector AccDirection;
	float Speed = 6000.0;

	bool bHoming = true;

	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccDirection.SnapTo(ActorForwardVector);

		AccTargetLocation.SnapTo(TargetPlayer.ActorLocation);
		BP_Activate();
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccTargetLocation.AccelerateTo(TargetPlayer.ActorLocation + TargetPlayer.ActorForwardVector * 1000.0, 2.5, DeltaSeconds);

		FVector TargetLocation = TargetPlayer.ActorLocation + TargetPlayer.ActorForwardVector * 1000.0;
		FVector HomingMovement = (TargetLocation - ActorLocation).GetSafeNormal();
		
		if (bHoming)
			AccDirection.AccelerateTo(HomingMovement, 2.5, DeltaSeconds);

		//FVector Direction = Math::Lerp(InitialForward, HomingMovement, HomingMultiplier);
		FVector DeltaMove = AccDirection.Value * Speed * DeltaSeconds;

		AddActorWorldOffset(DeltaMove);

		if (TargetPlayer.ActorForwardVector.DotProduct((ActorLocation - TargetPlayer.ActorLocation).GetSafeNormal()) < 0.0)
			StopHoming();

		if (GameTimeSinceCreation > 10.0)
			DestroyActor();

		if (HighfiveComp.IsHighfiveJumping())
			DestroyActor();

	}

	private void StopHoming()
	{
		bHoming = false;
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};