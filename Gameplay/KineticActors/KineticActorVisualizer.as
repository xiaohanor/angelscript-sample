#if EDITOR
enum EKineticActorVisualizeAttachedActorsMode
{
	Disabled,
	WireBoxBounds,
	StaticMeshes
};

namespace KineticActorVisualizer
{
	const FString MainMaterialPath = "/Game/Editor/Materials/M_Wireframe_Main";
	const FString SubMaterialPath = "/Game/Editor/Materials/M_Wireframe_Sub";
	const bool bVisualizeOnlyMainMesh = false;
	const EKineticActorVisualizeAttachedActorsMode VisualizeAttachedActors = EKineticActorVisualizeAttachedActorsMode::WireBoxBounds;
	const FLinearColor AttachedActorBoundsColor = FLinearColor::DPink;

	/**
	 * Start recursively finding attached kinetic actors, and simulate their movement from the top down
	 * If we are multi selecting in the editor, it falls back to KineticActorVisualizer::VisualizeSingle()
	 */
	void VisualizeKineticChain(
		const AActor Actor,
		const UHazeScriptComponentVisualizer Visualizer,
		bool bSimulateOnlySelected
	)
	{
		FTransform ParentTransform = FTransform::Identity;
		if(Actor.GetAttachParentActor() != nullptr)
			ParentTransform = Actor.GetAttachParentActor().ActorTransform;

		// Don't recursively visualize if we are multi selecting
		const bool bRecursiveVisualize = (Editor::SelectedActors.Num() <= 1 && Editor::SelectedComponents.Num() <= 1);

		if(bRecursiveVisualize)
		{
			VisualizeRecursive(Actor, Visualizer, ParentTransform, bSimulateOnlySelected);
		}
		else
		{
			FTransform OutVisualizeActorTransform;
			VisualizeSingle(Actor, Visualizer, ParentTransform, bSimulateOnlySelected, OutVisualizeActorTransform);
		}
	}

	/**
	 * Recursively go through the attached actors to VisualizeActor and call KineticActorVisualizer::Visualize()
	 */
	void VisualizeRecursive(
		const AActor VisualizeActor,
		const UHazeScriptComponentVisualizer Visualizer,
		FTransform ParentTransform,
		bool bSimulateOnlySelected
	)
	{
		FTransform VisualizeActorTransform = ParentTransform * VisualizeActor.ActorTransform;

		VisualizeSingle(VisualizeActor, Visualizer, ParentTransform, bSimulateOnlySelected, VisualizeActorTransform);

		TArray<AActor> AttachedActors;
		VisualizeActor.GetAttachedActors(AttachedActors, false, false);
		for(auto Actor : AttachedActors)
		{
			// Go through all children and visualize them as well
			VisualizeRecursive(Actor, Visualizer, VisualizeActorTransform, bSimulateOnlySelected);
		}
	}

	/**
	 * Visualize any of the Kinetic actors from another visualizer.
	 * @param ParentTransform The kinetic movement is relative, so we need to provide a parent transform if we are not the root actor.
	 * @param OutVisualizeActorTransform The final transform of the visualized actor.
	 */
	void VisualizeSingle(
		const AActor VisualizeActor,
		const UHazeScriptComponentVisualizer Visualizer,
		FTransform ParentTransform,
		bool bSimulateOnlySelected,
		FTransform&out OutVisualizeActorTransform
	)
	{
		{
			auto KineticMovingActor = Cast<AKineticMovingActor>(VisualizeActor);
			if(KineticMovingActor != nullptr)
			{
				bool bSimulate = true;
				if(bSimulateOnlySelected && !IsExclusivelySelected(KineticMovingActor))
					bSimulate = false;

				KineticMovingActor.Visualize(Visualizer, ParentTransform, bSimulate, OutVisualizeActorTransform);
				return;
			}
		}

		{
			auto KineticRotatingActor = Cast<AKineticRotatingActor>(VisualizeActor);
			if(KineticRotatingActor != nullptr)
			{
				bool bSimulate = true;
				if(bSimulateOnlySelected && !IsExclusivelySelected(KineticRotatingActor))
					bSimulate = false;

				KineticRotatingActor.Visualize(Visualizer, ParentTransform, bSimulate, OutVisualizeActorTransform);
				return;
			}
		}

		{
			auto KineticSplineFollowActor = Cast<AKineticSplineFollowActor>(VisualizeActor);
			if(KineticSplineFollowActor != nullptr)
			{
				bool bSimulate = true;
				if(bSimulateOnlySelected && !IsExclusivelySelected(KineticSplineFollowActor))
					bSimulate = false;

				KineticSplineFollowActor.Visualize(Visualizer, ParentTransform, bSimulate, OutVisualizeActorTransform);
				return;
			}
		}

		OutVisualizeActorTransform = VisualizeActor.ActorRelativeTransform * ParentTransform;

		DrawAttachedActor(Visualizer, VisualizeActor, OutVisualizeActorTransform);
	}

