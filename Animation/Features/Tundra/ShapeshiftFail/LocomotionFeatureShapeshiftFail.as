struct FLocomotionFeatureShapeshiftFailAnimData
{
	UPROPERTY(Category = "ShapeshiftFail")
	FHazePlaySequenceData PoleClimb;

	UPROPERTY(Category = "ShapeshiftFail")
	FHazePlaySequenceData Perch;
}

class ULocomotionFeatureShapeshiftFail : UHazeLocomotionFeatureBase
{
	default Tag = n"ShapeshiftFail";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureShapeshiftFailAnimData AnimData;
}
