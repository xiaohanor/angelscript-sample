class UIslandTrajectoryTraversalScenepointComponent : UTrajectoryTraversalScenepoint
{
	// Overrides the traversal method's default arc height if value is non-negative.
	UPROPERTY(EditInstanceOnly, Category="Custom Trajectory Adjustments")
	float OverrideHeight = -1.0;
	
	// Overrides the traversal method's default gravity by multiplying it by this factor if value is non-negative.
	UPROPERTY(EditInstanceOnly, Category="Custom Trajectory Adjustments")
	float OverrideGravityFactor = -1.0;

	UPROPERTY(EditInstanceOnly, Category="Custom Trajectory Adjustments")
	bool bLimitToOnlyShortestLeap = false;

	// Used if value is non-negative.	
	UPROPERTY(EditInstanceOnly, Category="Custom Trajectory Adjustments")
	float MaxLeapDistance2D = -1.0;
};