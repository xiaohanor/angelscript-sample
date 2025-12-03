UCLASS(Abstract)
class UMeltdownSplitSlideBridgeScannerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartScan() {}
}

class AMeltdownSplitSlideBridgeScanner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ScannerRoot;

	UPROPERTY()
	FHazeTimeLike ScannerRevealTimeLike;
	default ScannerRevealTimeLike.UseSmoothCurveZeroToOne();
	default ScannerRevealTimeLike.Duration = 0.3;

	UPROPERTY()
	FHazeTimeLike ScanTimeLike;;
	default ScanTimeLike.UseSmoothCurveZeroToOne();
	default ScanTimeLike.bFlipFlop = true;
	default ScanTimeLike.Duration = 1.0;

	FHazeAcceleratedVector AcceleratedTargetLocation;
	float HeightOffset = -500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScannerRevealTimeLike.BindUpdate(this, n"ScannerRevealTimeLikeUpdate");
		ScannerRevealTimeLike.BindFinished(this, n"ScannerRevealTimeLikeFinished");
		ScanTimeLike.BindUpdate(this, n"ScanTimeLikeUpdate");
		ScanTimeLike.BindFinished(this, n"ScanTimeLikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	void Activate()
	{			
		RemoveActorDisable(this);

		FVector AverageLocation = (Game::Zoe.ActorCenterLocation + Game::Mio.ActorCenterLocation) * 0.5;
		AverageLocation += FVector::UpVector * HeightOffset;
		AcceleratedTargetLocation.SnapTo(AverageLocation);

		ScannerRevealTimeLike.Play();

		BP_Activated();
		
		UMeltdownSplitSlideBridgeScannerEventHandler::Trigger_OnStartScan(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activated(){}

	UFUNCTION()
	private void ScannerRevealTimeLikeUpdate(float CurrentValue)
	{
		ScannerRoot.SetWorldScale3D(FVector(CurrentValue));
		SetScannerRotation();
	}

	UFUNCTION()
	private void ScannerRevealTimeLikeFinished()
	{
		if (!ScannerRevealTimeLike.IsReversed())
			ScanTimeLike.Play();
		else
			BP_Deactivated();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivated(){}

	UFUNCTION()
	private void ScanTimeLikeUpdate(float CurrentValue)
	{
		HeightOffset = Math::Lerp(-200, 200.0, CurrentValue);
		SetScannerRotation();
	}

	UFUNCTION()
	private void ScanTimeLikeFinished()
	{
		if (ScanTimeLike.IsReversed())
			ScannerRevealTimeLike.Reverse();
	}

	private void SetScannerRotation()
	{
		FVector AverageLocation = (Game::Zoe.ActorCenterLocation + Game::Mio.ActorCenterLocation) * 0.5;
		AverageLocation += FVector::UpVector * HeightOffset;
		AcceleratedTargetLocation.AccelerateTo(AverageLocation, 1.0, Time::GetActorDeltaSeconds(this));
		
		FRotator ScannerRotation = (AcceleratedTargetLocation.Value - ScannerRoot.WorldLocation).GetSafeNormal().Rotation();
		ScannerRoot.SetWorldRotation(ScannerRotation);
	}
};