class AGemSpearMaster : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LaunchRoot;
	UPROPERTY(DefaultComponent, Attach = LaunchRoot)
	USceneComponent LaunchPoint1;
	UPROPERTY(DefaultComponent, Attach = LaunchRoot)
	USceneComponent LaunchPoint2;
	UPROPERTY(DefaultComponent, Attach = LaunchRoot)
	USceneComponent LaunchPoint3;
	UPROPERTY(DefaultComponent, Attach = LaunchRoot)
	USceneComponent LaunchPoint4;
	UPROPERTY(DefaultComponent, Attach = LaunchRoot)
	USceneComponent LaunchPoint5;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UAdultDragonTailSmashModeTargetableComponent TailTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"GemSpearMasterAttackCapability"); 

	UPROPERTY(DefaultComponent)
	UStormSiegeDetectPlayerComponent DetectPlayerComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AGemSpearAttack> GemSwordClass;

	UPROPERTY()
	TSubclassOf<ANightQueenShieldRotator> ShieldRotatorClass;

	UPROPERTY(EditAnywhere)
	bool bSpawnMetalShields = true;

	FHazeAcceleratedQuat AccelQuat;

	bool bSendToMio;
	bool bIsAttacking;

	float WaitTime;
	float WaitDuration = 2.5;
	float MiniAttackTime;
	float MiniAttackDuration = 0.1;
	int AttackCount;

	UPROPERTY(EditAnywhere)
	int MaxAttackCount = 5;

	UPROPERTY(EditAnywhere)
	float AggressionRange = 30000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		AccelQuat.SnapTo(ActorQuat);

		if (bSpawnMetalShields)
		{
			ANightQueenShieldRotator ShieldRotator = SpawnActor(ShieldRotatorClass, ActorLocation);
			ShieldRotator.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			ShieldRotator.RotSpeed = 5.0;
			AddMetalInZone();
		}
	}

	void SpawnSword(AHazePlayerCharacter TargetPlayer, USceneComponent Target)
	{
		FVector GoToLocation = Target.WorldLocation;
		AGemSpearAttack Sword = SpawnActor(GemSwordClass, ActorLocation, (GoToLocation - ActorLocation).Rotation(), NAME_None, true);
		Sword.StartLocation = GoToLocation;
		Sword.TargetPlayer = TargetPlayer;
		FinishSpawningActor(Sword);
	}
}