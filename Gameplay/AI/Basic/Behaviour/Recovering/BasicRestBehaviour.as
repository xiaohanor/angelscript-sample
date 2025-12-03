
class UBasicRestBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	private float RestDuration = 1.0;

	UBasicRestBehaviour(float RestingDuration)
	{
		RestDuration = RestingDuration;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAITags::Recovery, SubTagAIRecovery::Rest, EBasicBehaviourPriority::Low, this);

		if (ActiveDuration > RestDuration)
		{
			DeactivateBehaviour();
			return;
		}
	}
}