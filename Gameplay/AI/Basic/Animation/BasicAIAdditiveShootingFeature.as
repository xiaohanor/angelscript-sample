
class UBasicAIAnimationFeatureAdditiveShooting : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::AdditiveShooting;

	UPROPERTY(Category = "Shooting")
	UAnimSequence SingleShot;
} 
