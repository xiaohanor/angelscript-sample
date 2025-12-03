class UEnforcerJetpackSettings : UHazeComposableSettings
{
	// Wait at least this long before using another jetpack ability (min)
	UPROPERTY(Category = "Jetpack|Default")
	float CommonCooldownMin = 2.5;

	// Wait at least this long before using another jetpack ability (max)
	UPROPERTY(Category = "Jetpack|Default")
	float CommonCooldownMax = 3.5;

	// Wait this long before initiating a retreat
	UPROPERTY(Category = "Jetpack|Retreat")
	float RetreatWaitDuration = 0.5;

	// Wait this long before retreating again
	UPROPERTY(Category = "Jetpack|Retreat")
	float RetreatCooldownDuration = 2.0;

	// Attempt retreat at this distance to enemies
	UPROPERTY(Category = "Jetpack|Retreat")
	float RetreatTriggerDistance = 500.0;

	// Desired retreat distance
	UPROPERTY(Category = "Jetpack|Retreat")
	float RetreatDistance = 1000.0;

	// How high we leap when jetpack retreating
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float RetreatHeight = 200.0;

	// How long should we try to retreat?
	UPROPERTY(Category = "Jetpack|Retreat")
	float RetreatLeapDuration = 0.7;

	// Duration of recovery when landing
	UPROPERTY(Category = "Jetpack|Retreat")
	float RetreatLandDuration = 0.7;

	UPROPERTY(Category = "Jetpack|Retreat", meta = (ClampMin = "0", ClampMax = "90"))
	float RetreatMaxAngle = 90.0;

	// Duration of retreat startup
	UPROPERTY(Category = "Jetpack|Retreat")
	float RetreatStartDuration = 0.5;



	// Wait this long before jetpack chasing again
	UPROPERTY(Category = "Jetpack|Chase")
	float ChaseCooldownDuration = 3.0;

	// Jetpack chase minimum distance
	UPROPERTY(Category = "Jetpack|Chase")
	float ChaseTriggerMinDistance = 2000.0;

	// Desired jetpack chase distance
	UPROPERTY(Category = "Jetpack|Chase")
	float ChaseDistance = 1000.0;

	// How high we leap when jetpack chasing
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float ChaseHeight = 200.0;

	// How long should we try to jetpack chase?
	UPROPERTY(Category = "Jetpack|Chase")
	float ChaseLeapDuration = 5.7;

	// Duration of recovery when landing after a jetpack chase
	UPROPERTY(Category = "Jetpack|Chase")
	float ChaseLandDuration = 0.8;

	// Duration of jetpack chase startup
	UPROPERTY(Category = "Jetpack|Chase")
	float ChaseStartDuration = 0.5;



	// Min duration of jetpack circle strafe
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float CircleStrafeMinLeapDuration = 0.5;

	// Max duration of jetpack circle strafe
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float CircleStrafeMaxLeapDuration = 0.7;

	// Min cooldown of jetpack circle strafe
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float CircleStrafeMinCooldownDuration = 10.0;

	// Max cooldown of jetpack circle strafe
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float CircleStrafeMaxCooldownDuration = 15.0;

	// How far jetpack circle strafe leap takes us
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float CircleStrafeDistance = 1000.0;

	// How high we leap when jetpack strafing
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float CircleStrafeHeight = 40.0;

	// Duration of jetpack circle strafe startup
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float CircleStrafeStartDuration = 0.5;

	// Duration of jetpack circle strafe landing recovery
	UPROPERTY(Category = "Jetpack|CircleStrafe")
	float CircleStrafeLandDuration = 0.8;


	UPROPERTY(Category = "Jetpack|TraverseToScenepointEntrance")
	float TraverseToScenepointMoveSpeed = 1200.0;

	// Duration of landing when traversing to entrance scenepoint
	UPROPERTY(Category = "Jetpack|TraverseToScenepointEntrance")
	float TraverseToScenepointEntranceLandDuration = 0.8;

	UPROPERTY(Category = "Jetpack|TraverseToScenepointEntrance")
	float TraverseToScenepointLaunchTangentLength = 2000.0;

	UPROPERTY(Category = "Jetpack|TraverseToScenepointEntrance")
	float TraverseToScenepointLandTangentLength = 2000.0;

	UPROPERTY(Category = "Jetpack|TraverseToScenepointEntrance")
	float TraverseToScenepointLaunchPitch = 45.0;

	UPROPERTY(Category = "Jetpack|TraverseToScenepointEntrance")
	float TraverseToScenepointLandPitch = 45.0;
}
