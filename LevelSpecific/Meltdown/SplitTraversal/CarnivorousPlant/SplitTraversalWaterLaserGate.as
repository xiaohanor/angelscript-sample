UCLASS(Abstract)
class USplitTraversalWaterLaserGateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenGate() {}
}

class ASplitTraversalWaterLaserGate : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent GateRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent WaterFallRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent WaterRoot;
	
	UPROPERTY(DefaultComponent, Attach = WaterFallRoot)
	UBoxComponent WaterFallTriggerComp;

	UPROPERTY(EditAnywhere)
	float OpenDistanceGate = 1000.0;

	UPROPERTY(EditAnywhere)
	float OpenDistanceWaterfall = 1000.0;

	UPROPERTY(EditAnywhere)
	float OpenDistanceWater = 100.0;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalCutableCable CableActor;

	UPROPERTY()
	FHazeTimeLike OpenTimeLike;
	default OpenTimeLike.UseSmoothCurveZeroToOne();
	default OpenTimeLike.Duration = 2.0;

	UPROPERTY()
	FHazeTimeLike LowerWaterTimeLike;
	default LowerWaterTimeLike.UseSmoothCurveZeroToOne();
	default LowerWaterTimeLike.Duration = 2.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		//CableActor.OnCableCut.AddUFunction(this, n"HandleCableCut");
		OpenTimeLike.BindUpdate(this, n"OpenTimeLikeUpdate");
		OpenTimeLike.BindFinished(this, n"OpenFinished");
		LowerWaterTimeLike.BindUpdate(this, n"LowerWaterTimeLikeUpdate");
		WaterFallTriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleWaterFallOverlap");
	}

	UFUNCTION()
	private void HandleWaterFallOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                    UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                    bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (OtherActor == Game::Zoe)
		{
			//Game::Zoe.AddMovementImpulse(-ActorForwardVector * 2000.0 + FVector::UpVector * 500.0);
			Game::Zoe.ApplyKnockdown(ActorForwardVector * -800.0, 2.0);
		}
	}

	UFUNCTION()
	private void LowerWaterTimeLikeUpdate(float CurrentValue)
	{
		WaterRoot.SetRelativeLocation(FVector::UpVector * CurrentValue * -OpenDistanceWater);
	}

	UFUNCTION()
	private void OpenTimeLikeUpdate(float CurrentValue)
	{
		GateRoot.SetRelativeLocation(FVector::UpVector * CurrentValue * -OpenDistanceGate);
		WaterFallRoot.SetRelativeLocation(FVector::UpVector * CurrentValue * -OpenDistanceWaterfall);
	}

	UFUNCTION()
	private void OpenFinished()
	{
		SetActorHiddenInGame(true);
	}

	UFUNCTION()
	private void HandleCableCut()
	{
		Timer::SetTimer(this, n"OpenGate", 5.0);
		Timer::SetTimer(this, n"LowerWater", 7.0);
	}

	UFUNCTION()
	void OpenGate()
	{
		OpenTimeLike.Play();
		USplitTraversalWaterLaserGateEventHandler::Trigger_OnOpenGate(this);
	}

	UFUNCTION()
	void LowerWater()
	{
		LowerWaterTimeLike.Play();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate() {}
};