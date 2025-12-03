class ANightQueenArmouredArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Shoulder;
	UPROPERTY(DefaultComponent, Attach = Shoulder)
	USceneComponent UpperArm;
	UPROPERTY(DefaultComponent, Attach = UpperArm)
	USceneComponent ForeArm;
	UPROPERTY(DefaultComponent, Attach = ForeArm)
	USceneComponent Hand;
	UPROPERTY(DefaultComponent, Attach = Hand)
	USceneComponent GroundImpactLocation;
	UPROPERTY(DefaultComponent, Attach = Hand)
	USummitDeathVolumeComponent DeathVolume;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ANightQueenArmouredArm AttackPose;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ANightQueenArmouredArm ReadyPose;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"NightQueenArmouredArmAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"NightQueenArmouredArmTargetingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"NightQueenArmouredFacePlayerCapability");

	UPROPERTY()
	UNiagaraSystem GroundImpact;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	ANightQueenArmouredArm TargetPose;

	TArray<AHazePlayerCharacter> TargetPlayers;

	FRotator ShoulderStart;
	FRotator UpperArmStart;
	FRotator ForeArmStart;
	FRotator HandStart;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bIsPose = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AttackRange = 1500.0;

	float AggressionDistance = 5500.0;
	float RotateSpeed = 320.0;
	bool bDefaultMode;

	bool bAttacking;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShoulderStart = Shoulder.RelativeRotation;
		UpperArmStart = UpperArm.RelativeRotation;
		ForeArmStart = ForeArm.RelativeRotation;
		HandStart = Hand.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (TargetPose == nullptr)
			return;

		if (bDefaultMode)
		{
			Shoulder.RelativeRotation = Math::RInterpConstantTo(Shoulder.RelativeRotation, ShoulderStart, DeltaSeconds, RotateSpeed);
			UpperArm.RelativeRotation = Math::RInterpConstantTo(UpperArm.RelativeRotation, UpperArmStart, DeltaSeconds, RotateSpeed);
			ForeArm.RelativeRotation = Math::RInterpConstantTo(ForeArm.RelativeRotation, ForeArmStart, DeltaSeconds, RotateSpeed);
			Hand.RelativeRotation = Math::RInterpConstantTo(Hand.RelativeRotation, HandStart, DeltaSeconds, RotateSpeed);
		}
		else
		{
			Shoulder.RelativeRotation = Math::RInterpConstantTo(Shoulder.RelativeRotation, TargetPose.Shoulder.RelativeRotation, DeltaSeconds, RotateSpeed);
			UpperArm.RelativeRotation = Math::RInterpConstantTo(UpperArm.RelativeRotation, TargetPose.UpperArm.RelativeRotation, DeltaSeconds, RotateSpeed);
			ForeArm.RelativeRotation = Math::RInterpConstantTo(ForeArm.RelativeRotation, TargetPose.ForeArm.RelativeRotation, DeltaSeconds, RotateSpeed);
			Hand.RelativeRotation = Math::RInterpConstantTo(Hand.RelativeRotation, TargetPose.Hand.RelativeRotation, DeltaSeconds, RotateSpeed);
		}
	}

	void SetNewTarget(AHazePlayerCharacter InPlayer)
	{
		if (TargetPlayers.Num() == 0)
		{
			SetReadyPose();
		}

		TargetPlayers.AddUnique(InPlayer);
	}

	void RemoveTarget(AHazePlayerCharacter InPlayer)
	{
		TargetPlayers.Remove(InPlayer);

		if (TargetPlayers.Num() == 0)
		{
			SetReadyPose();
		}
	}

	AHazePlayerCharacter GetClosestTargetPlayer() const
	{
		AHazePlayerCharacter CurrentPlayer;
		float CurrentDistance = 10000000.0;

		for (AHazePlayerCharacter Player : TargetPlayers)
		{
			float Distance = (Player.ActorLocation - ActorLocation).Size();

			if (Distance < CurrentDistance)
			{
				CurrentDistance = Distance;
				CurrentPlayer = Player;
			}
		}

		return CurrentPlayer;
	}

	void SetAttackPose()
	{
		TargetPose = AttackPose;
		bDefaultMode = false;
		bAttacking = true;
	}

	void SetReadyPose()
	{
		TargetPose = ReadyPose;
		bDefaultMode = false;
		bAttacking = false;
	}

	void SetDefaultPose()
	{
		bDefaultMode = true;
	}
}