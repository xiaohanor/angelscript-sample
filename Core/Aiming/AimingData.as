enum EAimingMode
{
	Free3DAim,
	Directional2DAim,
	Cursor2DAim,
};

struct FAimingSettings
{
	// Render a crosshair widget to the screen while aiming
	UPROPERTY(Category = "Visuals")
	bool bShowCrosshair = false;

	// Whether to place the crosshair at the auto-aimed target, or keep it at the original aiming ray
	UPROPERTY(Category = "Visuals", Meta = (EditCondition = "bShowCrosshair", EditConditionHides))
	bool bCrosshairFollowsTarget = false;

	// Override which crosshair widget to use. If not set, use the default crosshair.
	UPROPERTY(Category = "Visuals", Meta = (EditCondition = "bShowCrosshair", EditConditionHides))
	TSubclassOf<UCrosshairWidget> OverrideCrosshairWidget;

	// Settings to use for the crosshair when in 2D mode
	UPROPERTY(Category = "Visuals", Meta = (EditCondition = "bShowCrosshair", EditConditionHides))
	FAiming2DCrosshairSettings Crosshair2DSettings;

	// When stopping this aiming, how long the crosshair widget lingers before fading away
	UPROPERTY(Category = "Visuals", Meta = (EditCondition = "bShowCrosshair", EditConditionHides))
	float CrosshairLingerDuration = 0.0;

	// Whether to use auto-aim assist
	UPROPERTY(Category = "Auto Aim")
	bool bUseAutoAim = true;

	// Specify a targetable type to use for auto-aim purposes. If not set, use any auto aim target.
	UPROPERTY(Category = "Auto Aim")
	TSubclassOf<UTargetableComponent> OverrideAutoAimTarget;

	// Whether to use aiming mode sensitivity for the camera while this aiming is active
	UPROPERTY(Category = "Camera")
	bool bApplyAimingSensitivity = true;

	// While aiming, we might want to not pitch the camera as far down, since then the crosshair will point into the ground.
	UPROPERTY(Category = "Camera")
	bool bOverrideSnapOffsetPitch = false;

	UPROPERTY(Category = "Camera", Meta = (EditCondition = "bOverrideSnapOffsetPitch"))
	float SnapOffsetPitch = -5;
};

struct FAiming2DCrosshairSettings
{
	// Crosshair offset towards aim direction
	UPROPERTY(Category = "Crosshair")
	float CrosshairOffset2D = 110.0;

	// Offset of the aiming circle relative to the player's center
	UPROPERTY(Category = "Crosshair")
	FVector DirectionOffset(0.0, 0.0, 50.0);

	// Size of the directional aim arrow
	UPROPERTY(Category = "Crosshair")
	float DirectionalArrowSize = 30.0;

	// Whether to fade out the directional arrow after not giving aim input for a while
	UPROPERTY(Category = "Crosshair")
	bool bAutoFadeOut = true;
};

struct FAimingResult
{
	// Original Ray that we used to trace the aim for, may have a different direction from the final direction
	UPROPERTY()
	FAimingRay Ray;

	// Origin of the line we're aiming in
	UPROPERTY()
	FVector AimOrigin;

	// Direction that we are aiming in
	UPROPERTY()
	FVector AimDirection;

	// Targetable component that we are auto-aiming to
	UPROPERTY()
	USceneComponent AutoAimTarget = nullptr;

	// When auto-aiming the world position we auto-aimed to, will not be set if AutoAimTarget is nullptr
	UPROPERTY()
	FVector AutoAimTargetPoint;
};

struct FAimingRay
{
	// Whether we're aiming in 2D or 3D
	UPROPERTY()
	EAimingMode AimingMode = EAimingMode::Free3DAim;

	// Origin of the line we're aiming in
	UPROPERTY()
	FVector Origin;

	// Direction that we are aiming in
	UPROPERTY()
	FVector Direction;

	// Cursor position if the aiming mode is cursor, relative to the player viewport
	UPROPERTY()
	FVector2D CursorPosition;

	// Normal of the aiming constraint plane if the aiming mode is 2D
	UPROPERTY()
	FVector ConstraintPlaneNormal;

	// Whether the player is currently giving aim input or not
	UPROPERTY()
	bool bIsGivingAimInput = true;

	// Whether this ray has a constraint plane active or not
	bool HasConstraintPlane() const
	{
		return AimingMode != EAimingMode::Free3DAim && !ConstraintPlaneNormal.IsNearlyZero();
	}
};

enum EAimingConstraintType2D
{
	None,
	Plane,
	Spline,
	CameraPlane,
}

struct FAimingConstraint2D
{
	UPROPERTY()
	EAimingConstraintType2D Type = EAimingConstraintType2D::None;
	UPROPERTY()
	FVector Normal;
	UPROPERTY()
	UHazeSplineComponent SplineComponent;
}