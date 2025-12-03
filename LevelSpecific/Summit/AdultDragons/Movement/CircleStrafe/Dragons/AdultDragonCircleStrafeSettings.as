class UAdultDragonCircleStrafeSettings : UHazeComposableSettings
{
	/** How much the dragon is offset in front of the camera */
	UPROPERTY(Category = "Offset")
	float BaseForwardOffset = 4000.0;

	/** How much more the dragon is offset in front of the camera
	 * I separated them so it's easier to tweak the distance between the dragons seperately from the distance in front of the camera */
	UPROPERTY(Category = "Offset")
	float AdditionalForwardOffset = 0.0;

	/** How smooth the dragon goes towards the offset. */
	UPROPERTY(Category = "Offset")
	float OffsetAccelerationDuration = 0.5;
	
	/** How fast the dragon gets offset in either direction with input. */
	UPROPERTY(Category = "Offset")
	float OffsetSpeed = 3000.0;

	UPROPERTY(Category = "Offset")
	FVector2D OffsetBoundaryRadius = FVector2D(3500, 2500);
}