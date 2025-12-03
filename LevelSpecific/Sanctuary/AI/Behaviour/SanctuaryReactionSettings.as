class USanctuaryReactionSettings : UHazeComposableSettings
{	
	UPROPERTY(Category = "DarkPortal")
	float DarkPortalPullSpeed = 1000.0;

	UPROPERTY(Category = "DarkPortal")
	float DarkPortalPullAccelerationDuration = 2.0;

	// Maximum grabbed targets (applies only to actors using DarkPortalReactionComponent)
	UPROPERTY(Category = "DarkPortal")
	int MaxGrabTargets = 3;

	// Maximum time we can be grabbed
	UPROPERTY(Category = "DarkPortal")
	float MaxGrabDuration = 5;

	// How long we are immune to grabbing after having been released or escaped
	UPROPERTY(Category = "DarkPortal")
	float ImmuneGrabDuration = 3;

	// With how much force do we escape once MaxGrabDuration expires
	UPROPERTY(Category = "DarkPortal")
	float EscapeForce = 2000;
}