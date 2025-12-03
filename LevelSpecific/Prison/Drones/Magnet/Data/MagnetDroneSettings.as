class UMagnetDroneSettings : UHazeComposableSettings
{
	// FB TODO: Replace with TopDown/SideScroller modes
	UPROPERTY(Category = "Aiming")
	bool bUse2DTargeting = false;

	UPROPERTY(Category = "Aiming")
    FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = false;
	default AimSettings.OverrideAutoAimTarget = UMagnetDroneAutoAimComponent;
	default AimSettings.bCrosshairFollowsTarget = true;
	default AimSettings.bApplyAimingSensitivity = false;

	UPROPERTY(Category = "Attraction")
	float AttractionStartVerticalImpulse = 0;

	/**
	 * If no magnetic target was found, but the player is currently on a magnetic surface, should we attach?
	 */
	UPROPERTY(Category = "Attraction")
	bool bAttachToGroundIfNoTargetFound = true;

	UPROPERTY(Category = "Attraction")
	float AttractionFailMaxSpeed = 400;

	UPROPERTY(Category = "Attraction|Input")
	bool bAllowHoldingInput = true;

	/**
	 * If we are currently not targeting anything, and not on a magnetic surface, but there is a magnetic surface close to us, should we attract towards it?
	 */
	UPROPERTY(Category = "Attraction|Closest Surface")
	bool bAttachToClosestSurfaceIfNoTargetAndNoGround = true;

	UPROPERTY(Category = "Attraction|Closest Surface")
	float ClosestSurfaceOverlapRadius = 200;

	UPROPERTY(Category = "Attraction|Jump")
	bool bAttractWhenJumpingFromMagneticSurfaces = true;

	UPROPERTY(Category = "Attraction|Jump")
	float AttractWhenJumpingFromMagneticSurfacesDistance = 700;

	UPROPERTY(Category = "Surface")
	bool bOnlyAlignWithMagneticContacts = true;

	UPROPERTY(Category = "Surface|Movement")
	bool bUseGroundStickynessWhileAttached = true;

	UPROPERTY(Category = "Surface|Movement")
	float Acceleration = 7000;

	UPROPERTY(Category = "Surface|Movement")
	float Deceleration = 3000;

	UPROPERTY(Category = "Surface|Movement")
	float MaxHorizontalSpeed = 600;

	UPROPERTY(Category = "Surface|Movement")
	float MaxSpeedDeceleration = 2000;

	UPROPERTY(Category = "Surface|Movement")
	float ReboundMultiplier = 1.5;

	UPROPERTY(Category = "Surface|Dashing")
	float DashMaximumSpeed = 700.0;

	UPROPERTY(Category = "Surface|Dashing")
	float DashInputBufferWindow = 0.08;

	UPROPERTY(Category = "Surface|Dashing")
	float DashCooldown = 0.2;

	UPROPERTY(Category = "Surface|Dashing")
	float DashDuration = 0.2;

	UPROPERTY(Category = "Surface|Dashing")
	float DashExitSpeed = 2000.0;

	UPROPERTY(Category = "Surface|Dashing")
	float DashSprintExitBoost = 50.0;

	UPROPERTY(Category = "Surface|Dashing")
	float DashEnterSpeed = 1000.0;

	UPROPERTY(Category = "Surface|Dashing")
	float DashTurnDuration = 0.75;

	UPROPERTY(Category = "Detaching")
	bool bAlignWithNonMagneticFlatGround = true;

	UPROPERTY(Category = "Detaching")
	float AlignWithNonMagneticFlatGroundAngleThreshold = 45.0;

	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset CamSettings_Default;

	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset CamSettings_Attached;

	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset CamSettings_ChainJump;

	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset CamSettings_AttractionStarted;

	UPROPERTY(Category = "Camera")
	float AttractionFOV = 110;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> ShakeClass_Attached;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> ShakeClass_Detached;

	UPROPERTY(Category = "Roll|Straighten")
	float StartStraighteningSpeed = 100.0;

	UPROPERTY(Category = "Roll|Straighten")
	float RollStraightenDuration = 1.0;

	UPROPERTY(Category = "Roll|Straighten")
	float DashRollStraightenDuration = 0.5;

	UPROPERTY(Category = "Roll|Straighten")
	bool bStraightenWhileAirborne = true;

	UPROPERTY(Category = "Roll|Straighten")
	bool bStraightenWhileAttracting = false;

	UPROPERTY(Category = "Jumping")
	bool bAllowJumpingWhileMagneticallyAttached = true;

	UPROPERTY(Category = "Jumping")
	bool bAllowChainingMagneticSurfacesWhileJumping = true;
};
	
