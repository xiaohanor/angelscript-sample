class UCameraInheritMovementSettings : UHazeComposableSettings
{
	// Should the camera inherit movement when user has inherit movement active
	// (Like moving platforms)
	UPROPERTY()
	bool bInheritMovement = false;

	// The time it will take to reach the inherit movement velocity
	UPROPERTY()
	float InheritMovementAccelerationTime = 0.5;
};
