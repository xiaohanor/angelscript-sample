enum ECenterViewPitch
{
	Zero,
	SlightDown,
	KeepPitch,
};

enum ECenterViewPitchClamp
{
	DontClamp,
	ClampBoth,
	ClampOnlyUpWhenGrounded,
};

enum ECenterViewLockViewTarget
{
	// Never lock to the center view target, only center once.
	NoLock,

	// Keep view target centered while holding.
	Hold,

	// Toggle target centering when tapped. Release on stick input.
	Toggle,
};

class UCenterViewSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Settings")
	float TurnDuration = 0.5;

	/**
	 * If the key is pressed after this time, allow resetting the centering.
	 * If set to 0, will basically allow spamming the button.
	 */
	UPROPERTY(Category = "Settings")
	float AllowResetDelay = 0.2;


	UPROPERTY(Category = "Forward|Pitch")
	ECenterViewPitch PitchHandling = ECenterViewPitch::KeepPitch;

	UPROPERTY(Category = "Forward|Pitch")
	ECenterViewPitchClamp PitchClamping = ECenterViewPitchClamp::ClampOnlyUpWhenGrounded;

	UPROPERTY(Category = "Forward|Pitch")
	FHazeRange PitchClamp = FHazeRange(-10, 20);

	UPROPERTY(Category = "Forward|Lock Control Rotation")
	float LockControlRotationDotMinimum = -0.9;

	UPROPERTY(Category = "Forward|Lock Control Rotation")
	float LockControlRotationDuration = 0.25;

	/**
	 * If true, we apply the pitch offset defined in CameraUserSettings
	 */
	UPROPERTY(Category = "Target")
	bool bApplyPitchOffset = true;

	/**
	 * How do we want to lock to the target?
	 * @see ECenterViewLockViewTarget
	 */
	UPROPERTY(Category = "Target")
	ECenterViewLockViewTarget LockViewTarget = ECenterViewLockViewTarget::Hold;

	/**
	 * Tap and Hold locking can optionally set a minimum duration, to not make the transition out of the lock too harsh.
	 */
	UPROPERTY(Category = "Target")
	float MinimumLockOnDuration = 0.0;

	UPROPERTY(Category = "Target")
	bool bDisengageIfReleaseAfterHoldDuringToggle = false;

	UPROPERTY(Category = "Target")
	bool bDisengageFromCameraInput = true;

	/**
	 * To prevent jerkiness, we don't allow disengaging via input until after a delay.
	 */
	UPROPERTY(Category = "Target")
	float DisengageFromInputDelay = 0.3;
};

namespace CameraTags
{
	// Covers the entire CenterView system (targeting and rotation).
	const FName CenterView = CapabilityTags::CenterView;

	// Only covers the CenterView rotation, not targeting. I.e target locks will not be lost.
	const FName CenterViewRotation = n"CenterViewRotation";

	// Only covers the CenterView that looks forward.
	const FName CenterViewForward = n"CenterViewForward";

	// Only covers the CenterView that looks towards a target. Both target lock and 
	const FName CenterViewTarget = n"CenterViewTarget";
}