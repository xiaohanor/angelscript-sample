class UPlayerAimingSettings : UHazeComposableSettings
{
	// Offset in screen space that the aim has from the center
	UPROPERTY(Category = "Aim")
	FVector2D ScreenSpaceAimOffset;

	// How fast the aim interps to the current aiming ray in 2D when aiming with a gamepad.
	UPROPERTY(Category = "Aim")
	float AimingGamepad2DRayInterpSpeed = -1.0;

	// How fast the aim interps to the current aiming ray in 2D when aiming with a mouse cursor.
	UPROPERTY(Category = "Aim")
	float AimingCursor2DRayInterpSpeed = -1.0;

	// How long it will take for the crosshair to lerp to the target (this will only be used if the current FAimingSettings has bCrosshairFollowsTarget set to true)
	UPROPERTY(Category = "Crosshair Follows Target")
	float CrosshairLerpToTargetDuration = 0.2;

	// How long it will take for the crosshair to lerp back to the origin location on the screen (this will only be used if the current FAimingSettings has bCrosshairFollowsTarget set to true)
	UPROPERTY(Category = "Crosshair Follows Target")
	float CrosshairLerpToOriginDuration = 0.5;

	// If current crosshair location is this close to the lerp destination, it will snap (this will only be used if the current FAimingSettings has bCrosshairFollowsTarget set to true)
	UPROPERTY(Category = "Crosshair Follows Target")
	float CrosshairSnapToDestinationTolerance = 0.01;

	// If true, both left and right stick can be used
	UPROPERTY(Category = "Input")
	bool bGamepadAllowBothSticks = false;
}

namespace Aim2DSettings
{
	const FConsoleVariable CVar_UseSystemSensitivity("Haze.2DAim.UseSystemSensitivity", 1);
	const FConsoleVariable CVar_UseSystemCursor("Haze.2DAim.UseSystemCursor", 0);
	const FConsoleVariable CVar_SoftwareCursorSize("Haze.2DAim.SoftwareCursorSize", 20.0);
}

namespace AimSettings
{
	const FConsoleVariable CVar_ShowReticleDot_Mio("Haze.Aim.ShowReticleDot_Mio", 0);
	const FConsoleVariable CVar_ShowReticleDot_Zoe("Haze.Aim.ShowReticleDot_Zoe", 0);
}