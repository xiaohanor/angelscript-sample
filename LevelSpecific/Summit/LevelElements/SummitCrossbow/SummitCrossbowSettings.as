class USummitCrossbowSettings : UHazeComposableSettings
{
	// Maximum distance to pull
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float PullMaxDistance = 900.0;

	// How fast does the basket move back?
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float BasketPullBackSpeed = 230.0;

	// How fast does the basket move forward?
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float BasketPullForwardSpeed = 500.0;

	// Strength of the basket spring
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	float BasketSpringStrength = 50.0;

	// How much we launch the acid dragon
	UPROPERTY(EditAnywhere, Category = "Slingshot")
	FVector LaunchImpulse(6000.0, 0.0, 4000.0);

	// Time axle ; 0 - 1 how much it's pulled
	// Value axle ; 0 - 1 how much resistance percentage wise it is to pull it  
	UPROPERTY()
	FRuntimeFloatCurve PullResistance;
	default PullResistance.AddDefaultKey(0, 0.0);
	default PullResistance.AddDefaultKey(0.5, 0.0);
	default PullResistance.AddDefaultKey(1.0, 0.5);

	// CAMERA

	UPROPERTY()
	float CameraBlendInTime = 2.0;

	UPROPERTY()
	float CameraBlendOutTime = 2.0;
	
	// EXIT
	// FOR ANIMATION PURPOSES
	
	// Duration before control is given back to the player after exiting the interaction
	UPROPERTY()
	float NormalExitDuration = 0.5;

	// Threshold at which it is considered a long pull exit 
	UPROPERTY()
	float LongExitFractionThreshold = 0.5;

	// Duration before control is given back to the player after exiting the interaction when the pulley is pulled over the threshold
	UPROPERTY()
	float LongExitDuration = 1.0;
}