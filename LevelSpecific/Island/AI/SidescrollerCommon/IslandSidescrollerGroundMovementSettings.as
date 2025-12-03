class UIslandSidescrollerGroundMovementSettings : UHazeComposableSettings
{
	// If true, we try to find the nearest constrain volume for restricting movement along sidescroller spline.
    UPROPERTY(Category = "Movement|ConstrainedMovement")
	bool bUseConstrainVolume = true;

	UPROPERTY(Category = "Movement")
	bool bShouldActivateMovementCapability = true;
}
