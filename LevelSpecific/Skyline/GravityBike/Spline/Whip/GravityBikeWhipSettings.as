enum EGravityBikeWhipWidgetInterpMode
{
	Accelerate,
	Interp,
	InterpConstantTo,
	Snap,
}

// If you add a category here, add a case in GetGravityBikeWhipGrabCategoryPriority too!
enum EGravityBikeWhipGrabCategory
{
	Generic,
	Missile,
	TurretDrone,
	UseClass,
};

// Higher returned values means higher prio
// 0 is invalid, so 1 is the lowest prio
int GetGravityBikeWhipGrabCategoryPriority(EGravityBikeWhipGrabCategory Category)
{
	switch(Category)
	{
		case EGravityBikeWhipGrabCategory::Generic:
			return 1;

		case EGravityBikeWhipGrabCategory::UseClass:
			return 1;

		case EGravityBikeWhipGrabCategory::Missile:
			return 20;

		case EGravityBikeWhipGrabCategory::TurretDrone:
			return 10;
	}
}

namespace GravityBikeWhip
{
	const FName GrabInput = ActionNames::PrimaryLevelAbility;

	// Grab Targeting
	const float StartGrabDecelerateSpeed = 0;
	const float PullAccelerateDuration = 0.5;
	const float LassoAccelerateDuration = 2.0;
	const float ThrowReboundAccelerateDuration = 0.0;
	const float ThrowAccelerateDuration = 0.1;

	// Multi grab
	const float MultiGrabSpinSpeed = 4;
	const float MultiGrabDistance = 50;
	const float MultiGrabOffsetAccelerationDuration = 1;

	const FName TargetableCategoryGrab = n"GravityBikeWhipGrab";
	const FName TargetableCategoryThrow = n"GravityBikeWhipThrow";

	// Throw Targeting
	const float ThrowTargetBufferTime = 0.75;

	// Snapping
	const float SnapThreshold = 0.5;
	const bool bUseSnapInterval = true;	// If true, we will snap to a new target after SnapInterval time, even if input is unchanged
	const float SnapInterval = 0.2;
	const float SnapDeadzone = 0.3;

	const float TargetVisibleRange = 8000.0;
	const float TargetTargetableRange = 8000.0;
	const float TargetIsMainMultiplier = 1.0; // If we want the main target to stay as the main target, we can apply a score multiplier here

	const bool bUseAimBox = false;
	const float AimBoxCenterWidth = 1;
	const float AimBoxSideWidth = 1;

	const bool bDrawAimBox = false;
	const float AimBoxScale = 0.068;	// Adjust until the height of the drawn box matches the screen height...

	const bool bDrawWhipState = false;

	// Crosshair
	const float InputAngleThreshold = 45;
	const float NoInputScreenspaceDistanceThreshold = 0.3;
	const bool bSnapCrosshairToTarget = true;

	// SideScroller
	const FVector SideScrollerOffset = FVector(0, 0, -40);
	const float SideScrollerArrowDistance = 120;

	// Throwing
	const bool bIntervalBetweenThrows = true;
	const float IntervalBetweenThrows = 0.2;

	AHazePlayerCharacter GetPlayer()
	{
		return Game::Zoe;
	}

	UGravityBikeWhipComponent GetWhipComponent()
	{
		return UGravityBikeWhipComponent::Get(GetPlayer());
	}
}