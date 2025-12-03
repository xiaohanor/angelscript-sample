class ASummitStoneBeastZapperShuffleScenepointActor : AScenepointActorBase
{
	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UScenepointComponent ScenepointComponent;
	default ScenepointComponent.Radius = 600.0;

	UPROPERTY(DefaultComponent)
	USummitStoneBeastZapperShuffleScenepointComponent ShufflePointComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	private TArray<AHazeActor> Holders;
	
	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};

	bool IsAt(AHazeActor Actor, float PredictionTime = 0.0) const
	{
		return ScenepointComponent.IsAt(Actor, PredictionTime);
	}

	bool IsValidHolder(AHazeActor Actor)
	{
		if (!ActorLocation.IsWithinDist(Actor.ActorLocation, GetScenepoint().Radius + 500.0))
			return false; // Too far away
		if (UBasicAIHealthComponent::Get(Actor).IsDead())
			return false;
		return true;
	}

	bool Hold(AHazeActor Actor)
	{
		if (!IsValidHolder(Actor))
			return false;
		if (Holders.Contains(Actor))
			return true;
		SetActorTickEnabled(true);
		Holders.Add(Actor);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Check if we're still being held
		for (int i = Holders.Num() - 1; i >= 0; i--)
		{
			if (!IsValidHolder(Holders[i]))
			{
				Holders.RemoveAtSwap(i);
				continue;
			}
#if EDITOR
			//Holders[i].bHazeEditorOnlyDebugBool = true;		
			if (Holders[i].bHazeEditorOnlyDebugBool)
				Debug::DrawDebugCircle(ShufflePointComp.WorldLocation, ScenepointComponent.Radius, 12, FLinearColor::Blue, 10);
#endif
		}

		if (Holders.Num() == 0)
			SetActorTickEnabled(false);
	}

}

class USummitStoneBeastZapperShuffleScenepointComponent : USceneComponent
{
}

#if EDITOR
class USummitStoneBeastZapperShuffleScenepointVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitStoneBeastZapperShuffleScenepointComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USummitStoneBeastZapperShuffleScenepointComponent ShufflePointComp = Cast<USummitStoneBeastZapperShuffleScenepointComponent>(Component);
		DrawWorldString("StoneBeastZapperShuffleScenepointComponent", ShufflePointComp.WorldLocation, FLinearColor::Yellow, 2, 10000, true, true);
		if (ShufflePointComp == nullptr)
			return;
		UScenepointComponent Scenepoint = UScenepointComponent::Get(Component.Owner);
		if (Scenepoint == nullptr)
			return;
		DrawCircle(ShufflePointComp.WorldLocation, Scenepoint.Radius, FLinearColor::Blue, 10.0); 	
	}
}
#endif
