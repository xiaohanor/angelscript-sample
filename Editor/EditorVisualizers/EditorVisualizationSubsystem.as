struct FEditorVisualizationComponent
{
	FInstigator Instigator;
	uint LastUsedFrame = 0;
	TSoftObjectPtr<AActor> TemporaryActor;
	TSoftObjectPtr<UActorComponent> Component;
}

struct FEditorVisualizationAnimation
{
	uint LastUsedFrame = 0;
	TSoftObjectPtr<AActor> TemporaryActor;
	TSoftObjectPtr<UHazeEditorPreviewSkeletalMeshComponent> Component;

	USkeletalMesh Mesh;
	UAnimSequence AnimSequence;
	float AnimTime;
	bool bApplyRootMotion;
}

class UEditorVisualizationSubsystem : UHazeEditorSubsystem
{
	private TMap<FInstigator, FEditorVisualizationComponent> VisualizationComponents;
	private TArray<FEditorVisualizationAnimation> VisualizationAnimations;
	
	/**
	 * Draw a skeletal mesh animation in editor for one frame.
	 */
	UHazeEditorPreviewSkeletalMeshComponent DrawAnimation(
		FTransform Transform, UAnimSequence Animation, float TimeInAnimation,
		bool bApplyRootMotion = false, USkeletalMesh OverrideMesh = nullptr)
	{
		for (FEditorVisualizationAnimation& Vis : VisualizationAnimations)
		{
			if (Vis.LastUsedFrame >= GFrameNumber)
				continue;
			if (Vis.AnimSequence != Animation)
				continue;

			auto Comp = Cast<UHazeEditorPreviewSkeletalMeshComponent>(Vis.Component.Get());
			Comp.SetVisibility(true);

			// Update an existing animation
			Vis.LastUsedFrame = GFrameNumber;

			auto Actor = Vis.TemporaryActor.Get();
			if (Actor != nullptr)
				Actor.ActorTransform = Transform;

			if (Vis.AnimTime != TimeInAnimation || Vis.bApplyRootMotion != bApplyRootMotion
				|| (OverrideMesh != nullptr && Vis.Mesh != OverrideMesh))
			{
				USkeletalMesh SkelMesh = OverrideMesh;
				if (SkelMesh == nullptr)
				{
					SkelMesh = EditorAnimation::GetAnimSequencePreviewMesh(Animation);
				}
				if (SkelMesh == nullptr)
				{
					TArray<USkeletalMesh> Meshes;
					if (EditorAnimation::GetPreviewMeshes(Animation, Meshes))
						SkelMesh = Meshes[0];
				}

				Comp.SetSkeletalMeshAsset(SkelMesh);
				Comp.SetAnimationPreview(
					Animation, TimeInAnimation, bApplyRootMotion
				);

				Vis.Mesh = SkelMesh;
				Vis.AnimSequence = Animation;
				Vis.AnimTime = TimeInAnimation;
				Vis.bApplyRootMotion = bApplyRootMotion;
			}
			else if (bApplyRootMotion)
			{
				Comp.ApplyAnimationRootMotion(
					Animation, TimeInAnimation
				);
			}

			return Comp;
		}

		USkeletalMesh SkelMesh = OverrideMesh;
		if (SkelMesh == nullptr)
		{
			SkelMesh = EditorAnimation::GetAnimSequencePreviewMesh(Animation);
		}
		if (SkelMesh == nullptr)
		{
			TArray<USkeletalMesh> Meshes;
			if (EditorAnimation::GetPreviewMeshes(Animation, Meshes))
				SkelMesh = Meshes[0];
		}

		FEditorVisualizationAnimation NewVis;
		NewVis.LastUsedFrame = GFrameNumber;
		NewVis.Mesh = SkelMesh;
		NewVis.AnimSequence = Animation;
		NewVis.AnimTime = TimeInAnimation;
		NewVis.bApplyRootMotion = bApplyRootMotion;

		auto Actor = SpawnTemporaryEditorActor(AHazeActor);
		Actor.SetActorEnableCollision(false);
		Actor.SetActorHiddenInGame(false);
		Actor.ActorTransform = Transform;

		auto Component = Cast<UHazeEditorPreviewSkeletalMeshComponent>(
			Actor.CreateComponent(UHazeEditorPreviewSkeletalMeshComponent));

		Component.SetVisibility(true);
		Component.SetSkeletalMeshAsset(SkelMesh);
		Component.SetAnimationPreview(
			Animation, TimeInAnimation, bApplyRootMotion
		);

		NewVis.TemporaryActor = Actor;
		NewVis.Component = Component;
		Editor::SetComponentSelectable(Component, false);

		VisualizationAnimations.Add(NewVis);
		return Component;
	}