	void DrawAttachedActor(
		const UHazeScriptComponentVisualizer Visualizer,
		const AActor AttachedActor,
		FTransform ActorTransform
	)
	{
		switch(VisualizeAttachedActors)
		{
			case EKineticActorVisualizeAttachedActorsMode::Disabled:
				return;

			case EKineticActorVisualizeAttachedActorsMode::WireBoxBounds:
			{
				FVector Origin;
				FVector Extents;
				AttachedActor.GetActorLocalBounds(true, Origin, Extents);

				if(!Extents.IsNearlyZero())
				{
					Origin = ActorTransform.TransformPosition(Origin);
					Extents = ActorTransform.Scale3D * Extents;

					//Visualizer.DrawWorldString(VisualizeActor.ActorNameOrLabel, Origin, FLinearColor::White, 1, -1, false, true);
					//Visualizer.DrawSolidBox(FInstigator(Visualizer, VisualizeActor.Name), Origin, Transform.Rotation, Extents, FLinearColor::White, 0.1, 3);
					Visualizer.DrawWireBox(Origin, Extents, ActorTransform.Rotation, AttachedActorBoundsColor, 2, true);
					return;
				}
				break;
			}

			case EKineticActorVisualizeAttachedActorsMode::StaticMeshes:
			{
				auto Material = Cast<UMaterialInterface>(LoadObject(nullptr, KineticActorVisualizer::MainMaterialPath));
				DrawAllStaticMeshesOnActor(Visualizer, AttachedActor, ActorTransform, Material);
				break;
			}
		}
	}

	void DrawAllStaticMeshesOnActor(
		const UHazeScriptComponentVisualizer Visualizer,
		const AActor AttachedActor,
		FTransform ActorTransform,
		UMaterialInterface Material
	)
	{
		TArray<UStaticMeshComponent> MeshComponents;
		AttachedActor.GetComponentsByClass(MeshComponents);

		for(auto MeshComponent : MeshComponents)
		{
			if(!IsValid(MeshComponent))
				continue;
			
			if(!MeshComponent.bVisible)
				continue;
			
			const FTransform RelativeTransform = MeshComponent.WorldTransform.GetRelativeTransform(MeshComponent.Owner.ActorTransform);
			const FTransform MeshTransform = RelativeTransform * ActorTransform;

			Visualizer.DrawMeshWithMaterial(
				MeshComponent.StaticMesh,
				Material,
				MeshTransform.Location,
				MeshTransform.Rotation,
				MeshTransform.Scale3D
			);
		}
	}

	bool IsExclusivelySelected(const AActor Actor)
	{
		return Editor::SelectedActors.Num() == 1 && Editor::IsSelected(Actor);
	}

	UMaterialInterface GetMaterial(const AActor Actor)
	{
		if(IsExclusivelySelected(Actor))
			return GetSelectedMaterial();
		else
			return GetUnselectedMaterial();
	}

	UMaterialInterface GetSelectedMaterial()
	{
		return Cast<UMaterialInterface>(LoadObject(nullptr, KineticActorVisualizer::MainMaterialPath));
	}

	UMaterialInterface GetUnselectedMaterial()
	{
		return Cast<UMaterialInterface>(LoadObject(nullptr, KineticActorVisualizer::SubMaterialPath));
	}
}
#endif