
class ULocomotionFeatureSanctuaryDoppelgangerJump : ULocomotionFeatureJump
{
    default Tag = LocomotionFeatureAISanctuaryTags::DoppelgangerMimicJump;

	void MimicFeature(AHazePlayerCharacter MimicTarget)
	{
		ULocomotionFeatureJump TargetFeature = Cast<ULocomotionFeatureJump>(MimicTarget.Mesh.GetFeatureByClass(ULocomotionFeatureJump));
		AnimData = TargetFeature.AnimData;
	}
}
