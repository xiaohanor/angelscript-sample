
event void FGameShowHeightAdjustableFinishedMovingEvent();
event void FGameShowHeightAdjustableStartedMovingEvent();

UCLASS(NotBlueprintable)
class UGameShowArenaHeightAdjustableComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "HeightAdjustableComponent")
	FVector MoveOffset;

	private FVector OffsetLocation;
	private FVector StartLocation;

	private float TotalMoveDuration = 0;
	private float CurrentMoveDuration = 0;

	UPROPERTY(EditAnywhere, Category = "HeightAdjustableComponent")
	float DefaultMoveToOffsetDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "HeightAdjustableComponent")
	float DefaultMoveFromOffsetDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "HeightAdjustableComponent", meta = (EditCondition = "!bStartMovingTowardsOffsetOnActivated"))
	bool bStartMovingTowardsStartOnActivated = false;
	UPROPERTY(EditAnywhere, Category = "HeightAdjustableComponent", meta = (EditCondition = "!bStartMovingTowardsStartOnActivated"))
	bool bStartMovingTowardsOffsetOnActivated = false;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "HeightAdjustableComponent")
	bool bVisualizeMovement = false;
	UPROPERTY(EditInstanceOnly, Category = "HeightAdjustableComponent")
	bool bVisualizeMoveToOffset = false;
	UPROPERTY(EditInstanceOnly, meta = (UIMin = 0.0, UIMax = 1.0), Category = "HeightAdjustableComponent")
	float VisualizationTimeScale = 1;
#endif

	bool bIsMovingToStart = false;
	default ComponentTickEnabled = false;

	UPROPERTY()
	FGameShowHeightAdjustableStartedMovingEvent OnStartedMoving;

	UPROPERTY()
	FGameShowHeightAdjustableFinishedMovingEvent OnFinishedMoving;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = Owner.ActorLocation;
		OffsetLocation = Owner.ActorLocation + MoveOffset;

		ComponentTickEnabled = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (bStartMovingTowardsOffsetOnActivated)
		{
			Owner.SetActorLocation(StartLocation);
			TotalMoveDuration = DefaultMoveToOffsetDuration;
			CurrentMoveDuration = 0;
			ComponentTickEnabled = true;
		}
		else if (bStartMovingTowardsStartOnActivated)
		{
			Owner.SetActorLocation(OffsetLocation);
			TotalMoveDuration = DefaultMoveFromOffsetDuration;
			CurrentMoveDuration = 0;
			ComponentTickEnabled = true;
			bIsMovingToStart = true;
		}
	}

	FVector GetOffsetLocation() const
	{
		return OffsetLocation;
	}

	FVector GetStartLocation() const
	{
		return StartLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentMoveDuration += DeltaSeconds;
		float Alpha = Math::Saturate(CurrentMoveDuration / TotalMoveDuration);
		FVector NewLocation;

		if (bIsMovingToStart)
		{
			NewLocation = Math::SinusoidalOut(OffsetLocation, StartLocation, Alpha);
		}
		else
		{
			NewLocation = Math::SinusoidalIn(StartLocation, OffsetLocation, Alpha);
		}
		Owner.SetActorLocation(NewLocation);
		if (Math::IsNearlyEqual(Alpha, 1.0))
		{
			ComponentTickEnabled = false;
			OnFinishedMoving.Broadcast();
		}
	}

	/**
	 * Move to StartLocation + MoveOffset over duration.
	 * @param Duration Total movement duration in seconds.
	 * @param bSnapToInitialLocation Snaps location to OffsetLocation
	 */
	UFUNCTION(DevFunction, meta = (Duration = "1.0"))
	void MoveToOffsetLocation(float Duration = DefaultMoveToOffsetDuration, bool bSnapInitialLocation = false)
	{
		if (bSnapInitialLocation)
		{
			Owner.SetActorLocation(StartLocation);
		}
		if ((Owner.ActorLocation - OffsetLocation).IsNearlyZero())
			return;

		TotalMoveDuration = Duration;
		CurrentMoveDuration = 0;
		bIsMovingToStart = false;

		OnStartedMoving.Broadcast();
		if (TotalMoveDuration > 0)
		{
			ComponentTickEnabled = true;
		}
		else
		{
			Owner.SetActorLocation(OffsetLocation);
			ComponentTickEnabled = false;
			OnFinishedMoving.Broadcast();
		}
	}

	/**
	 * Move to StartLocation over duration.
	 * @param Duration Total movement duration in seconds.
	 * @param bSnapToInitialLocation Snaps location to StartLocation
	 */
	UFUNCTION(DevFunction, meta = (Duration = "2.0"))
	void MoveToStartLocation(float Duration = DefaultMoveFromOffsetDuration, bool bSnapInitialLocation = false)
	{
		if (bSnapInitialLocation)
		{
			Owner.SetActorLocation(OffsetLocation);
		}
		if ((Owner.ActorLocation - StartLocation).IsNearlyZero())
			return;

		TotalMoveDuration = Duration;
		CurrentMoveDuration = 0;
		OnStartedMoving.Broadcast();
		bIsMovingToStart = true;
		if (TotalMoveDuration > 0)
		{
			ComponentTickEnabled = true;
		}
		else
		{
			Owner.SetActorLocation(StartLocation);
			ComponentTickEnabled = false;
			OnFinishedMoving.Broadcast();
		}
	}
};

