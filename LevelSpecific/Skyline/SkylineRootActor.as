UCLASS(Abstract)
class ASkylineRootActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USkylineRootActorVisualizerComponent VisualizerComp;
#endif
};

#if EDITOR
UCLASS(NotBlueprintable)
class USkylineRootActorVisualizerComponent : UHazeEditorRenderedComponent
{
	default bTickInEditor = true;
//	default SetIgnoreBoundsForEditorFocus(true);
//	default SetBoundsScale(1000.0);

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MarkRenderStateDirty();		
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		auto RootActor = Cast<ASkylineRootActor>(Owner);
		if (RootActor == nullptr)
			return;

		float Thickness = 50.0;
		FLinearColor Color = FLinearColor::Blue;

		auto Box = RootActor.RootComponent.GetLocalBoundingBoxOfChildren(true, true, false);
		FTransform Transform = RootActor.RootComponent.WorldTransform;
		DrawWireBox(Transform.TransformPositionNoScale(Box.Center), Box.Extent, Transform.Rotation, FLinearColor::LucBlue, 100.0);

//		FVector Origin;
//		FVector Extents;
//		RootActor.GetActorLocalBounds(false, Origin, Extents, true);
//		RootActor.GetActorBounds(false, Origin, Extents, true);
//		Extents = RootActor.GetActorBoxExtents(false, true);
//		FTransform LocalBoundsWorldTransform = FTransform(RootActor.ActorRotation, RootActor.ActorTransform.TransformPosition(Origin), RootActor.ActorScale3D * Extents);

		FVector Origin;
		FVector Extents;
//		GetHierarchyBounds(RootActor, Origin, Extents);

//		DrawWireBox(LocalBoundsWorldTransform.Location, LocalBoundsWorldTransform.Scale3D, LocalBoundsWorldTransform.Rotation, Color, Thickness);

		TArray<AActor> AttachedActors;
		RootActor.GetAttachedActors(AttachedActors, true, true);
		for (auto AttachedActor : AttachedActors)
		{
//			DrawLine(RootActor.ActorLocation, AttachedActor.ActorLocation, FLinearColor::Green, 10.0);
		}
#endif
	}

	void GetHierarchyBounds(AActor RootActor, FVector& Origin, FVector& Extents)
	{
		FVector HierarchyOrigin;
		FVector HierarchyExtents;

		TArray<AActor> AttachedActors;
		RootActor.GetAttachedActors(AttachedActors, true, true);
		for (auto AttachedActor : AttachedActors)
		{
			FTransform Transform = AttachedActor.ActorTransform;

			DrawLine(RootActor.ActorLocation, AttachedActor.ActorLocation, FLinearColor::Red, 20.0);

			FVector AttachedActorBoundsOrigin;
			FVector AttachedActorBoundsExtents;
			AttachedActor.GetActorLocalBounds(false, AttachedActorBoundsOrigin, AttachedActorBoundsExtents);
			DrawWireSphere(Transform.TransformPosition(AttachedActorBoundsOrigin), 100.0, FLinearColor::Green, 20.0, 4);
			DrawWireBox(Transform.TransformPosition(AttachedActorBoundsOrigin), Transform.Scale3D * AttachedActorBoundsExtents, Transform.Rotation, FLinearColor::Green, 20.0);
			DrawLine(RootActor.ActorLocation, RootActor.ActorTransform.TransformVectorNoScale(FVector().ComponentMax(AttachedActorBoundsExtents)), FLinearColor::Blue, 20.0);
			DrawLine(Transform.TransformPosition(AttachedActorBoundsOrigin), AttachedActor.ActorTransform.TransformVectorNoScale(FVector().ComponentMax(Transform.Scale3D * AttachedActorBoundsExtents)), FLinearColor::Blue, 20.0);
		}
	}
}

class USkylineRootActorVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineRootActorVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto RootActor = Cast<ASkylineRootActor>(InComponent.Owner);
	}
}
#endif