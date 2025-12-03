#if !RELEASE
struct FMovementInstigatorMove
{
	FVector Location;
	FQuat Rotation;
	bool bIsTeleport;
	TArray<FString> CallStack;
};
#endif

/**
 * Logs each time the actor moves, and the callstack that moved it.
 * Only works in !RELEASE
 */
class UMovementInstigatorLogComponent : UActorComponent
{
	default TickGroup = ETickingGroup::TG_LastDemotable;

#if !RELEASE
	TArray<FMovementInstigatorMove> Moves;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if !RELEASE
		SceneComponent::BindOnSceneComponentMoved(Owner.RootComponent, FOnSceneComponentMoved(this, n"OnMoved"));
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog PositionPageLog = TEMPORAL_LOG(Owner).Page("Position");

		PositionPageLog.Transform("Final Actor Transform", Owner.ActorTransform, 500, 5);
		PositionPageLog.DirectionalArrow("Final Actor Velocity", Owner.ActorLocation, Owner.ActorVelocity);

		for(int i = 0; i < Moves.Num(); i++)
		{
			FTemporalLog MoveSectionLog = PositionPageLog.Section(f"Move {i + 1}", i + 1);
			MoveSectionLog.Transform("Transform", FTransform(Moves[i].Rotation, Moves[i].Location), 500);
			MoveSectionLog.Value("Is Teleport", Moves[i].bIsTeleport);

			for(int j = 0; j < Moves[i].CallStack.Num(); j++)
			{
				MoveSectionLog.Value(f"Instigator {j + 1}", Moves[i].CallStack[j]);
			}
		}
		
		Moves.Reset();
#endif
	}

	UFUNCTION()
	private void OnMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
#if !RELEASE
		FMovementInstigatorMove Move;
		Move.Location = MovedComponent.WorldLocation;
		Move.Rotation = MovedComponent.ComponentQuat;
		Move.bIsTeleport = bIsTeleport;
		Move.CallStack = GetAngelscriptCallstack();

		// Remove self, event and actor from the callstack
		Move.CallStack.RemoveAt(0);
		Move.CallStack.RemoveAt(0);
		Move.CallStack.RemoveAt(0);

		if(Move.CallStack.IsEmpty())
			return;

		Moves.Add(Move);
#endif
	}
};