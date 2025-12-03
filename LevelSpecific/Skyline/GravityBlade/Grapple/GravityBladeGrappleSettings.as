class UGravityBladeGrappleSettings : UHazeComposableSettings
{
	UPROPERTY()
	bool bShowCrosshair = true;
	UPROPERTY()
	bool bApplyAimingSensitivity = false;
	UPROPERTY()
	bool bUse2DTargeting = false;
}

namespace GravityBladeGrapple
{
	const FName TargetableCategory = n"GravityBladeGrapple";

	const float VisibleRange = 3500.0;
	const float Range = 2900.0; // 2500.0 - TEMP Should this be on target comp?
	const float MaxAngleDeviation = 45.0;
	const float ThrowSpeed = 9000.0;
	const float PullSpeed = 1800.0;
	const float PullDelay = 0.2;
	const float LandDuration = 0.1;
	
	// Ensures the camera doesn't move too fast regardless of actual travel duration.
	const float MinCameraInterpDuration = 0.0;
	// Pullback distance when grounding the player on a surface.
	const float PullbackDistance = 50;
	// Height of step-down done when grounding the player on a surface.
	const float StepDownHeight = 100.0;
	// How far we trace from the player downwards when looking for a surface to align to.
	 const float AlignSurfaceTraceRange = 600.0;

	 namespace Eject
	 {
		const FName Instigator = n"GravityBladeGrappleEjectInstigator";

		const float MinimumTimeDilation = 0.5;
		const float MinimumGravityScale = 0.1;
	 }
}

namespace GravityBladeGrappleTags
{
	const FName GravityBladeGrapple = n"GravityBladeGrapple";

	const FName GravityBladeGrappleAim = n"GravityBladeGrappleAim";
	const FName GravityBladeGrappleCamera = n"GravityBladeGrappleCamera";
	const FName GravityBladeGrappleGrapple = n"GravityBladeGrappleGrapple";
	const FName GravityBladeGrappleLand = n"GravityBladeGrappleLand";
	const FName GravityBladeGrapplePull = n"GravityBladeGrapplePull";
	const FName GravityBladeGrappleThrow = n"GravityBladeGrappleThrow";
	const FName GravityBladeGrappleTransition = n"GravityBladeGrappleTransition";
	const FName GravityBladeGrappleGravityAlign = n"GravityBladeGrappleGravityAlign";
	const FName GravityBladeGrappleEject = n"GravityBladeGrappleEject";
}