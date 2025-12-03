UCLASS(Abstract)
class USkylineTimedLaunchFanEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerOverlap(FSkylineAllyLaunchFanOverlapParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEndOverlap() {}
}

class ASkylineTimedLaunchFan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FanBladeMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent WindTriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathTriggerComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY()
	FHazeTimeLike SpinTimeLike;
	default SpinTimeLike.UseSmoothCurveZeroToOne();
	default SpinTimeLike.Duration = 1.0;

	float Speed = 100.0;

	bool bZoeOverlapping = false;

	bool bBlowing = false;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");
		SpinTimeLike.BindUpdate(this, n"SpinTimeLikeUpdate");
		WindTriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleTriggerBeginOverlap");
		WindTriggerComp.OnComponentEndOverlap.AddUFunction(this, n"HandleTriggerEndOverlap");
		DeathTriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleDeathTriggerComp");
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		if (!bZoeOverlapping)
			bBlowing = false;

		bActivated = false;
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		BPActivated();
		SpinTimeLike.PlayFromStart();
		bBlowing = true;
		bActivated = true;

		if (bZoeOverlapping)
			ResetDoubleJump();

		USkylineTimedLaunchFanEventHandler::Trigger_OnStarted(this);
	}

	UFUNCTION()
	private void HandleDeathTriggerComp(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                    UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                    bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (IsValid(Player))
			Player.KillPlayer();
	}

	UFUNCTION()
	private void HandleTriggerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                       bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (OtherActor == Game::Zoe)
		{
			bZoeOverlapping = true;

			if (bActivated)
				ResetDoubleJump();
		}
	}

	UFUNCTION()
	private void HandleTriggerEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (OtherActor == Game::Zoe)
		{
			bZoeOverlapping = false;
			USkylineTimedLaunchFanEventHandler::Trigger_OnPlayerEndOverlap(this);
		}
			

		if (!bActivated && !bZoeOverlapping)
		{
			bBlowing = false;
		}
			
	}

	UFUNCTION()
	private void ResetDoubleJump()
	{
		Game::Zoe.ResetAirDashUsage();
		Game::Zoe.ResetAirJumpUsage();

		FSkylineAllyLaunchFanOverlapParams Params;
		Params.Player = Game::Zoe;
		
		USkylineTimedLaunchFanEventHandler::Trigger_OnPlayerOverlap(this, Params);
	}

	UFUNCTION()
	private void SpinTimeLikeUpdate(float CurrentValue)
	{
		Speed = Math::Lerp(100.0, 1000.0, CurrentValue);
	}

	UFUNCTION(BlueprintEvent)
	private void BPActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FanBladeMeshComp.AddRelativeRotation(FRotator(0.0, 0.0, Speed * DeltaSeconds));

		if (bZoeOverlapping && bBlowing)
		{
			FVector ToCenterVector = (ActorLocation - Game::Zoe.ActorLocation) * FVector(1.0, 1.0, 0.0) * 1.0;

			Game::Zoe.AddMovementImpulse(ToCenterVector * DeltaSeconds);

			Game::Zoe.AddMovementImpulse(ActorUpVector * 5000.0 * DeltaSeconds);
		}
	}
};