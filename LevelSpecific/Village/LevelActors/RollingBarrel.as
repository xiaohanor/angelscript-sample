class ARollingBarrel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase LoadRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase ThrowRoot;

	UPROPERTY(DefaultComponent, Attach = LoadRoot, AttachSocket = "Base")
	USceneComponent BarrelRoot;

	UPROPERTY(DefaultComponent, Attach = BarrelRoot)
	UBoxComponent VillagerKillTrigger;

	UPROPERTY(DefaultComponent, Attach = BarrelRoot)
	UDeathTriggerComponent PlayerKillTrigger;

	UPROPERTY(DefaultComponent, Attach = BarrelRoot)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent WobbleRoot;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LoadAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LeftAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MidAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence RightAnim;

	bool bRolling = false;

	float SplineDist = 0.0;

	EVillageBarrelThrowSide CurrentSide;

	float Radius = 80.0;

	float WobbleTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VillagerKillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"KillVillager");
	}

	UFUNCTION()
	private void KillVillager(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AVillageVillager Villager = Cast<AVillageVillager>(OtherActor);
		if (Villager != nullptr)
		{
			Villager.Kill();
		}
	}

	void Spawn(ASplineActor Spline, EVillageBarrelThrowSide Side)
	{
		SplineActor = Spline;
		SplineComp = SplineActor.Spline;

		BP_Spawn();

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = LoadAnim;
		AnimParams.BlendTime = 0.0;
		AnimParams.BlendOutTime = 0.0;
		AnimParams.bPauseAtEnd = false;
		LoadRoot.PlaySlotAnimation(AnimParams);

		Timer::SetTimer(this, n"LoadFinished", 2.0);

		CurrentSide = Side;

		URollingBarrelEffectEventHandler::Trigger_Loaded(this);
	}

	UFUNCTION()
	private void LoadFinished()
	{
		BarrelRoot.AttachToComponent(ThrowRoot, n"Base", EAttachmentRule::SnapToTarget);

		UAnimSequence ThrowAnim;
		switch (CurrentSide)
		{
			case EVillageBarrelThrowSide::Left:
				ThrowAnim = LeftAnim;
			break;
			case EVillageBarrelThrowSide::Mid:
				ThrowAnim = MidAnim;
			break;
			case EVillageBarrelThrowSide::Right:
				ThrowAnim = RightAnim;
			break;
		}

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = ThrowAnim;
		AnimParams.BlendTime = 0.0;
		AnimParams.BlendOutTime = 0.0;
		AnimParams.bPauseAtEnd = true;
		ThrowRoot.PlaySlotAnimation(AnimParams);

		Timer::SetTimer(this, n"ThrowFinished", 2.0);
		BarrelRoot.AttachToComponent(ThrowRoot, n"Base", EAttachmentRule::KeepWorld);

		URollingBarrelEffectEventHandler::Trigger_Thrown(this);
	}

	UFUNCTION()
	private void ThrowFinished()
	{
		StartRolling();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Spawn() {}

	UFUNCTION()
	void StartRolling()
	{
		SplineDist = SplineComp.GetClosestSplineDistanceToWorldLocation(BarrelRoot.WorldLocation);
		bRolling = true;

		URollingBarrelEffectEventHandler::Trigger_StartRolling(this);
	}

	UFUNCTION()
	void StartRollingWithoutDrop(float StartDist, ASplineActor Spline)
	{
		WobbleTime = Math::RandRange(0.0, 2.0);

		SplineActor = Spline;
		SplineComp = SplineActor.Spline;
		SplineDist = StartDist;
		SetActorRotation(FRotator(0.0, ActorRotation.Yaw, 90.0));
		bRolling = true;

		URollingBarrelEffectEventHandler::Trigger_StartRolling_WithoutDrop(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bRolling)
			return;

		RotationRoot.AddLocalRotation(FRotator(0.0, 350.0 * DeltaTime, 0.0));

		float Roll = Math::Sin(WobbleTime * 2.0) * 5.0;
		WobbleRoot.SetRelativeRotation(FRotator(0.0, 0.0, Roll));
		WobbleTime += DeltaTime;

		SplineDist += 500.0 * DeltaTime;

		FVector Loc = SplineComp.GetWorldLocationAtSplineDistance(SplineDist) + (SplineComp.GetWorldRotationAtSplineDistance(SplineDist).UpVector * Radius);
		BarrelRoot.SetWorldLocation(Loc);

		if (SplineDist >= SplineComp.SplineLength)
			Explode();
	}

	void Explode()
	{
		BP_Explode();
		
		URollingBarrelEffectEventHandler::Trigger_Destroyed(this);

		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() {}
}

class URollingBarrelEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Loaded() {}
	UFUNCTION(BlueprintEvent)
	void Thrown() {}
	UFUNCTION(BlueprintEvent)
	void StartRolling() {}
	UFUNCTION(BlueprintEvent)
	void StartRolling_WithoutDrop() {}
	UFUNCTION(BlueprintEvent)
	void Destroyed() {}
	UFUNCTION(BlueprintEvent)
	void PlayerKilled() {}
}