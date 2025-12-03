class USkylineSentryDroneSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Sentry Drone Settings")
	EGravityWhipGrabMode GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(Category = "Sentry Drone Settings")
	bool bContextualMoves = true;

	UPROPERTY(Category = "Sentry Drone Settings")
	bool bContextualMovesWhenSlinged = false;

	UPROPERTY(Category = "Sentry Drone Settings")
	bool bContextualMovesWhenDragged = false;

	// Hover Settings
	UPROPERTY(Category = "Hover")
	float HoverForceScale = 1.0;

	UPROPERTY(Category = "Hover")
	float HoverDrag = 1.0;

	UPROPERTY(Category = "Hover")
	float HoverTorqueScale = 1.0;

	UPROPERTY(Category = "Hover")
	float HoverAngularDrag = 1.0;

	// MoveTo Target Settings
	UPROPERTY(Category = "MoveTo")
	float MoveToMaxAcceleration = 800.0;

	UPROPERTY(Category = "MoveTo")
	float MoveToForceScale = 4.0;

	UPROPERTY(Category = "MoveTo")
	float MoveToDrag = 2.0;

	UPROPERTY(Category = "MoveTo")
	float MoveToTorqueScale = 30.0;

	UPROPERTY(Category = "MoveTo")
	float MoveToAngularDrag = 4.0;

	// LookAt Target Settings
	UPROPERTY(Category = "LookAt")
	float LookAtTorqueScale = 30.0;

	UPROPERTY(Category = "LookAt")
	float LookAtAngularDrag = 8.0;

	// Spline Follow Settings
	UPROPERTY(Category = "SplineFollow")
	float SplineFollowSpeed = 300.0;

	// GravityWhip Drag Mode Settings
	UPROPERTY(Category = "GravityWhipDragMode")
	float DragModeForceScale = 1.0;

	UPROPERTY(Category = "GravityWhipDragMode")
	float DragModeDrag = 4.0;

	UPROPERTY(Category = "GravityWhipDragMode")
	float DragModeTorqueScale = 30.0;

	UPROPERTY(Category = "GravityWhipDragMode")
	float DragModeAngularDrag = 4.0;

	// GravityWhip Sling Mode Settings
	UPROPERTY(Category = "GravityWhipSlingMode")
	float SlingModeThrowSpeed = 4000.0;

	UPROPERTY(Category = "GravityWhipSlingMode")
	float SlingModeForceScale = 2.0;

	UPROPERTY(Category = "GravityWhipSlingMode")
	float SlingModeDrag = 8.0;

	UPROPERTY(Category = "GravityWhipSlingMode")
	float SlingModeTorqueScale = 50.0;

	UPROPERTY(Category = "GravityWhipSlingMode")
	float SlingModeAngularDrag = 8.0;

	// Falling Settings
	UPROPERTY(Category = "Falling")
	float FallingTimeBeforeStabilization = 1.0;

	UPROPERTY(Category = "Falling")
	float FallingGravity = 2940.0;

	UPROPERTY(Category = "Falling")
	float FallingDrag = 0.2;

	UPROPERTY(Category = "Falling")
	float FallingAngularDrag = 2.0;

	// Impact Settings
	UPROPERTY(Category = "Impact")
	float ImpactRestitution = 0.6;

	UPROPERTY(Category = "Impact")
	float ImpactAngularSpeed = 0.01;

	UPROPERTY(Category = "Impact")
	bool bExplodeOnImpact = false;

	// Stabilize Settings
	UPROPERTY(Category = "Stabilize")
	float StabilizeTime = 2.0;

	UPROPERTY(Category = "Stabilize")
	float StabilizeMaxAcceleration = 800.0;

	UPROPERTY(Category = "Stabilize")
	float StabilizeForceScale = 1.0;

	UPROPERTY(Category = "Stabilize")
	float StabilizeDrag = 1.0;

	UPROPERTY(Category = "Stabilize")
	float StabilizeTorqueScale = 50.0;

	UPROPERTY(Category = "Stabilize")
	float StabilizeAngularDrag = 4.0;
}