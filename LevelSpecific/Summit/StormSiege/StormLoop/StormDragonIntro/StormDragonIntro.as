enum EStormDragonAttackState
{
	Default,
	Attacking,
	Swooping
}

event void FOnStormDragonFinished();

class AStormDragonIntro : AHazeCharacter
{
	EStormDragonAttackState State;

	UPROPERTY()
	FOnStormDragonFinished OnStormDragonFinished;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonIntroMoveForwardCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonIntroFlameCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonIntroLightningCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonIntroDebrisCapability");

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttackOrigin;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FlameEffect;
	default FlameEffect.SetAutoActivate(false);

	UPROPERTY()
	UMaterialInterface FlamePostProcessMat;

	UPROPERTY()
	TSubclassOf<AStormLoopDebris> StormDebrisClass;

	UPROPERTY()
	TSubclassOf<ASummitMagicTrajectoryProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere)
	TArray<ADebrisAttackPoint> DebrisPoints;

	UPROPERTY(EditAnywhere)
	TArray<ALightningAttackpoint> LightningPoints;
	
	UPROPERTY(EditAnywhere)
	TArray<AFlameAttackPoint> FlamePoints;

	UPROPERTY()
	TSubclassOf<AFlameAttackWave> FlameAttackWaveClass;

	UPROPERTY(EditAnywhere)
	AActor TargetPoint;

	float DelayTime;
	float DelayDuration = 2.5;

	float MaxDistance;

	//Flame
	bool bRunFlameAttack;
	
	//Lightning
	bool bRunLightningAttack;

	//Debris
	bool bRunDebrisAttack;
	int MaxDebrisAttackCount;

	float TimeToReachPoint = 31.0;
	float AdditionaDelayToReachpoint = 6.0;
	float TotalTimeToReachpoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MaxDistance = (ActorLocation - FlamePoints[1].ActorLocation).Size();
	}

	void SpawnMagicAttack(AHazeActor Target)
	{
		float MinOffset = -800.0;
		float MaxOffset = 800.0;
		float RX = Math::RandRange(MinOffset, MaxOffset);
		float RY = Math::RandRange(MinOffset, MaxOffset);
		float RZ = Math::RandRange(MinOffset, MaxOffset);
		FVector TargetLoc = Target.ActorLocation + FVector(RX, RY, RZ);
		FRotator RotTarget = (TargetLoc - AttackOrigin.WorldLocation).Rotation();

		// TODO: Use projectile launcher?
		ASummitMagicTrajectoryProjectile Proj = SpawnActor(ProjectileClass, AttackOrigin.WorldLocation, RotTarget, bDeferredSpawn = true);
		Proj.IgnoreActors.Add(this);
		Proj.TargetLocation = TargetLoc;
		Proj.Speed = 18200.0;
		Proj.Gravity = 2000.0;
		FinishSpawningActor(Proj);		
	}

	UFUNCTION()
	void ActivateAttackingState()
	{
		State = EStormDragonAttackState::Attacking;
		DelayTime = Time::GameTimeSeconds + DelayDuration;
		StartAttackSequences();
	}

	UFUNCTION(BlueprintEvent)
	void StartAttackSequences() {}

	UFUNCTION()
	void RunLightningAttack()
	{
		bRunLightningAttack = true;
	}

	UFUNCTION()
	void RunFlameAttack()
	{
		bRunFlameAttack = true;
	}

	UFUNCTION()
	void RunDebrisAttack(int AttackCount = 1)
	{
		bRunDebrisAttack = true;
		MaxDebrisAttackCount = AttackCount;
		Print("RunDebrisAttack");
	}

	void SpawnDebris(int Index)
	{
		Print("SpawnDebris");
		ADebrisAttackPoint AttackPoint = DebrisPoints[Index];
		AStormLoopDebris Debris = SpawnActor(StormDebrisClass, ActorLocation, bDeferredSpawn = true);
		Debris.Direction = (AttackPoint.ActorLocation - ActorLocation).GetSafeNormal();
		Debris.Speed = 9000.0;
		FinishSpawningActor(Debris);
	}

	void SpawnFlameAttack(FVector TargetLocation)
	{
		float Dist = (ActorLocation - TargetLocation).Size();
		float Multiplier = Dist / MaxDistance;
		AFlameAttackWave FlameWave = SpawnActor(FlameAttackWaveClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
		FlameWave.Speed = 12000.0;
		FlameWave.TargetLocation = TargetLocation;
		FinishSpawningActor(FlameWave);
	}

	UFUNCTION()
	void FinishStormDragonSequence()
	{
		OnStormDragonFinished.Broadcast();
	}
}