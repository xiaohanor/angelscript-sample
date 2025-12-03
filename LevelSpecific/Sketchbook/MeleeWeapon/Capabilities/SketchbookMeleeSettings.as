class USketchbookMeleeWeaponSettings : UHazeComposableSettings
{
	UPROPERTY()
	float Radius = 500;

	UPROPERTY()
	ULocomotionFeatureSketchbookMelee Feature;

	UPROPERTY()
	UForceFeedbackEffect HitForceFeedback;
}

namespace Sketchbook::Melee
{
	const FName DebugCategory = n"SketchbookMelee";
    const FName TargetableCategory = n"SketchbookMelee";

    const FName MeleeAttachSocket = n"RightAttach";

    const FName Attack = ActionNames::WeaponFire;

	// Tags
	const FName SketchbookMelee = n"SketchbookMelee";
	const FName Feature = n"SketchbookMelee";
}