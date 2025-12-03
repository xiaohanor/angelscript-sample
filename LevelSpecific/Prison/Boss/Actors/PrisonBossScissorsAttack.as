class APrisonBossScissorsAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent ScissorsRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnTimeLike;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bSpawning = true;
	float SweepAlpha = 0.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnTimeLike.BindUpdate(this, n"UpdateSpawn");
		SpawnTimeLike.BindFinished(this, n"FinishSpawn");
		SpawnTimeLike.PlayFromStart();

		BP_Spawn();

		UPrisonBossScissorsEffectEventHandler::Trigger_Spawn(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Spawn() {}

	UFUNCTION()
	private void UpdateSpawn(float CurValue)
	{
		// ScissorsRoot.SetRelativeScale3D(FVector(1.0, 1.0, CurValue));
	}

	UFUNCTION()
	private void FinishSpawn()
	{
		if (!bSpawning)
			DestroyActor();
	}

	void Despawn()
	{
		DetachFromActor(EDetachmentRule::KeepWorld);

		bSpawning = false;
		SpawnTimeLike.ReverseFromEnd();

		BP_Despawn();

		UPrisonBossScissorsEffectEventHandler::Trigger_Despawn(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Despawn() {}

	void SetRotation(float Rot)
	{
		RotationRoot.SetRelativeRotation(FRotator(0.0, Rot, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FHazeTraceSettings DamageTrace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
		DamageTrace.UseBoxShape(2000.0, 20.0, 80.0, FQuat(RotationRoot.ForwardVector.Rotation()));

		/*FHazeTraceDebugSettings Debug;
		Debug.Duration = 0.0;
		Debug.Thickness = 10.0;
		Debug.TraceColor = FLinearColor::Red;
		DamageTrace.DebugDraw(Debug);*/

		FOverlapResultArray OverlapArray = DamageTrace.QueryOverlaps(ScissorsRoot.WorldLocation + (ScissorsRoot.ForwardVector * 2000.0));
		for (FOverlapResult Result : OverlapArray)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
			if (Player != nullptr)
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(FVector::UpVector), DamageEffect, DeathEffect);
		}
	}
}