// Blocks other behaviour in selector
class USummitDecimatorSpikeBombIdleBehaviour : UBasicBehaviour
{
	//default Requirements.
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Perception);

	USummitMeltComponent MeltComp;
	UHazeMovementComponent MoveComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MeltComp = USummitMeltComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!MeltComp.bMelted)
			return false;

		if (!MoveComp.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if (Super::ShouldDeactivate())
			return true;

		return false;
	}

}