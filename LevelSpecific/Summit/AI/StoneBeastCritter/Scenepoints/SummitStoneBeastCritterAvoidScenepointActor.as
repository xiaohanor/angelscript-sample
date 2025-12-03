class ASummitStoneBeastCritterAvoidScenepointActor : AScenepointActorBase
{
#if EDITOR
	default Billboard.SpriteName = "AvoidScenepoint";
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	
	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UScenepointComponent ScenepointComponent;

	// Avoid location will steer critters in direction of the hemisphere indicated by this actor's forward vector.
	UPROPERTY(EditInstanceOnly)
	bool bIsForcingInForwardDirectionHemisphere = false;

	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};
}