namespace MagnetDrone
{
	const float Radius = 39;

	/*
	 * Input
	 */

	const FName MagnetInput = ActionNames::PrimaryLevelAbility;
	const float StopFlipInputThreshold = 0.99;	// A smaller value makes the needed change from the previous frame bigger to stop the flip

	/*
	 * Targeting
	 */

	// will trace in the looking direction with this distance
	const float MaxTargetableDistance_Aim = 2000.0;

	// will trace in the looking direction with this distance
	const float VisibleDistanceExtra_Aim = 1000.0;

	float GetMaxVisibleDistance()
	{
		return MaxTargetableDistance_Aim + VisibleDistanceExtra_Aim;
	}

	// will trace in the looking direction with this distance
	const float VisibleDistance_2D = 1000.0;

	// Not compatible with bRequireClearFromPlayerToPotentialTarget
	const bool bPrioritizeClearFromPlayerToPotentialTarget = false;

	const bool bDeprioritizePreviousAttachment = false;

	// When we detach from something, how long should we deprioritize that target for?
	const float DetachDeprioritizeDuration = 1.0;

	/**
	 * Attraction
	 */

	// speed used to predict when we reach our target while 'attracting' towards a magnetic surface
	const float AttractionSpeed = 3000.0;

	/**
	 * Jump Attract
	 */

	const float JumpAttractBufferTime = 0.3;

	/**
	 * Attaching
	 */

	 const float AttachDistanceThreshold = 10;

	/**
	 * While attracting towards a target, if we hit a surface, what
	 * angle should make us completely stop or slide?
	 * If the angle is smaller than this value, we slide.
	 */
	const float SlideAngleThreshold = 45.0;

	/*
	 * Attached
	 */

	// how far out the camera should be offset along the surface normal while 'attached'
	const float PushOutCameraDistance = 150.0;

	const float MagnetGroundTraceDistance = 1.0;

	const float MagnetGroundTraceDistanceCantFallOff = 2.0;

	const float MagnetCameraClampAngle = 85.0;

	const float MagnetDistanceFromPlayerWeight = 1.0;
	const float MagnetDistanceFromAimLineWeight = 10.0;

	const bool ValidateMagneticZoneWorldUp = true;

	/**
	 * Detached
	 */
	const float DetachImpulse = 100;

	// Actor Rotation
	const float RotateSpeed = 10.0;

	// Camera
	const float DefaultAlignCameraWithSurfaceDuration = 1.0;

	// Tick Groups
	const EHazeTickGroup StartAttractTickGroup = EHazeTickGroup::BeforeMovement;
	const int StartAttractTickGroupOrder = 110;

	const EHazeTickGroup AttractionTickGroup = EHazeTickGroup::BeforeMovement;
	const int AttractionTickGroupOrder = 120;

	const EHazeTickGroup AttachToTickGroup = EHazeTickGroup::BeforeMovement;
	const int AttachToTickGroupOrder = 130;

	/**
	 * Experimental mode where we don't have a crosshair, and it instead "just works"
	 */
	namespace NextGenAiming
	{
		const bool bAimOmniDirectional = true;
		const bool bIgnoreAutoAimAngle = true;
		const bool bOnlyValidIfOnScreen = true;
	}

	/**
		* Attraction Modes is a new way of making movement while attracting.
		* It enables easier customization based on when we start the attraction,
		* and what our target is.
		*/
	namespace AttractionModes
	{
		/**
		 * The preview can be pretty jittery from small input changes.
		 * Should we smooth it out by moving a second spline towards the actual spline?
		 */
		const bool bPreviewAttractionSmoothing = true;

#if EDITOR
		const bool bDebugDrawPreviewSpline = false;
		const bool bDebugDrawInterpolatedSpline = true;
#endif
	}
};