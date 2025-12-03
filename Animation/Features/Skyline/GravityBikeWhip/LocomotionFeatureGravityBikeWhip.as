struct FLocomotionFeatureGravityBikeWhipAnimData
{
	UPROPERTY(Category = "GravityBikeWhip")
	FHazePlayBlendSpaceData GrabLeftBS;

	UPROPERTY(Category = "GravityBikeWhip")
	FHazePlayBlendSpaceData GrabRightBS;

	UPROPERTY(Category = "GravityBikeWhip")
	FHazePlayBlendSpaceData BikeLassoBS;

	UPROPERTY(Category = "GravityBikeWhip")
	FHazePlayBlendSpaceData ReleaseBS;

	UPROPERTY(EditAnywhere, Category = "Whip")
	float WhipPlayRate = 1;

	UPROPERTY(EditAnywhere, Category = "Release")
	float ReleasePlayRate = 1;
}

class ULocomotionFeatureGravityBikeWhip : UHazeLocomotionFeatureBase
{
	default Tag = n"GravityBikeWhip";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityBikeWhipAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph

	UPROPERTY(EditAnywhere, Category = "Whip")
	private float StartPullTime = 0.16;

	UPROPERTY(EditAnywhere, Category = "Whip")
	private float StartLassoTime = 0.4;

	UPROPERTY(EditAnywhere, Category = "Whip")
	private float WhipDropTime = 0.7;

	UPROPERTY(EditAnywhere, Category = "Whip")
	FRuntimeFloatCurve WhipAccelerationDurationMultiplier;

	UPROPERTY(EditAnywhere, Category = "Release")
	private float ReleaseDropTime = 0.22;

	float GetStartPullDuration() const
	{
		return StartPullTime / AnimData.WhipPlayRate;
	}

	float GetPullDuration() const
	{
		return (StartLassoTime - StartPullTime) / AnimData.WhipPlayRate;
	}

	float GetReboundDuration() const
	{
		return (WhipDropTime - (StartLassoTime - StartPullTime)) / AnimData.WhipPlayRate;
	}

	float GetThrowDuration() const
	{
		return ReleaseDropTime / AnimData.ReleasePlayRate;
	}
}
