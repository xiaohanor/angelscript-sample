struct FLocomotionFeatureFairyWindTunnelAnimData
{
	UPROPERTY(Category = "FairyWindTunnel")
	FHazePlaySequenceData WindTunnel;

	UPROPERTY(Category = "FairyWindTunnel")
	FHazePlaySequenceData Volt;

	
}

class ULocomotionFeatureFairyWindTunnel : UHazeLocomotionFeatureBase
{
	default Tag = n"FairyWindTunnel";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFairyWindTunnelAnimData AnimData;
}
