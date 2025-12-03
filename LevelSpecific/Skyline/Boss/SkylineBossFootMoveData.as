struct FSkylineBossFootMoveData
{
	USkylineBossLegComponent LegComponent;
	USkylineBossFootTargetComponent FootTarget;

	FHazeAcceleratedQuat AcceleratedRotation;

	FVector StartFootUpVector;
	FVector StartLocation;

	FVector PitchAxis;
	float StepTimeStamp;
}
