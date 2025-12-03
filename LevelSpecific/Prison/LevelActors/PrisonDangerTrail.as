class APrisonDangerTrail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TrailRoot;

	UPROPERTY(DefaultComponent, Attach = TrailRoot)
	USceneComponent PreviewRoot;

	UPROPERTY(DefaultComponent, Attach = PreviewRoot)
	UNiagaraComponent PreviewEffectComp;

	UPROPERTY(DefaultComponent, Attach = TrailRoot)
	USceneComponent DangerRoot;

	UPROPERTY(DefaultComponent, Attach = DangerRoot)
	UNiagaraComponent DangerEffectComp;

	UPROPERTY(DefaultComponent, Attach = TrailRoot)
	UBoxComponent KillTrigger;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector EndLoc = FVector::ZeroVector;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveEffectTimeLike;
	default MoveEffectTimeLike.Duration = 0.2;

	USceneComponent CurrentMovingRoot;

	bool bTrailActive = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		KillTrigger.SetBoxExtent(FVector(EndLoc.X/2, 10.0, 10.0));
		KillTrigger.SetRelativeLocation(FVector(EndLoc.X/2, 0.0, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveEffectTimeLike.BindUpdate(this, n"UpdateMoveEffect");
		MoveEffectTimeLike.BindFinished(this, n"FinishMoveEffect");

		Timer::SetTimer(this, n"ActivatePreviewTrail", 2.0);

		PreviewEffectComp.SetNiagaraVariableFloat("Life", 2.0);
		DangerEffectComp.SetNiagaraVariableFloat("Life", 2.0);

		KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (bTrailActive)
			Player.KillPlayer();
	}

	UFUNCTION()
	void ActivatePreviewTrail()
	{
		bTrailActive = false;
		CurrentMovingRoot = PreviewRoot;
		MoveEffectTimeLike.PlayFromStart();

		Timer::SetTimer(this, n"ActivateDangerTrail", 2.0);
	}

	UFUNCTION()
	void ActivateDangerTrail()
	{
		bTrailActive = true;
		CurrentMovingRoot = DangerRoot;
		MoveEffectTimeLike.PlayFromStart();

		Timer::SetTimer(this, n"ActivatePreviewTrail", 3.0);

		TArray<AActor> Actors;
		KillTrigger.GetOverlappingActors(Actors, AHazePlayerCharacter);
		for (AActor Actor : Actors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player != nullptr)
				Player.KillPlayer();
		}
	}

	UFUNCTION()
	void UpdateMoveEffect(float CurValue)
	{
		FVector Loc = Math::Lerp(FVector::ZeroVector, EndLoc, CurValue);
		CurrentMovingRoot.SetRelativeLocation(Loc);
	}

	UFUNCTION()
	void FinishMoveEffect()
	{
		CurrentMovingRoot.SetRelativeLocation(FVector::ZeroVector);
	}
}