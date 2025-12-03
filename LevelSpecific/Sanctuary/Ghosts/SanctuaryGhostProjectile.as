class ASanctuaryGhostProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	AHazePlayerCharacter TargetPlayer;

	float Speed = 1000.0;

	bool bIsHoming = true;

	float ExpireTime = -1.0;
	float NonHomingLifeTime = 5.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsHoming && Time::GameTimeSeconds > ExpireTime)
			Expire();

		FVector ToTarget = TargetPlayer.ActorCenterLocation - ActorLocation;
		float DistanceToTarget = ToTarget.Size();
		FVector Direction = ActorForwardVector;

		if (bIsHoming)
			Direction = ToTarget.SafeNormal;

		FVector DeltaMove = Direction * Speed * DeltaSeconds;

		ActorLocation += DeltaMove;
		ActorRotation = DeltaMove.ToOrientationRotator();

		if (bIsHoming && (TargetPlayer.IsPlayerDead() || (DistanceToTarget < 400.0 && TargetPlayer.IsAnyCapabilityActive(PlayerMovementTags::Dash))))
		{
			bIsHoming = false;
			ExpireTime = Time::GameTimeSeconds + NonHomingLifeTime;
		}

		if (bIsHoming && DistanceToTarget < 100.0)
		{
			TargetPlayer.DamagePlayerHealth(0.25);
			BP_Impact();
			DestroyActor();
		}
	}

	void Expire()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact() { }
};