class ATraversalVolume : AVolume
{
	UPROPERTY(DefaultComponent)
	UTraversalBuilderComponent BuilderComp;
	default BuilderComp.TraversalVolume = this;
}

class UTraversalBuilderComponent : UActorComponent
{
	AVolume TraversalVolume;

	
}
