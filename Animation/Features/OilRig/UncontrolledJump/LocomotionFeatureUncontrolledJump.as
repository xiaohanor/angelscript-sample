struct FLocomotionFeatureUncontrolledJumpAnimData
{
	UPROPERTY(Category = "UncontrolledJump")
	FHazePlaySequenceData Jump;

	UPROPERTY(Category = "UncontrolledJump")
	FHazePlaySequenceData WindGust;
}

class ULocomotionFeatureUncontrolledJump : UHazeLocomotionFeatureBase
{
	default Tag = n"AirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureUncontrolledJumpAnimData AnimData;
}
