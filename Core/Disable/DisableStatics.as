


/**
 * Log the default disabled actor and component logic to the temporal log for this actor
 */
UFUNCTION(Category = "Debug")
mixin void TemporalLogAllDefaultDisableLogic(AActor Actor, FString TemporalLogCategory = "Disables")
{
#if TEST
	auto Log = TEMPORAL_LOG(Actor, TemporalLogCategory);
	
	// Log the actor params
	{
		if(Actor.IsActorDisabled())
		{
			Log.Status("Enabled Status", FLinearColor::Red);

			// Get disablers
			FString AllDisablers = "";
			TArray<FString> ActorDisables; 
			Actor.GetDisableInstigatorsDebugInformation(ActorDisables);
			for(auto It : ActorDisables)
			{
				AllDisablers += It;
				AllDisablers += "\n";
			}

			Log.Value("Disablers", AllDisablers);
		}
		else
		{
			Log.Status("Enabled Status", FLinearColor::Green);
		}

		// Get blockers
		TArray<FActorBlockInstigatorDebugStatus> ActorBlockInfos;
		Actor.GetBlockInstigatorsDebugInformation(ActorBlockInfos);

		FHazeDebugBlockersLogData ActorBlockers;
		ActorBlockers.Apply(ActorBlockInfos);
	
		Log.Value("Tick Enabled", Actor.IsActorTickEnabled());
		Log.Value("Tick Blocked", ActorBlockers.TickBlockers);

		Log.Value("Hidden", Actor.IsHidden());
		Log.Value("Visuals Blocked", ActorBlockers.VisualBlockers);

		Log.Value("Collision Enabled", Actor.GetActorEnableCollision());
		Log.Value("Collision Blocked", ActorBlockers.CollisionBlockers);
	}
	
	// Log the components
	{
		TMap<UActorComponent, FComponentBlockInstigatorDebugStatus> BlockedCompnents;

		// Get component blockers
		TArray<UActorComponent> Components;
		Actor.GetComponentsByClass(Components);
		for(auto ItComp : Components)
		{
			TArray<FComponentBlockInstigatorDebugStatus> ComponentBlockInfos;
			ItComp.GetBlockInstigatorsDebugInformation(ComponentBlockInfos);

			FHazeDebugBlockersLogData ComponentBlockers;
			ComponentBlockers.Apply(ComponentBlockInfos);

			Log.Value(f"{ItComp};Tick Blocked", ComponentBlockers.TickBlockers);
			Log.Value(f"{ItComp};Visuals Blocked", ComponentBlockers.VisualBlockers);
			Log.Value(f"{ItComp};Collision Blocked", ComponentBlockers.CollisionBlockers);
		}
	}	
#endif
}

#if TEST
struct FHazeDebugBlockersLogData
{
	FString TickBlockers = "";
	FString VisualBlockers = "";
	FString CollisionBlockers = "";

	void Apply(TArray<FActorBlockInstigatorDebugStatus> ActorBlockInfo)
	{
		for(auto It : ActorBlockInfo)
		{
			if(It.bHasBlockedTick)
			{
				TickBlockers += It.Instigator;
				TickBlockers += "\n";
			}

			if(It.bHasBlockedVisuals)
			{
				VisualBlockers += It.Instigator;
				VisualBlockers += "\n";
			}

			if(It.bHasBlockedCollision)
			{
				CollisionBlockers += It.Instigator;
				CollisionBlockers += "\n";
			}
		}

		if(TickBlockers == "")
			TickBlockers = "None";

		if(VisualBlockers == "")
			VisualBlockers = "None";

		if(CollisionBlockers == "")
			CollisionBlockers = "None";
	}

	void Apply(TArray<FComponentBlockInstigatorDebugStatus> ActorBlockInfo)
	{
		for(auto It : ActorBlockInfo)
		{
			if(It.bHasBlockedTick)
			{
				TickBlockers += It.Instigator;
				TickBlockers += "\n";
			}

			if(It.bHasBlockedVisuals)
			{
				VisualBlockers += It.Instigator;
				VisualBlockers += "\n";
			}

			if(It.bHasBlockedCollision)
			{
				CollisionBlockers += It.Instigator;
				CollisionBlockers += "\n";
			}
		}

		if(TickBlockers == "")
			TickBlockers = "None";

		if(VisualBlockers == "")
			VisualBlockers = "None";

		if(CollisionBlockers == "")
			CollisionBlockers = "None";
	}
}
#endif