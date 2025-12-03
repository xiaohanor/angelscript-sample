/**
 * 
 */
class USketchbookBowSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Aiming")
    FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;
	default AimSettings.bCrosshairFollowsTarget = true;
	default AimSettings.bUseAutoAim = true;
	default AimSettings.Crosshair2DSettings.DirectionalArrowSize = 0;
    
    UPROPERTY(Category = "Aiming")
	TSubclassOf<UTargetableWidget> AutoAimTargetWidget;

    UPROPERTY(Category = "Aiming")
	bool bLineTraceAim = false;

	UPROPERTY(Category = "Reloading")
    float ReloadTime = 0.35;

    UPROPERTY(Category = "Charging")
    float ChargeTime = 0.2;

	UPROPERTY(Category = "Charging")
    float MinimumCharge = 0.35;

	UPROPERTY(Category = "Charging")
	float MinimumChargeForAutoAim = 0.75;

    UPROPERTY(Category = "Charging")
	TSubclassOf<UCameraShakeBase> ChargeCameraShake;

    UPROPERTY(Category = "Charging")
	UForceFeedbackEffect ChargeForceFeedback;

	UPROPERTY(Category = "Charging")
	UForceFeedbackEffect FullyChargedForceFeedback;
    
    UPROPERTY(Category = "Launching")
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

    UPROPERTY(Category = "Launching")
	UForceFeedbackEffect LaunchForceFeedback;

    UPROPERTY(Category = "Animation")
    float ShootAnimDuration = 0.2;
}

namespace Sketchbook::Bow
{
    const FName DebugCategory = n"SketchbookBow";
    const FName TargetableCategory = n"SketchbookBow";

    const FName BowAttachSocket = n"Backpack";

    const FName AimAction = ActionNames::WeaponAim;
    const FName ShootAction = ActionNames::WeaponFire;

    const float DefaultAutoAimDistance = 5000.0;
    const float MaxShootDistance = 10000.0;

	// Tags
	const FName SketchbookBow = n"SketchbookBow";
	const FName Feature = n"SketchbookBow";
}