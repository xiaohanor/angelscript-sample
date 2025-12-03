struct FLocomotionFeatureGravityBikeFreeAnimData
{
	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringBS;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteerHeighBS;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringChargeBS;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringBoost;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringBoostLanding;
	
	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlaySequenceData SteeringFallingMh;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringLanding;
}

class ULocomotionFeatureGravityBikeFree : UHazeLocomotionFeatureBase
{
	default Tag = GravityBikeFree::GravityBikeFreeDriverFeature;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityBikeFreeAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
