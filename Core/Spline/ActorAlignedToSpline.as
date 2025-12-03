
/**
 * Helper actor to align objects to the nearest spline position inside the editor.
 * Does not do anything during gameplay.
 */
class AActorAlignedToSpline : AHazePrefabActor
{
#if EDITOR
	default bRunConstructionScriptOnDrag = true;

	// Spline to align to in the editor
	UPROPERTY(EditInstanceOnly, Category = "Align to Spline in Editor")
	TSoftObjectPtr<AHazeActor> SplineActor;

	// Whether to align the location of the component to the nearest point on the spline
	UPROPERTY(EditAnywhere, Category = "Align to Spline in Editor")
	bool bAlignLocationToSpline = true;

	// Whether to align the rotation of the component to the nearest point on the spline
	UPROPERTY(EditAnywhere, Category = "Align to Spline in Editor")
	bool bAlignRotationToSpline = true;

	// Whether to set the scale to the scaling set inside the nearest spline point
	UPROPERTY(EditAnywhere, Category = "Align to Spline in Editor")
	bool bAlignScaleToSpline = false;

	private void Editor_AlignToSpline()
	{
		if (SplineActor.IsValid())
		{
			auto SplineComp = UHazeSplineComponent::Get(SplineActor.Get());
			if (SplineComp != nullptr)
			{
				float SplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);

				FTransform SplineTransform = SplineComp.GetWorldTransformAtSplineDistance(SplineDistance);
				FTransform RootTransform = RootComponent.GetWorldTransform();

				FTransform ParentTransform;
				if (RootComponent.AttachParent != nullptr)
					ParentTransform = RootComponent.AttachParent.GetWorldTransform();

				if (bAlignLocationToSpline)
					RootTransform.Location = ParentTransform.InverseTransformPosition(SplineTransform.Location);
				if (bAlignRotationToSpline)
					RootTransform.Rotation = ParentTransform.InverseTransformRotation(SplineTransform.Rotation);
				if (bAlignScaleToSpline)
					RootTransform.Scale3D = ParentTransform.InverseTransformVector(SplineTransform.Scale3D);

				RootComponent.SetWorldTransform(RootTransform);
			}
		}
	}

	// Manually re-align all actors that are aligned to a spline, use after editing a spline
	UFUNCTION(CallInEditor, Category = "Align to Spline in Editor")
	private void UpdateAllAlignedActorsToSpline()
	{
		FScopedTransaction Transaction("Align Actors To Spline");

		auto AlignedActors = Editor::GetAllEditorWorldActorsOfClass(AActorAlignedToSpline);

		for (auto It : AlignedActors)
		{
			auto Actor = Cast<AActorAlignedToSpline>(It);
			if (Actor.World == GetWorld())
			{
				Actor.Modify();
				Actor.RootComponent.Modify();
				Actor.Editor_AlignToSpline();
			}
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		
#if EDITOR
		if (!Editor::IsCooking())
			Editor_AlignToSpline();
#endif
	}
}