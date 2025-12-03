UCLASS(Abstract)
class AFlyingPigPoop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PoopRoot;

	UPROPERTY(DefaultComponent, Attach = PoopRoot)
	USphereComponent OverlapComp;

	float FallSpeed = 2500.0;

	bool bFalling = true;

	float LifeTime = 0.0;

	bool bDestroyed = false;
	bool bDestroying = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEnter");
	}

	UFUNCTION()
	private void PlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor,  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr || !Player.HasControl())
			return;
		if (bDestroyed)
			return;
		if (bDestroying)
			return;

		TryDestroy(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bDestroyed)
			return;

		LifeTime += DeltaTime;
		if (LifeTime >= 10.0 && HasControl())
			TryDestroy(nullptr);

		if (!bFalling)
			return;

		FVector DeltaMove = -ActorUpVector * FallSpeed * DeltaTime;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(this);
		Trace.IgnorePlayers();
		Trace.UseLine();

		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		if (Hit.bBlockingHit)
		{
			SetActorLocation(Hit.ImpactPoint);
		}
		else
		{
			SetActorLocation(ActorLocation + DeltaMove);
		}
	}

	void TryDestroy(AHazePlayerCharacter StepPlayer)
	{
		if (bDestroying)
			return;
		if (bDestroyed)
			return;
		if (IsActorBeingDestroyed())
			return;
		bDestroying = true;
		CrumbDestroy(StepPlayer);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDestroy(AHazePlayerCharacter StepPlayer)
	{
		if (StepPlayer != nullptr)
		{
			FPoopStepEventHandlerParams EventParams;
			EventParams.Player = StepPlayer;
			UFlyingPigPoopEventHandler::Trigger_PoopStep(this, EventParams);
		}
		DestroyPoop();
		
	}

	void DestroyPoop()
	{
		UFlyingPigPoopEventHandler::Trigger_PoopExplode(this);
		bDestroyed = true;
		BP_DestroyPoop();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyPoop() {}
}