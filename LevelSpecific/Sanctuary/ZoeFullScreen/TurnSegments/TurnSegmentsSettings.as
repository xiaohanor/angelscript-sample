class UTurnSegmentsSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "Range")
    float DistanceAhead = 500.0;

    UPROPERTY(Category = "Turning")
    float TurnSpeed = 400.0;

    UPROPERTY(Category = "Segment")
    float SegmentFriction = 4.0;

    UPROPERTY(Category = "Segment|Hard Constraint")
    float ConstrainAngle = 5.0;

	UPROPERTY(Category = "Segment|Soft Constraint")
	bool bUseSoftConstraintToo = true;

	UPROPERTY(Category = "Zoe|Camera")
	bool bAlignCameraWithWorldUpWhilePoleClimbing = false;
}