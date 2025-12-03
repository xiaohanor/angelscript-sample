struct FLocomotionFeaturePoleVaultChargeOverrideAnimData
{
	UPROPERTY(Category = "PoleVaultChargeOverride")
	FHazePlaySequenceData ChargeStart;

	UPROPERTY(Category = "PoleVaultChargeOverride")
	FHazePlaySequenceData ChargeStop;

	UPROPERTY(Category = "PoleVaultChargeOverride")
	FHazePlayBlendSpaceData ChargeMH;
}

class ULocomotionFeaturePoleVaultChargeOverride : UHazeLocomotionFeatureBase
{
	default Tag = n"PoleVaultChargeOverride";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePoleVaultChargeOverrideAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
