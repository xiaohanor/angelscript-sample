struct FLocomotionFeatureCopsGunMeleeFinisherAnimData
{
	UPROPERTY(Category = "CopsGunMeleeFinisher")
	FHazePlaySequenceData ClockwiseFinisher_var1;
}

class ULocomotionFeatureCopsGunMeleeFinisher : UHazeLocomotionFeatureBase
{
	default Tag = n"CopsGunMeleeFinisher";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCopsGunMeleeFinisherAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
