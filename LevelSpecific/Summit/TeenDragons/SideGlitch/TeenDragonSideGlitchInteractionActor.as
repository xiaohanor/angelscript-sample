class ATeenDragonSideGlitchInteractionActor : ASideGlitchInteractionActor
{
	UPROPERTY(OverrideComponent = MioInteraction)
	UTeenDragonThreeShotInteractionComponent TeenDragonMioInteraction;

	UPROPERTY(OverrideComponent = ZoeInteraction)
	UTeenDragonThreeShotInteractionComponent TeenDragonZoeInteraction;
};