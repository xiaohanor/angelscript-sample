class UAdultDragonHomingTailSmashComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SmashStartedForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SmashImpactForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> SmashImpactCameraShake;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	USceneComponent SmashTargetComp;

	AHazePlayerCharacter Player;

	// Speed before smashing a target
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve AdditiveSpinSpeedCurve;

	// Speed fraction after smashing target (based on speed at moment of impact)
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SlowdownSpinSpeedFractionCurve;

	bool bHasSmashedActor = false;

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

		TemporalLog.Value(f"AdultDragonHomingTailSmash;SmashTargetComp", SmashTargetComp);
		// Print(f"AdultDragonTailSmash;State:{State}", 0, FLinearColor::Green);
	}
#endif
};