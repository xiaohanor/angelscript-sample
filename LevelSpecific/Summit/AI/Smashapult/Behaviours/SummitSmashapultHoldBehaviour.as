class USummitSmashapultHoldBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TargetComp.SetTarget(Game::Zoe);
		if (TargetComp.HasValidTarget())
			DestinationComp.RotateTowards(TargetComp.Target);		
	}
}
