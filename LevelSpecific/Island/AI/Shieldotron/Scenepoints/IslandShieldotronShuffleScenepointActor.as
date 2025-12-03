class AIslandShieldotronShuffleScenepointActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Scenepoint";
	default Billboard.WorldScale3D = FVector(2.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
#endif	

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UIslandShieldotronScenepointComponent ScenepointComponent;
	default ScenepointComponent.Radius = 600.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	private AHazeActor Holder = nullptr;
	
	UPROPERTY(EditInstanceOnly)
	ATraversalAreaActorBase ParentArea = nullptr;

	// Check that this ShufflePoint is reachable from the user's location.
	UPROPERTY(EditInstanceOnly)
	bool bRequirePathFindingCheck = true;

	private bool bDelayedInit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		// Try finding parent area if not set
		if (ParentArea == nullptr)
		{
			UTraversalManager TraversalManager = Traversal::GetManager();
			if (TraversalManager == nullptr)
			{
				bDelayedInit = true;
				SetActorTickEnabled(true); // delay setting parent area until TraversalManager has been created.
			}
			else
			{
				TrySetParentArea();
			}
		}
	}	

	void TrySetParentArea()
	{
		UTraversalManager TraversalManager = Traversal::GetManager();
		if (TraversalManager == nullptr)
			return;
		UScenepointComponent CloseTraversalScenepoint = TraversalManager.FindClosestTraversalScenepointOnSameElevation(ActorLocation);
		ATraversalAreaActorBase TraversalArea = TraversalManager.FindTraversalArea(CloseTraversalScenepoint);
		ParentArea = TraversalArea;
	}

	UIslandShieldotronScenepointComponent GetScenepoint()
	{
		return ScenepointComponent;
	};

	bool IsAt(AHazeActor Actor, float PredictionTime = 0.0) const
	{
		return ScenepointComponent.IsAt(Actor, PredictionTime);
	}

	bool IsValidHolder(AHazeActor Actor, float Range = 500)
	{
		if (Holder != nullptr && Holder != Actor)
			return false;
		if (!ScenepointComponent.IsShapeWithinRange(Actor, Range))
			return false; // Too far away
		if (UBasicAIHealthComponent::Get(Actor).IsDead())
			return false;
		
		return true;
	}

	bool Hold(AHazeActor Actor, float Range)
	{
		if (!IsValidHolder(Actor, Range))
			return false;		
		SetActorTickEnabled(true);
		Holder = Actor;
		return true;
	}

	float GetDist2DToShape(FVector Location)
	{
		return ScenepointComponent.GetDist2DToShape(Location);
	}
	
	FVector GetDestinationPoint()
	{		
		// Rectangle
		if (ScenepointComponent.Shape == EIslandShieldotronScenepointShape::Rectangle)
		{
			FVector RectanglePointLocalLoc = GetPointOnRectangle() * ScenepointComponent.Extents;
			FVector RectanglePointWorldLoc = ScenepointComponent.WorldTransform.TransformPositionNoScale(RectanglePointLocalLoc);
			return 	RectanglePointWorldLoc;
		}

		// Circle
		return ScenepointComponent.WorldLocation + Math::GetRandomPointOnCircle_XY() * ScenepointComponent.Radius * 1.0;
	}

	FVector GetPointOnRectangle()
	{
		int Side = Math::RandRange(0, 3);
		float Distance = Math::RandRange(-1.0, 1.0);			
		switch (Side)
		{
			case 0: return FVector(1.0, Distance, 0.0);
			case 1: return FVector(-1.0, Distance, 0.0);
			case 2: return FVector(Distance, 1.0, 0.0);
			case 3: return FVector(Distance, -1.0, 0.0);
		}
		return FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bDelayedInit)
		{			
			TrySetParentArea();
			SetActorTickEnabled(false);
			bDelayedInit = false;
			return;
		}

		// Check if we're still being held
		if (!IsValidHolder(Holder))
		{
			SetActorTickEnabled(false);
		}

#if EDITOR
		if (Holder == nullptr)
			return;		
		//Holder.bHazeEditorOnlyDebugBool = true;		
		if (Holder.bHazeEditorOnlyDebugBool)
		{
			if (ScenepointComponent.Shape == EIslandShieldotronScenepointShape::Circle)
				Debug::DrawDebugCircle(ScenepointComponent.WorldLocation, ScenepointComponent.Radius, 12, FLinearColor::Blue, 10.0);
			else if (ScenepointComponent.Shape == EIslandShieldotronScenepointShape::Rectangle)
				Debug::DrawDebugBox(ScenepointComponent.WorldLocation, ScenepointComponent.Extents, ScenepointComponent.WorldRotation, FLinearColor::Blue, 10.0);
		}
#endif		
	}

}


#if EDITOR
class UIslandShieldotronShuffleScenepointComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandShieldotronScenepointComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UIslandShieldotronScenepointComponent ShufflePointComp = Cast<UIslandShieldotronScenepointComponent>(Component);
		DrawWorldString("ShieldotronShuffleScenepoint", ShufflePointComp.WorldLocation, FLinearColor::Yellow, 2, 10000, true, true);
		if (ShufflePointComp == nullptr)
			return;
		UIslandShieldotronScenepointComponent Scenepoint = UIslandShieldotronScenepointComponent::Get(Component.Owner);
		if (Scenepoint == nullptr)
			return;
		if (Scenepoint.Shape == EIslandShieldotronScenepointShape::Circle)
			DrawCircle(ShufflePointComp.WorldLocation, Scenepoint.Radius, FLinearColor::Blue, 10.0);
		else if (Scenepoint.Shape == EIslandShieldotronScenepointShape::Rectangle)
			DrawWireBox(ShufflePointComp.WorldLocation, Scenepoint.Extents, ShufflePointComp.WorldRotation.Quaternion(), FLinearColor::Blue, 10.0);
	}
}
#endif
