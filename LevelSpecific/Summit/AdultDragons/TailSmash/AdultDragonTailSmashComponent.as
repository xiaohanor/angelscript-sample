class UAdultDragonTailSmashComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SmashStartedForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SmashImpactForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> SmashImpactCameraShake;

	USceneComponent SmashTargetComp;
	FVector SmashTargetPoint;

	AHazePlayerCharacter Player;

	// Speed override during spin
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SpinSpeedCurve;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset SpinChargeCameraSettings;

	float SpinChargeTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	bool HasTarget() const
	{
		return SmashTargetComp != nullptr;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(Owner);

		TemporalLog.Value(f"AdultDragonTailSmash;SmashTargetComp", SmashTargetComp);
		TemporalLog.Value(f"AdultDragonTailSmash;SmashTargetPoint", SmashTargetPoint);
		// Print(f"AdultDragonTailSmash;State:{State}", 0, FLinearColor::Green);
	}
#endif
};