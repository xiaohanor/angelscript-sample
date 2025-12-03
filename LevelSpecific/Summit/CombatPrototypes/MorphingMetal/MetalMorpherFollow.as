class AMetalMorpherFollow : ANightQueenMetal
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpikesRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpikesActiveTargetLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	USummitKillAreaSphereComponent DeathSphere;

	UPROPERTY(EditAnywhere, Category = "Settings")
	EHazePlayer TargetPlayer;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartActive = false;

	AHazePlayerCharacter Player;

	FHazeAcceleratedRotator AccelRot;

	bool bSpikesActive = false;

	FVector StartLocation;
	FVector TelegraphLocation;

	float TelegraphTime;
	float TelegraphDuration = 1.2;
	float SpikeActiveTime;
	float SpikeActiveDuration = 2.5;
	float ActivateSpikeTime;
	float FollowDuration = 4.0;

	float MoveSpeed = 800.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		SetActorTickEnabled(false);

		if (bStartActive)
			ActivateFollowPlayer();

		DeathSphere.DisableKill();
		StartLocation = SpikesRoot.RelativeLocation;
		TelegraphLocation = StartLocation + FVector(0.0, 0.0, 120.0);

		if (TargetPlayer == EHazePlayer::Mio)
			Player = Game::Mio;
		else
			Player = Game::Zoe;

		FVector DirectionToPlayer = (Player.ActorLocation - ActorLocation).GetSafeNormal();
		AccelRot.SnapTo(DirectionToPlayer.Rotation());
		ActorRotation = AccelRot.Value; 

		ActivateSpikeTime = Time::GameTimeSeconds + FollowDuration;

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > ActivateSpikeTime && !bSpikesActive)
		{
			ActivateSpikes();
		}

		if (bSpikesActive)
		{
			if (Time::GameTimeSeconds > TelegraphTime)
			{
				SpikesRoot.RelativeLocation = Math::VInterpConstantTo(SpikesRoot.RelativeLocation, SpikesActiveTargetLocation.RelativeLocation, DeltaSeconds, 1800.0);
				if (!DeathSphere.CanKillPlayer())
					DeathSphere.EnableKill();
			}
			else	
			{
				SpikesRoot.RelativeLocation = Math::VInterpConstantTo(SpikesRoot.RelativeLocation, TelegraphLocation, DeltaSeconds, 80.0);
			}

			if (Time::GameTimeSeconds > SpikeActiveTime)
			{
				if (DeathSphere.CanKillPlayer())
					DeathSphere.DisableKill();
				DeactivateSpikes();
			}
		}
		else
		{
			SpikesRoot.RelativeLocation = Math::VInterpConstantTo(SpikesRoot.RelativeLocation, StartLocation, DeltaSeconds, 1000.0);

			FVector DirectionToPlayer = (Player.ActorLocation - ActorLocation).GetSafeNormal();
			DirectionToPlayer = DirectionToPlayer.ConstrainToPlane(FVector::UpVector);
			DirectionToPlayer.Normalize();
			AccelRot.AccelerateTo(DirectionToPlayer.Rotation(), 0.8, DeltaSeconds);
			ActorRotation = AccelRot.Value;

			ActorLocation += ActorForwardVector * MoveSpeed * DeltaSeconds;
		}
	}

	UFUNCTION()
	void ActivateSpikes()
	{
		TelegraphTime = Time::GameTimeSeconds + TelegraphDuration;
		bSpikesActive = true;
		SpikeActiveTime = Time::GameTimeSeconds + SpikeActiveDuration;
	}

	UFUNCTION()
	void DeactivateSpikes()
	{
		bSpikesActive = false;
		ActivateSpikeTime = Time::GameTimeSeconds + FollowDuration;
	}

	UFUNCTION()
	void ActivateFollowPlayer()
	{
		SetActorTickEnabled(true);
	}
}