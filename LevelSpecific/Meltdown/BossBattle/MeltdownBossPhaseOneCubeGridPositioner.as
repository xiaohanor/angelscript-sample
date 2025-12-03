struct FCubeGridPosition
{
	TArray<FTransform> Transforms;
}

class AMeltdownBossPhaseOneCubeGridPositioner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UMeltdownCubeGridPositionerComponent Positioner;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AActor> CubeGrids;

	UPROPERTY(EditAnywhere, Category = "Setup")
	int PositionCount = 1;

	UPROPERTY(EditAnywhere, EditConst, Category = "Editing")
	int CurrentlyEditingPosition = 0;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	TArray<FTransform> EditingTransforms;

	UPROPERTY(EditAnywhere, EditConst, Category = "Data")
	TArray<FCubeGridPosition> StoredPositions;

	private TArray<FTransform> OriginalTransforms;
	private TArray<FHazeAcceleratedVector> AccelPositions;
	private TArray<FHazeAcceleratedRotator> AccelRotations;
	private TArray<FHazeAcceleratedVector> AccelScales;

#if EDITOR
	private TArray<FTransform> EditorOriginalTransforms;
#endif

	private int CurrentTarget = -1;
	private float CurrentDuration = 0.0;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = 0, Count = CubeGrids.Num(); i < Count; ++i)
		{
			FTransform Transform;
			if (CubeGrids[i] != nullptr)
				Transform = CubeGrids[i].ActorTransform.GetRelativeTransform(ActorTransform);

			OriginalTransforms.Add(Transform);

			FHazeAcceleratedVector Position;
			Position.SnapTo(Transform.Location);
			FHazeAcceleratedRotator Rotation;
			Rotation.SnapTo(Transform.Rotator());
			FHazeAcceleratedVector Scale;
			Scale.SnapTo(Transform.Scale3D);

			AccelPositions.Add(Position);
			AccelRotations.Add(Rotation);
			AccelScales.Add(Scale);
		}
		
		SceneComponent::BindOnSceneComponentMoved(Root, FOnSceneComponentMoved(this, n"OnMoved"));
	}

	UFUNCTION()
	private void OnMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void AccelerateToPosition(int Position, float Duration)
	{
		CurrentTarget = Position;
		CurrentDuration = Duration;
		SetActorTickEnabled(true);
		DisableOtherPositioners();
	}

	UFUNCTION()
	void ResetToOriginalPosition(float Duration)
	{
		CurrentTarget = -1;
		CurrentDuration = Duration;
		SetActorTickEnabled(true);
		DisableOtherPositioners();
	}

	void DisableOtherPositioners()
	{
		for (AMeltdownBossPhaseOneCubeGridPositioner OtherPositioner : TListedActors<AMeltdownBossPhaseOneCubeGridPositioner>())
		{
			if (OtherPositioner != this)
				OtherPositioner.SetActorTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bAnyMoved = false;

		for (int i = 0, Count = CubeGrids.Num(); i < Count; ++i)
		{
			FTransform TargetTransform;
			if (StoredPositions.IsValidIndex(CurrentTarget))
				TargetTransform = StoredPositions[CurrentTarget].Transforms[i];
			else
				TargetTransform = OriginalTransforms[i];

			AccelPositions[i].AccelerateTo(TargetTransform.Location, CurrentDuration, DeltaSeconds);
			AccelRotations[i].AccelerateTo(TargetTransform.Rotator(), CurrentDuration, DeltaSeconds);
			AccelScales[i].AccelerateTo(TargetTransform.Scale3D, CurrentDuration, DeltaSeconds);

			if (IsValid(CubeGrids[i]))
			{
				FTransform NewTransform = FTransform(AccelRotations[i].Value, AccelPositions[i].Value, AccelScales[i].Value) * ActorTransform;
				if (!NewTransform.Equals(CubeGrids[i].ActorTransform))
				{
					CubeGrids[i].ActorTransform = NewTransform;
					bAnyMoved = true;
				}
			}
		}

		if (!bAnyMoved)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		if (EditorOriginalTransforms.Num() != CubeGrids.Num())
		{
			EditorOriginalTransforms.Reset();
			for (int i = 0, Count = CubeGrids.Num(); i < Count; ++i)
			{
				if (CubeGrids[i] != nullptr)
					EditorOriginalTransforms.Add(CubeGrids[i].ActorTransform);
				else
					EditorOriginalTransforms.Add(FTransform());
			}
		}
#endif

		if (PositionCount < 1)
			PositionCount = 1;

		for (int i = StoredPositions.Num(); i < PositionCount; ++i)
		{
			FCubeGridPosition Pos;
			for (auto Grid : CubeGrids)
			{
				FTransform Transform;
				if (Grid != nullptr)
					Transform = Grid.ActorTransform.GetRelativeTransform(ActorTransform);
				Pos.Transforms.Add(Transform);
			}

			StoredPositions.Add(Pos);
		}

		StoredPositions.SetNum(PositionCount);

		int GridCount = CubeGrids.Num();
		for (int n = 0; n < GridCount; ++n)
		{
			FTransform Transform;
			if (CubeGrids[n] != nullptr)
				Transform = CubeGrids[n].ActorTransform.GetRelativeTransform(ActorTransform);

			if (n < EditingTransforms.Num())
			{
				if (EditingTransforms[n].Equals(FTransform()))
					EditingTransforms[n] = Transform;
			}
			else
			{
				EditingTransforms.Add(Transform);
			}
		}
		EditingTransforms.SetNum(CubeGrids.Num());

		for (int i = 0; i < PositionCount; ++i)
		{
			FCubeGridPosition& Pos = StoredPositions[i];
			for (int n = 0; n < GridCount; ++n)
			{
				FTransform Transform;
				if (CubeGrids[n] != nullptr)
					Transform = CubeGrids[n].ActorTransform.GetRelativeTransform(ActorTransform);

				if (n < Pos.Transforms.Num())
				{
					if (Pos.Transforms[n].Equals(FTransform()))
						Pos.Transforms[n] = Transform;
				}
				else
				{
					Pos.Transforms.Add(Transform);
				}
			}
			Pos.Transforms.SetNum(CubeGrids.Num());
		}

		StoredPositions[CurrentlyEditingPosition].Transforms = EditingTransforms;
	}

	UFUNCTION(CallInEditor, Category = "Editing")
	void EditPosition(int Position)
	{
		CurrentlyEditingPosition = Math::Clamp(Position, 0, PositionCount - 1);
		EditingTransforms = StoredPositions[CurrentlyEditingPosition].Transforms;
	}

#if EDITOR
	/**
	 * Apply the current editing position's transforms to the actors in the level.
	 */
	UFUNCTION(CallInEditor, Category = "Application")
	private void ApplyTransformsToActors()
	{
		for (int i = 0, Count = EditingTransforms.Num(); i < Count; ++i)
		{
			if (CubeGrids.IsValidIndex(i) && CubeGrids[i] != nullptr)
				CubeGrids[i].ActorTransform = EditingTransforms[i] * ActorTransform;
		}
	}

	/**
	 * Copy the transforms of the current actors in the level into the position being edited.
	 */
	UFUNCTION(CallInEditor, Category = "Application")
	private void CopyTransformsFromActors()
	{
		for (int i = 0, Count = EditingTransforms.Num(); i < Count; ++i)
		{
			if (CubeGrids.IsValidIndex(i) && CubeGrids[i] != nullptr)
				EditingTransforms[i] = CubeGrids[i].ActorTransform.GetRelativeTransform(ActorTransform);
		}

		RerunConstructionScripts();
	}

	/**
	 * Reset the transforms of the actors in the level to their original position
	 */
	UFUNCTION(CallInEditor, Category = "Application")
	private void ResetActorTransforms()
	{
		for (int i = 0, Count = EditorOriginalTransforms.Num(); i < Count; ++i)
		{
			if (CubeGrids.IsValidIndex(i) && CubeGrids[i] != nullptr)
				CubeGrids[i].ActorTransform = EditorOriginalTransforms[i];
		}
	}
#endif
};

class UMeltdownCubeGridPositionerComponent : USceneComponent
{
};

#if EDITOR
class UMeltdownCubeGridPositionerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMeltdownCubeGridPositionerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		AMeltdownBossPhaseOneCubeGridPositioner Positioner = Cast<AMeltdownBossPhaseOneCubeGridPositioner>(Component.Owner);

		for (int i = 0, Count = Positioner.EditingTransforms.Num(); i < Count; ++i)
		{
			auto CubeGrid = Positioner.CubeGrids[i];
			if (!IsValid(CubeGrid))
				continue;

			FBox BoundingBox = CubeGrid.GetActorLocalBoundingBox(true);
			FTransform LocalTransform = Positioner.EditingTransforms[i];
			LocalTransform.AddToTranslation(LocalTransform.TransformVector(BoundingBox.Center));
			FTransform Transform = LocalTransform * Positioner.ActorTransform;
			DrawSolidBox(CubeGrid, Transform.Location, Transform.Rotation, BoundingBox.Extent, FLinearColor::White, Opacity = 0.5);
		}
	}
}
#endif