struct FLocomotionFeatureIceBowAnimData
{
	UPROPERTY(Category = "IceBow")
	FHazePlaySequenceData AimAdditive;
	
	UPROPERTY(Category = "IceBow")
	FHazePlayBlendSpaceData Enter;

	UPROPERTY(Category = "IceBow")
	FHazePlayBlendSpaceData EnterStill;

	UPROPERTY(Category = "IceBow")
	FHazePlayBlendSpaceData Aim;

	UPROPERTY(Category = "IceBow")
	FHazePlayBlendSpaceData Shoot;


	UPROPERTY(Category = "IceBow")
	FHazePlaySequenceData StillExit;

}

class ULocomotionFeatureIceBow : UHazeLocomotionFeatureBase
{
	default Tag = n"IceBow";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureIceBowAnimData AnimData;
}
