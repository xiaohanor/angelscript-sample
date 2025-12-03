UCLASS(Abstract)
class AFlippingHayBale : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent FlipRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent HayMeshComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FlipTimeLike;

	FTimerHandle FlipTimerHandle;
	float FlipDelay = 1.0;

	UPROPERTY(EditAnywhere)
	float FlipDistance = 200.0;

	UPROPERTY(EditAnywhere)
	bool bShowEffect = true;

	bool bEffectTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(HasControl())
		{
			float TimerStartDelay = Math::RandRange(0.1, 1.0);
			Timer::SetTimer(this, n"StartFlipTimer", TimerStartDelay);
		}

		FlipTimeLike.BindUpdate(this, n"UpdateFlip");
		FlipTimeLike.BindFinished(this, n"FinishFlip");

		HayMeshComp.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		SetActorLocation(ActorLocation + (ActorForwardVector * FlipDistance));

		HayMeshComp.AttachToComponent(FlipRoot, NAME_None, EAttachmentRule::KeepWorld);
		FlipTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void StartFlipTimer()
	{
		check(HasControl());
		FlipTimerHandle = Timer::SetTimer(this, n"TriggerFlip", FlipDelay, true);
	}

	UFUNCTION()
	private void TriggerFlip()
	{
		check(HasControl());

		TArray<int> ValidIndexes;

		FVector TraceDir = ActorForwardVector;
		for (int i = 0; i <= 3; i++)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(this);
			Trace.IgnorePlayers();
			Trace.UseBoxShape(FlipDistance/2, FQuat(ActorRotation));
			
			FVector TraceStartLoc = ActorLocation + (TraceDir * FlipDistance) + (FVector::UpVector * (FlipDistance/2) + FVector::UpVector);

			FHitResult Hit = Trace.QueryTraceSingle(TraceStartLoc, TraceStartLoc + FVector(0.0, 0.0, 0.1));
			TraceDir = TraceDir.RotateAngleAxis(90.0, FVector::UpVector);

			FHazeTraceSettings DownTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(this);
			Trace.IgnorePlayers();
			Trace.UseLine();

			FHitResult DownHit = Trace.QueryTraceSingle(TraceStartLoc, TraceStartLoc - (FVector::UpVector * (FlipDistance/2 + 10.0)));

			if (!Hit.bBlockingHit && DownHit.bBlockingHit)
				ValidIndexes.Add(i);
		}

		if (ValidIndexes.Num() == 0)
			return;

		ValidIndexes.Shuffle();
		int DirectionIndex = ValidIndexes[0];

		FVector FlipDirection;

		if (DirectionIndex == 0)
			FlipDirection = ActorForwardVector;
		else if (DirectionIndex == 1)
			FlipDirection = ActorRightVector;
		else if (DirectionIndex == 2)
			FlipDirection = -ActorForwardVector;
		else if (DirectionIndex == 3)
			FlipDirection = -ActorRightVector;
		else
			return;

		Crumb_TriggerFlip(FlipDirection);
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_TriggerFlip(FVector FlipDirection)
	{
		HayMeshComp.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		FVector Loc = ActorLocation + (FlipDirection * FlipDistance);
		SetActorLocation(Loc);
		
		FlipRoot.SetWorldRotation(FlipDirection.Rotation());
		FlipRoot.SetWorldLocation(FVector(ActorLocation + (-FlipDirection * (FlipDistance/2))));

		HayMeshComp.AttachToComponent(FlipRoot, NAME_None, EAttachmentRule::KeepWorld);

		bEffectTriggered = false;
		FlipTimeLike.PlayFromStart();
		UPigWorldFlippingHayBaleEventHandler::Trigger_OnFlip(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateFlip(float CurValue)
	{
		float Rot = Math::Lerp(0.0, -90.0, CurValue);
		FlipRoot.SetRelativeRotation(FRotator(Rot, FlipRoot.RelativeRotation.Yaw, 0.0));
		if (bShowEffect && !bEffectTriggered && CurValue >= 0.3)
		{
			bEffectTriggered = true;
			BP_TriggerEffect();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_TriggerEffect() {}

	UFUNCTION(NotBlueprintCallable)
	void FinishFlip()
	{
		BP_FinishFlip();
	}

	UFUNCTION(BlueprintEvent)
	void BP_FinishFlip() {}
}