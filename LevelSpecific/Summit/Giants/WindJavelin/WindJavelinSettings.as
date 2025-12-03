/**
 * 
 */
class UWindJavelinSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "Spawning")
    FVector HandHoldRelativeLocation = FVector(-100.0, 0.0, 0.0);

    UPROPERTY(Category = "Aiming")
    FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;
	default AimSettings.OverrideAutoAimTarget = UWindJavelinAutoAimTargetComponent;
	default AimSettings.bCrosshairFollowsTarget = true;

    UPROPERTY(Category = "Aiming")
	UCurveFloat AimFOVCurve;

	UPROPERTY(Category = "Aiming")
	float AimMaxFOV = 10.0;

    UPROPERTY(Category = "Aiming")
	TSubclassOf<UTargetableWidget> AutoAimTargetWidget;

    UPROPERTY(Category = "Aiming")
	UHazeCameraSpringArmSettingsDataAsset CamSettings;
    
    UPROPERTY(Category = "Reloading")
    float AimAfterThrowDelay = 1.0;

    UPROPERTY(Category = "Charging")
    float StartChargingDelay = 0.2;

	UPROPERTY(Category = "Charging")
    float ChargeTime = 0.2;

    UPROPERTY(Category = "Charging")
    float SpawnJavelinDelay = 0.2;

    UPROPERTY(Category = "Charging")
	TSubclassOf<UCameraShakeBase> ChargeCameraShake;

    UPROPERTY(Category = "Charging")
	UForceFeedbackEffect ChargeForceFeedback;

    UPROPERTY(Category = "Throwing")
    FHazeCameraImpulse CameraImpulse;

    UPROPERTY(Category = "Throwing")
	TSubclassOf<UCameraShakeBase> ThrowCameraShake;

    UPROPERTY(Category = "Throwing")
	UForceFeedbackEffect ThrowForceFeedback;

    UPROPERTY(Category = "Throwing")
    float ThrowSpeed = 3000.0;

    UPROPERTY(Category = "Throwing|Recoil")
    float RecoilGroundIntensity = 18000.0;

    UPROPERTY(Category = "Throwing|Recoil")
    float RecoilAirIntensity = 18000.0;

    UPROPERTY(Category = "Throwing|Recoil")
    UCurveFloat RecoilCurve;

    UPROPERTY(Category = "Gravity")
    float Gravity = 300.0;

    UPROPERTY(Category = "Hit")
    bool bRequireWindJavelinTag = true;

    UPROPERTY(Category = "Hit")
	float Lifetime = 6.0;

    UPROPERTY(Category = "Reloading")
    float ReloadTime = 1.0;

    UPROPERTY(Category = "Animation")
    float StrafeYawOffset = 60.0;

    UPROPERTY(Category = "Animation")
    float RotationSpeed = 100.0;

    UPROPERTY(Category = "Animation|Transitions")
    float EnterToWindAimTime = 0.2;

    UPROPERTY(Category = "Animation|Transitions")
    float EnterToWindThrowTime = 0.1;

    UPROPERTY(Category = "Animation|Transitions")
    float EnterStillToWindAimTime = 0.2;

    UPROPERTY(Category = "Animation|Transitions")
    float EnterStillToWindThrowTime = 0.1;

    UPROPERTY(Category = "Animation|Transitions")
    float WindAimToWindThrowTime = 0.075;

    UPROPERTY(Category = "Animation|Throw")
    float ThrowStartDelay = 0.48;

    UPROPERTY(Category = "Animation|Throw")
    float ThrowEndDelay = 0.45;

	UPROPERTY(Category = "Tutorial")
	FText AimTutorialText;

	UPROPERTY(Category = "Tutorial")
	FText ThrowTutorialText;
}

namespace WindJavelin
{
    const FName DebugCategory = n"WindJavelin";
    const FName WindJavelinTag = n"WindJavelin";
    const FName WindJavelinProjectileTag = n"WindJavelinProjectile";
    const FName Feature = n"WindJavelin";
	const FName WindJavelinHittableTag = n"WindJavelinHittable";
    const FName TargetableCategory = n"WindJavelin";

    const EHazePlayer Player = EHazePlayer::Mio;
    const EHazeSelectPlayer SelectPlayer = EHazeSelectPlayer::Mio;

    const FName JavelinAttachSocket = n"RightAttach";

    const FName ThrowAction = ActionNames::WeaponFire;


    // Restart the editor if these is changed
    const float DefaultAutoAimDistance = 5000.0;    // The default value for all WindJavelinAutoAimTargetComponents
    const float MaxThrowDistance = 10000.0;         // The distance we will trace when throwing a wind javelin to calculate the trajectory

	const float PrepareToDestroyDelay = 5.0;

    AHazePlayerCharacter GetPlayer()
    {
        return Game::GetPlayer(Player);
    }
}