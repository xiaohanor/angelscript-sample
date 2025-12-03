 class AVendingMachineCan : AHazeActor
 {
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent NiagaraComp;

	bool bMoving = true;

	float MovementSpeed = 1500;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bMoving)
			return;

		FVector DeltaMove = ActorForwardVector * MovementSpeed * DeltaSeconds;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActor(this);
		TraceSettings.UseSphereShape(50);
		
		// FHitResult HitResult = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);
		// if(HitResult.bBlockingHit)
		// {
		// 	bMoving = false;
		// 	NiagaraComp.Deactivate();
		// 	Timer::SetTimer(this, n"Destroy", 3);
		// }

		SetActorLocation(ActorLocation + DeltaMove);
	}

	UFUNCTION()
	private void Destroy()
	{
		DestroyActor();
	}
 }