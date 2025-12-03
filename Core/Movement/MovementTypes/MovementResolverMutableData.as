/**
 * Some resolver data may need to be accessed from const functions, even when it is not reasonable to pass it in as an argument.
 * Those values can instead be put here to allow access from the resolver.
 * Should never keep state between frames, since this will not be copied for reruns.
 */
UCLASS(NotBlueprintable)
class UMovementResolverMutableData
{
	int IterationDepenetrationCount = 0;

	void OnPrepareResolver()
	{
		IterationDepenetrationCount = 0;
	}

	void OnPrepareNextIteration()
	{
		IterationDepenetrationCount = 0;
	}
};