#if EDITOR
class UGameShowArenaHeightAdjustableVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGameShowArenaHeightAdjustableComponent;
	UMaterialInterface DebugMaterial;
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UGameShowArenaHeightAdjustableComponent>(Component);
		if (Comp == nullptr)
			return;

		if (DebugMaterial == nullptr)
			DebugMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/Materials/M_Wireframe_Sub.M_Wireframe_Sub"));

		if (Comp.Owner.IsTemporarilyHiddenInEditor())
			return;

		FVector SimulatedActorLocation = Comp.Owner.ActorLocation;
		FVector OffsetLocation = SimulatedActorLocation + Comp.MoveOffset;
		if (Comp.bVisualizeMovement)
		{
			if (Comp.bVisualizeMoveToOffset)
			{
				float Alpha = Math::Fmod(Time::GameTimeSeconds * Comp.VisualizationTimeScale, Comp.DefaultMoveToOffsetDuration) / Comp.DefaultMoveToOffsetDuration;
				SimulatedActorLocation = Math::SinusoidalIn(SimulatedActorLocation, OffsetLocation, Alpha);
			}
			else
			{
				float Alpha = Math::Fmod(Time::GameTimeSeconds * Comp.VisualizationTimeScale, Comp.DefaultMoveFromOffsetDuration) / Comp.DefaultMoveFromOffsetDuration;
				SimulatedActorLocation = Math::SinusoidalOut(OffsetLocation, SimulatedActorLocation, Alpha);
			}
			DrawWorldString("SimulatedLocation", SimulatedActorLocation, FLinearColor::Yellow, 1, 10000, false, true);
		}
		DrawWorldString("OffsetLocation", OffsetLocation, FLinearColor::Yellow, 2, 5000, true, true);

		TArray<UStaticMeshComponent> MeshComps;
		Comp.Owner.RootComponent.GetChildrenComponentsByClass(UStaticMeshComponent, true, MeshComps);
		for (auto MeshComp : MeshComps)
		{
			FVector WorldOffset = MeshComp.WorldLocation - Comp.Owner.ActorLocation;
			FVector NewLocation;
			if (!Comp.bVisualizeMovement)
				NewLocation = OffsetLocation + WorldOffset;
			else
				NewLocation = SimulatedActorLocation + WorldOffset;

			DrawMeshWithMaterial(MeshComp.StaticMesh, DebugMaterial, NewLocation, MeshComp.GetWorldRotation().Quaternion(), MeshComp.GetWorldScale());
		}
	}
}
#endif