struct FLocomotionFeatureShapeShiftData
{
	UPROPERTY()
	float AdditiveScale = 1;

	UPROPERTY()
	UAnimSequence ScalePose;

	UPROPERTY()
	UAnimSequence CorrectionPose;

	UPROPERTY()
	UAnimSequence TransformMh;
}

class ULocomotionFeatureShapeshift : UHazeLocomotionFeatureBase
{
	default Tag = n"Shapeshift";

	UPROPERTY(Category = "BasePose")
	FHazePlaySequenceData BasePose;

	UPROPERTY(Category = "Shape")
	FLocomotionFeatureShapeShiftData Big;

	UPROPERTY(Category = "Shape")
	FLocomotionFeatureShapeShiftData Player;

	UPROPERTY(Category = "Shape")
	FLocomotionFeatureShapeShiftData Small;

	FLocomotionFeatureShapeShiftData GetAnimDataForShape(ETundraShapeshiftShape Shape)
	{
		if (Shape == ETundraShapeshiftShape::Big)
			return Big;

		if (Shape == ETundraShapeshiftShape::Small)
			return Small;

		return Player;
	}
}
