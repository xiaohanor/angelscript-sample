struct FLocomotionFeatureDroneHangAnimData
{
	UPROPERTY(Category = "DroneHang")
	FHazePlaySequenceData DroneJump;

	UPROPERTY(Category = "DroneHang")
	FHazePlaySequenceData DroneJumpTwistLeft;

	UPROPERTY(Category = "DroneHang")
	FHazePlaySequenceData DroneJumpTwistRight;

	UPROPERTY(Category = "DroneHang")
	FHazePlayBlendSpaceData Hang;
}

class ULocomotionFeatureDroneHang : UHazeLocomotionFeatureBase
{
	default Tag = n"DroneHang";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDroneHangAnimData AnimData;
}
