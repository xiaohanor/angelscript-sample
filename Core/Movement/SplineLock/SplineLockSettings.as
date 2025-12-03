enum EPlayerSplineLockPlaneType
{
	/** This will lock the player to the closest horizontal spline location
	 * so the player can still jump and apply gravity.
	 */
	Horizontal,

	/** This will lock the player unto the splines right vector plane
	 * It will be able to jump and deviate but you have to make sure that the splines
	 * forward and right vector are correctly positioned
	 */
	SplinePlane,

	/**
	 * Same as Spline Plane, but we allow moving within the AllowedHorizontalDeviation.
	 */
	SplinePlaneAllowMovingWithinHorizontalDeviation,
};

enum ESplineLockKeepDeltaSize
{
	KeepDeltaSizeWhenMovementInputIsRedirected,
	KeepDeltaSizeAlways,
	DontKeepDeltaSize
};

struct FPlayerMovementSplineLockProperties
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	EPlayerSplineLockPlaneType LockType = EPlayerSplineLockPlaneType::Horizontal;

	/** If true, the player will go back to normal movement if end of spline is reached. */
	UPROPERTY(Category = "Settings")
	bool bCanLeaveSplineAtEnd = true;

	/** How much can the player deviate from the spline on the horizontal plane */
	UPROPERTY(Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float AllowedHorizontalDeviation = 0.0;

	/** If true, we can only give input along the spline,
	 * else we give normal input but are still locked to the spline
	 */
	UPROPERTY(Category = "Settings")
	bool bRedirectMovementInput = true;

	/*
	 * When we redirect movement to follow the spline, do we want to keep the size or allow it to shrink?
	 * Keeping the delta size when redirecting can cause excessive velocity if we are actively trying to move away from the spline.
	 * KeepDeltaSizeWhenMovementInputIsRedirected: Keep delta if bRedirectMovementInput is true.
	 * KeepDeltaSizeAlways: Always keep the delta.
	 * DontKeepDeltaSize: Allow redirecting to simply project the delta onto the plane, resulting in the delta often being smaller than it initially was.
	 */
	UPROPERTY(Category = "Settings")
	ESplineLockKeepDeltaSize KeepDeltaSize = ESplineLockKeepDeltaSize::KeepDeltaSizeWhenMovementInputIsRedirected;

	/** If true, the initial velocity will be cleared if not along the spline */
	UPROPERTY(Category = "Settings")
	bool bConstrainInitialVelocityAlongSpline = false;
	
	/**
	 * Whether position crumbs while the player is locked should be synced relative to the spline.
	 */
	bool bSyncPositionCrumbsRelativeToSpline = false;
};

enum EPlayerSplineLockEnterType
{
	Snap,
	SnapAtTheBeginningOfMovement,
	SmoothLerp,
	MoveInto,
};

struct FPlayerSplineLockSettings
{
	UHazeSplineComponent Spline;
	FPlayerMovementSplineLockProperties LockSettings;
	UPlayerSplineLockRubberBandSettings RubberBandSettings;
	UPlayerSplineLockEnterSettings EnterSettings;
}

class UPlayerSplineLockRubberBandSettings : UDataAsset
{
	// How far and close we should use the min and max values
	UPROPERTY()
	FHazeRange Ranges;

	/** How much we change the speed depending on the distance to the other player
	 * Player ahead; At max distance, min speed is used and vice versa
	 * Player behind; At max distance, the max speed is used and vice versa
	 */
	UPROPERTY()
	FHazeRange SpeedMultipliers;
};

class UPlayerSplineLockEnterSettings : UDataAsset
{
	UPROPERTY()
	EPlayerSplineLockEnterType EnterType = EPlayerSplineLockEnterType::MoveInto;

	/**
	 * How fast we will smooth lerp the mesh
	 */
	UPROPERTY(meta = (EditCondition="EnterType == EPlayerSplineLockEnterType::SmoothLerp", ClampMin = "0.01"))
	float EnterSmoothLerpDuration = 0.1;

	/**
	 * How far ahead on the spline we will align movement direction with 
	 * making the enter not move so quickly towards the spline
	*/
	UPROPERTY(meta = (EditCondition="EnterType == EPlayerSplineLockEnterType::MoveInto", ClampMin = "0.0"))
	float MoveIntoSmoothnessDistance = 300.0;
};