
class UPlayerCarChaseDiveComponent : UActorComponent
{
	UPlayerCarChaseDiveSettings Settings;

    UPROPERTY(EditAnywhere)
    bool bActive;

    UPROPERTY(EditAnywhere)
    UAnimSequence DiveAnimation;

    UPROPERTY(EditAnywhere)
    UHazeCameraSpringArmSettingsDataAsset CameraSetting;

    UPROPERTY(EditAnywhere)
	UNiagaraSystem TrailEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerCarChaseDiveSettings::GetSettings(Cast<AHazeActor>(Owner));
	}
}