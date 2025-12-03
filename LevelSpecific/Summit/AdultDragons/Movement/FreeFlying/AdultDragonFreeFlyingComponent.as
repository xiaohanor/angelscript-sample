UCLASS(Abstract)
class UAdultDragonFreeFlyingComponent : UActorComponent
{
	// Camera settings that are blended in depending on speed
	// 0 -> 1 Flying Min Speed & Flying Max Speed
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset CameraSpeedSettings;

	// Camera settings that are enabled at start of flying and disabled at end of flying
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset CameraSettings;

	// UPROPERTY(EditDefaultsOnly, Category = "Settings")
	// UAdultDragonFlightSettings FlightSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> ImpactShake;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> SpeedShake;

	AHazePlayerCharacter Player;

	float RubberBandingMoveSpeedMultiplier = 1;

	AAdultDragonFreeFlyingRubberBandSpline RubberBandSpline;
	UAdultDragonSplineRubberBandSyncPointComponent RubberBandSplineSyncPointComp;

	UPROPERTY(EditDefaultsOnly)
	UAdultDragonSplineFollowRubberBandingSettings DefaultRubberBandSettings;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem OutsideBoundaryEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ApplyDefaultSettings(AdultDragonFreeFlying::AdultDragonFreeFlightSettings);
		Player.ApplyDefaultSettings(DefaultRubberBandSettings);
	}

	void SetRubberBandSpline(AAdultDragonFreeFlyingRubberBandSpline RubberBandSplineActor)
	{
		RubberBandSpline = RubberBandSplineActor;
		RubberBandSplineSyncPointComp = UAdultDragonSplineRubberBandSyncPointComponent::Get(RubberBandSplineActor);
	}
};