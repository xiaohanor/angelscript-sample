UCLASS(NotBlueprintable)
class ADentistSplitToothAICircleConstraint : ACircleConstraintResolverExtensionActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
};

namespace ADentistSplitToothAICircleConstraint
{
	ADentistSplitToothAICircleConstraint Get()
	{
		return TListedActors<ADentistSplitToothAICircleConstraint>().Single;
	}
}