
class ULocomotionFeatureSanctuaryDoppelgangerMovement : ULocomotionFeatureMovement
{
    default Tag = LocomotionFeatureAISanctuaryTags::DoppelgangerMimicMovement;

	void MimicFeature(AHazePlayerCharacter MimicTarget)
	{
		ULocomotionFeatureMovement TargetFeature = Cast<ULocomotionFeatureMovement>(MimicTarget.Mesh.GetFeatureByClass(ULocomotionFeatureMovement));
		AnimData = TargetFeature.AnimData;
	}
}