	/**
	 * Draw a static mesh in editor for one frame.
	 */
	UStaticMeshComponent DrawMesh(
		FInstigator Instigator,
		FTransform Transform, UStaticMesh StaticMesh
	)
	{
		auto Component = Cast<UStaticMeshComponent>(DrawVisualizationComponent(Instigator, UStaticMeshComponent, Transform));
		if(Component == nullptr)
			return nullptr;

		Component.SetVisibility(true);
		Component.SetStaticMesh(StaticMesh);
		return Component;
	}

	/**
	 * Draw a visualization component in the editor for one frame.
	 */
	UActorComponent DrawVisualizationComponent(
		FInstigator Instigator,
		TSubclassOf<UActorComponent> ComponentClass,
		FTransform Transform)
	{
		FEditorVisualizationComponent& Vis = VisualizationComponents.FindOrAdd(Instigator);

		// If it's an existing one
		if (Vis.Instigator == Instigator)
		{
			auto Comp = Vis.Component.Get();
			if(Comp == nullptr)
			{
				// Asset is probably pending, just wait
				return nullptr;
			}

			if (Comp.Class == ComponentClass.Get())
			{
				Vis.LastUsedFrame = GFrameNumber;
				auto Actor = Vis.TemporaryActor.Get();
				if (Actor != nullptr)
					Actor.ActorTransform = Transform;
				return Comp;
			}
			else
			{
				auto Actor = Vis.TemporaryActor.Get();
				if (Actor != nullptr)
					Actor.DestroyActor();
			}
		}

		Vis.Instigator = Instigator;
		Vis.LastUsedFrame = GFrameNumber;

		auto Actor = SpawnTemporaryEditorActor(AHazeActor);
		Actor.SetActorEnableCollision(false);
		Actor.SetActorHiddenInGame(false);
		Actor.ActorTransform = Transform;

		auto Component = Actor.CreateComponent(ComponentClass);

		auto PrimitiveComp = Cast<UPrimitiveComponent>(Component);
		if (PrimitiveComp != nullptr)
			Editor::SetComponentSelectable(PrimitiveComp, false);

		Vis.TemporaryActor = Actor;
		Vis.Component = Component;

		return Component;
	}

	UBoxComponent DrawSolidBox(
		FInstigator Instigator,
		FVector Location,
		FQuat Rotation,
		FVector Extents,
		FLinearColor Color,
		float Opacity = 1)
	{
		FTransform Transform(Rotation, Location);
		UBoxComponent BoxComponent = Cast<UBoxComponent>(DrawVisualizationComponent(Instigator, UBoxComponent, Transform));
		if(BoxComponent == nullptr)
			return nullptr;

		BoxComponent.BoxExtent = Extents;

		FLinearColor NewColor = Color;
		NewColor.A = Opacity;

		if(!NewColor.Equals(FLinearColor(BoxComponent.ShapeColor)) || !BoxComponent.bAlwaysRenderSolid)
		{
			Shape::SetShapeColor(BoxComponent, NewColor, true);
			BoxComponent.bAlwaysRenderSolid = true;
			BoxComponent.MarkRenderStateDirty();
		}

		return BoxComponent;
	}

	UFUNCTION(BlueprintOverride)
	private void Tick(float DeltaTime)
	{
		for (auto Elem : VisualizationComponents)
		{
			if (Elem.Value.LastUsedFrame < GFrameNumber - 1)
			{
				auto Actor = Elem.Value.TemporaryActor.Get();
				if (Actor != nullptr)
					Actor.DestroyActor();
				Elem.RemoveCurrent();
			}
		}

		for (int i = VisualizationAnimations.Num() - 1; i >= 0; --i)
		{
			if (VisualizationAnimations[i].LastUsedFrame < GFrameNumber - 1)
			{
				auto Actor = VisualizationAnimations[i].TemporaryActor.Get();
				if (Actor != nullptr)
					Actor.DestroyActor();
				VisualizationAnimations.RemoveAt(i);
			}
		}
	}
}

mixin void DrawSolidBox(
	UHazeScriptComponentVisualizer Visualizer,
	FInstigator Instigator,
	FVector Location,
	FQuat Rotation,
	FVector Extents,
	FLinearColor Color,
	float Opacity = 1,
	float EdgeThickness = 0.0)
{
	UEditorVisualizationSubsystem::Get().DrawSolidBox(Instigator, Location, Rotation, Extents, Color, Opacity);
	
	if(EdgeThickness > KINDA_SMALL_NUMBER)
		Visualizer.DrawWireBox(Location, Extents, Rotation, Color, EdgeThickness);
}