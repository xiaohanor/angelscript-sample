/**
 * 
 */
class UIceBowSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "Visual")
	UStaticMesh IceBowMesh;

	UPROPERTY(Category = "Aiming")
    FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;
	default AimSettings.OverrideAutoAimTarget = UIceBowAutoAimTargetComponent;
	default AimSettings.bCrosshairFollowsTarget = true;
    
	UPROPERTY(Category = "Aiming")
    UCurveFloat CrosshairSizeCurve;

	UPROPERTY(Category = "Aiming")
	float AimMaxFOV = -10.0;

    UPROPERTY(Category = "Aiming")
	TSubclassOf<UTargetableWidget> AutoAimTargetWidget;

    UPROPERTY(Category = "Aiming")
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY(Category = "Reloading")
    float ReloadTime = 0.2;

    UPROPERTY(Category = "Charging")
    float ChargeTime = 0.7;

	UPROPERTY(Category = "Charging")
    float MinimumCharge = 0.3;

	UPROPERTY(Category = "Charging")
	UCurveFloat ChargeFOVCurve;

    UPROPERTY(Category = "Charging")
	TSubclassOf<UCameraShakeBase> ChargeCameraShake;

    UPROPERTY(Category = "Charging")
	UForceFeedbackEffect ChargeForceFeedback;

	UPROPERTY(Category = "Charging")
	UForceFeedbackEffect FullyChargedForceFeedback;
    
    UPROPERTY(Category = "Launching")
    FHazeCameraImpulse LaunchCameraImpulse;

    UPROPERTY(Category = "Launching")
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

    UPROPERTY(Category = "Launching")
	UForceFeedbackEffect LaunchForceFeedback;

    UPROPERTY(Category = "Animation")
    float ShootAnimDuration = 0.35;

	UPROPERTY(Category = "Animation")
    float StrafeYawOffset = 60.0;

	UPROPERTY(Category = "Tutorial")
	FText AimTutorialText;

	UPROPERTY(Category = "Tutorial")
	FText ChargeTutorialText;

	UPROPERTY(Category = "Tutorial")
	FText ShootTutorialText;

    UPROPERTY(Category = "Tutorial")
	FText FullChargeTutorialText;
}

namespace IceBow
{
    const FName DebugCategory = n"IceBow";
    const FName IceBowTag = n"IceBow";
    const FName TargetableCategory = n"IceBow";
    const FName Feature = n"IceBow";

    const EHazePlayer Player = EHazePlayer::Mio;
    const EHazeSelectPlayer SelectPlayer = EHazeSelectPlayer::Mio;

    const FName BowComponentName = n"IceBowMesh";
    const FName BowAttachSocket = n"LeftAttach";

    const FName AimAction = ActionNames::WeaponAim;
    const FName ShotAction = ActionNames::WeaponFire;

    // Restart the editor if these is changed
    const float DefaultAutoAimDistance = 5000.0;    // The default value for all WindJavelinAutoAimTargetComponents
    const float MaxShootDistance = 10000.0;          // The distance we will trace when throwing a wind javelin to calculate the trajectory
}