/*
 * Defines a safe area where the Sandfish cannot attack.
 */
UCLASS(NotBlueprintable)
class ASandSharkSafePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "AutoAimTarget";
	default EditorIcon.WorldScale3D = FVector(10);

	UPROPERTY(DefaultComponent)
	USandSharkSafePointComponent SafePointComp;
#endif

	// Automatically registers this actor so that it can be fetched anywhere with TListedActors<ASandSharkSafePoint>().Array
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	// Actors that are considered part of this safe point
	UPROPERTY(EditInstanceOnly, Category = "Sand Shark Safe Point")
	TArray<AActor> SafePointGrounds;

	// References a spline that will be used by the Sandfish when the target player reaches the safe point
	UPROPERTY(EditInstanceOnly, Category = "Sand Shark Safe Point")
	ASandSharkSpline Spline;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Sand Shark Safe Point")
	FVector AutoFetchExtent = FVector(1000);

	// Finds all valid actors whose AABB intersects with the fetch extents (drawn in red)
	UFUNCTION(CallInEditor, Category = "Sand Shark Safe Point")
	private void AutoFetch()
	{
		SafePointGrounds.Empty();

		const FBox FetchBounds = FBox::BuildAABB(ActorLocation, AutoFetchExtent);

		// This is how we get all actors of a certain class in the editor.
		// This is NOT valid to call while playing the game, and is used since TListedActors only works while playing.
		TArray<AActor> Actors = Editor::GetAllEditorWorldActorsOfClass(AActor);
		for(auto Actor : Actors)
		{
			if(Actor.RootComponent == nullptr)
				continue;

			if(Actor.RootComponent.Mobility != EComponentMobility::Static)
				continue;

			// Ignore landscapes
			auto Landscape = Cast<ALandscape>(Actor);
			if(Landscape != nullptr)
				continue;

			// The safe point ground actors should have static meshes as root
			auto MeshComp = Cast<UStaticMeshComponent>(Actor.RootComponent);
			if(MeshComp == nullptr)
				continue;

			// Check AABB intersection
			FVector Origin, Extent;
			Actor.GetActorBounds(true, Origin, Extent);
			const FBox Bounds = FBox::BuildAABB(Origin, Extent);

			if(!FetchBounds.Intersect(Bounds))
				continue;

			// Check if the AABB origin is close enough, some actors have huge extents and/or we are inside of them
			if(ActorLocation.DistSquared(Origin) > AutoFetchExtent.SizeSquared())
				continue;

			SafePointGrounds.Add(Actor);
		}
	}
#endif
};

#if EDITOR
/**
 * This is an editor-only component that is simply used to link a visualizer to.
 * In a perfect world we would be able to add visualizers to actors and not just components, but at the moment this is not possible.
 */
UCLASS(NotBlueprintable, NotPlaceable)
class USandSharkSafePointComponent : UActorComponent
{
};

/**
 * This is a visualizer that allows you to draw lines and shapes in the editor view. Super useful, and very appreciated by designers.
 * It will only be drawn when the component is selected.
 */
 UCLASS(NotBlueprintable, NotPlaceable)
class USandSharkSafePointComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USandSharkSafePointComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		 auto SafePoint = Cast<ASandSharkSafePoint>(Component.Owner);
		 if(SafePoint == nullptr)
		 	return;

		DrawWireBox(SafePoint.ActorLocation, SafePoint.AutoFetchExtent, FQuat::Identity, FLinearColor::Red, 5, false);

		FBox Bounds;
		for(int i = 0; i < SafePoint.SafePointGrounds.Num(); i++)
		{
			auto SafePointGround = SafePoint.SafePointGrounds[i];
			if(SafePointGround == nullptr)
				continue;

			DrawDashedLine(SafePoint.ActorLocation, SafePointGround.ActorLocation, FLinearColor::LucBlue, 50, 5, true);

			FVector Origin, Extent;
			SafePointGround.GetActorBounds(true, Origin, Extent);

			// Combine all the bounds of the safe point ground actors into one bounds, visualizing the complete bounds of the safe point.
			Bounds += FBox::BuildAABB(Origin, Extent);

			// Draw the local bounds of a safe point ground actor
			// GetActorLocalBounds allows the bounds to be drawn in a rotated way without being the wrong scale, since a AABB (GetActorBounds) uses identity rotation.
			SafePointGround.GetActorLocalBounds(true, Origin, Extent, false);
			DrawWireBox(SafePointGround.ActorTransform.TransformPosition(Origin), SafePointGround.ActorTransform.Scale3D * Extent, SafePointGround.ActorQuat, FLinearColor::LucBlue, 1, false);
		}

		// Draw the complete bounds of the safe point
		DrawWireBox(Bounds.GetCenter(), Bounds.GetExtent(), FQuat::Identity, FLinearColor::Blue, 3, false);

		if(SafePoint.Spline != nullptr)
		{
			// Draw an arrow to the start of the spline
			DrawArrow(SafePoint.ActorLocation, SafePoint.Spline.Spline.GetWorldLocationAtSplineDistance(0), FLinearColor::Yellow, 100, 10);

			// Draw lines along the spline, showing that it belongs to the selected safe point
			float SplineDistance = 0;
			const float Interval = 500;
			while(SplineDistance < SafePoint.Spline.Spline.SplineLength)
			{
				DrawLine(
					SafePoint.Spline.Spline.GetWorldLocationAtSplineDistance(SplineDistance),
					SafePoint.Spline.Spline.GetWorldLocationAtSplineDistance(SplineDistance + Interval),
					FLinearColor::Yellow,
					20
				);

				SplineDistance += Interval;
			}
		}
		else
		{
			DrawWorldString("NO SPLINE ASSIGNED", SafePoint.ActorLocation, FLinearColor::Yellow, 2, 10000, true, true);
		}
	}
};
#endif

namespace SandShark
{
	namespace SafePoint
	{
		TArray<ASandSharkSafePoint> GetSafePoints()
		{
			// Static function to get all safe points in the world
			// TListedActors is a fancy way of handling registering actors that are enabled in the level.
			// Actors with a UHazeListedActorComponent can be fetched like this. If they are destroyed or disabled,
			// they will automatically be removed from the array.
			return TListedActors<ASandSharkSafePoint>().Array;
		}

		ASandSharkSafePoint GetSafePointForActor(AActor Actor)
		{
			for(auto SafePoint : GetSafePoints())
			{
				if(SafePoint.SafePointGrounds.Contains(Actor))
					return SafePoint;
			}
			
			return nullptr;
		}
	}
}