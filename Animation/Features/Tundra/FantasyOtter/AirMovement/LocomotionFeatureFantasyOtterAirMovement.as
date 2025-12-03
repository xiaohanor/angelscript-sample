struct FLocomotionFeatureFantasyOtterAirMovementAnimData
{
	UPROPERTY(Category = "FromGround")
	FHazePlayBlendSpaceData FallFromGroundJumpBS;

	UPROPERTY(Category = "FromWater")
	FHazePlayBlendSpaceData FallFromWaterJumpBS;

	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData AirAdditiveBS;

}

class ULocomotionFeatureFantasyOtterAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"AirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFantasyOtterAirMovementAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, Category = "Physics")
    UHazePhysicalAnimationProfile PhysAnimProfile;

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph

}
