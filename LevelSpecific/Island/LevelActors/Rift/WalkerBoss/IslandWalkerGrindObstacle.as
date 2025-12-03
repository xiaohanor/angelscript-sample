event void FIslandWalkerGrindObstacleSignature();

class AIslandWalkerGrindObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeverRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeverRootForwardDestination;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeverRootBackwardDestination;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent ClearCollision;

	UPROPERTY(DefaultComponent)
	UBoxComponent ForwardCollision;

	UPROPERTY(DefaultComponent)
	UBoxComponent BackwardCollision;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = DestinationComp)
	UStaticMeshComponent MainCube;
	default MainCube.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	USceneComponent ProgressBarParent;

	UPROPERTY(DefaultComponent)
	USceneComponent PercentageTextParent;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationPreviewComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandWalkerGrindObstacleVisualizerComponent VisualizerComp;
#endif
	
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem NiagaraEffect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditAnywhere)
	AIslandGrindObstacleListener ListenerRef;

	UPROPERTY(EditAnywhere)
	AIslandsGrindObstacleActivator ActivatorRef;

	UPROPERTY(EditAnywhere)
	bool bMoveObstacleBeforeDestruction = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bMoveObstacleBeforeDestruction", EditConditionHides))
	float MaxDistanceBeforeDestruction = 200.0;

	bool bIsActive = true;
	bool bIsDestroyed;

	UPROPERTY()
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 0.5;
	default MoveAnimation.UseLinearCurveZeroToOne();

	FVector OriginalPosition;
	
	FTransform StartingTransform;
	FQuat StartingRotation = FQuat(FRotator(0,0,0));
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;
	TArray<UMaterialInstanceDynamic> ProgressBarMaterials;
	TArray<AHoverPerchActor> HoverPerchesMovingObstacle;

	FQuat LeverRotation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (ActivatorRef != nullptr)
		{
			EndingTransform = ActivatorRef.GetActorTransform();
			EndingPosition = EndingTransform.GetLocation();
			EndingRotation = EndingTransform.GetRotation();

			DestinationPreviewComp.SetWorldLocation(EndingPosition);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		LeverRotation = LeverRootForwardDestination.GetRelativeTransform().GetRotation();

		ForwardCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnForwardOverlap");
		BackwardCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnBackwardOverlap");

		if(!bMoveObstacleBeforeDestruction)
			ClearCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapClear");

		OriginalPosition = DestinationComp.WorldLocation;

		if (ListenerRef != nullptr)
		{
			ListenerRef.OnCompleted.AddUFunction(this, n"HandleCompleted");
			ListenerRef.OnUpdateDisplay.AddUFunction(this, n"OnUpdateDisplay");
		}
		else
		{
			ProgressBarParent.SetHiddenInGame(true, true);
			PercentageTextParent.SetHiddenInGame(true, true);
		}

		InitDisplay();
	}

	private void InitDisplay()
	{
		for(int i = 0; i < ProgressBarParent.NumChildrenComponents; i++)
		{
			USceneComponent Comp = ProgressBarParent.GetChildComponent(i);
			auto MeshComp = Cast<UStaticMeshComponent>(Comp);
			if(MeshComp == nullptr)
				continue;

			ProgressBarMaterials.Add(MeshComp.CreateDynamicMaterialInstance(0));
		}

		OnUpdateDisplay(1.0);
	}

	UFUNCTION()
	private void OnUpdateDisplay(float PercentageAlpha)
	{
		int Percentage = Math::FloorToInt(PercentageAlpha * 100.0);
		for(UMaterialInstanceDynamic Mat : ProgressBarMaterials)
		{
			Mat.SetScalarParameterValue(n"FillPercentage", PercentageAlpha);
		}

		for(int i = 0; i < PercentageTextParent.NumChildrenComponents; i++)
		{
			USceneComponent Comp = PercentageTextParent.GetChildComponent(i);
			auto TextComp = Cast<UTextRenderComponent>(Comp);
			if(TextComp == nullptr)
				continue;

			TextComp.Text = FText::FromString(f"{Percentage}%");
		}
	}

	UFUNCTION()
	private void OnOverlapClear(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		
		if (!bIsActive)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		OnClear(Player);
	}

	UFUNCTION()
	private void OnForwardOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		
		if (!bIsActive)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
		{
			auto HoverPerchRef = Cast<AHoverPerchActor>(OtherActor);
			if (HoverPerchRef == nullptr)
				return;
			else
				return;
		}
			

		LeverRotation = LeverRootForwardDestination.GetRelativeTransform().GetRotation();

		MoveAnimation.PlayFromStart();

	}

	UFUNCTION()
	private void OnBackwardOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		
		if (!bIsActive)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
		{
			auto HoverPerchRef = Cast<AHoverPerchActor>(OtherActor);
			if (HoverPerchRef == nullptr)
				return;
			else
				return;
		}

		LeverRotation = LeverRootBackwardDestination.GetRelativeTransform().GetRotation();

		MoveAnimation.PlayFromStart();

	}

	void OnClear(AHazePlayerCharacter Player)
	{
		if (!bIsActive)
			return;

		bIsActive = false;

		if (ActivatorRef == nullptr)
		{
			bIsDestroyed = true;
			// AddActorDisable(this);

			if (ListenerRef != nullptr)
				ListenerRef.CheckChildren();
		}
		else
		{
			StartingTransform = DestinationComp.GetWorldTransform();
			StartingPosition = StartingTransform.GetLocation();
			// StartingRotation = StartingTransform.GetRotation();

			EndingTransform = ActivatorRef.GetActorTransform();
			EndingPosition = EndingTransform.GetLocation();
			EndingRotation = EndingTransform.GetRotation();

			if (!MoveAnimation.IsPlaying())
				MoveAnimation.PlayFromStart();
		}

		if (NiagaraEffect != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraEffect, StartingPosition);

		if(ForceFeedback != nullptr)
			Player.PlayForceFeedback(ForceFeedback, false, false, this);

		BP_OnDestruction();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		if (ActivatorRef == nullptr)
			return;

		LeverRoot.SetRelativeRotation(FQuat::SlerpFullPath(StartingRotation, LeverRotation, Alpha));

	}

	UFUNCTION()
	void OnFinished()
	{
		if (ActivatorRef == nullptr)
			return;

		bIsDestroyed = true;

		if (ListenerRef != nullptr)
			ListenerRef.CheckChildren();

		ActivatorRef.ObstacleActivated();
		// AddActorDisable(this);
		DestinationComp.SetWorldLocation(OriginalPosition);
	}

	UFUNCTION()
	void Respawn()
	{
		bIsActive = true;
		bIsDestroyed = false;
		RotateRoot.RelativeRotation = FRotator::ZeroRotator;
		LeverRoot.SetRelativeRotation(FRotator(0,0,0));
		BP_OnRespawn();
		RemoveActorDisable(this);
		DestinationComp.SetWorldLocation(OriginalPosition);
		
		if (ActivatorRef != nullptr)
			ActivatorRef.ObstacleDeactivated();
	}

	UFUNCTION()
	void HandleCompleted()
	{
		if (ActivatorRef != nullptr)
			ActivatorRef.ObstacleCompleted();
	}

	FTransform GetMainCubeTransformWithRotation(float Angle) const
	{
		FTransform CubeTransformRelativeToRotateRoot = MainCube.WorldTransform.GetRelativeTransform(RotateRoot.WorldTransform);
		FTransform RotateRootTransform = RotateRoot.WorldTransform;
		FQuat RotRootQuat = RotateRootTransform.Rotation;
		RotateRootTransform.Rotation = Math::RotatorFromAxisAndAngle(RotRootQuat.ForwardVector, Angle).Quaternion() * RotRootQuat;
		return CubeTransformRelativeToRotateRoot * RotateRootTransform;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDestruction() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnRespawn() {}
}

#if EDITOR
class UIslandWalkerGrindObstacleVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandWalkerGrindObstacleVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandWalkerGrindObstacleVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Obstacle = Cast<AIslandWalkerGrindObstacle>(Component.Owner);

		FTransform CubeTransform1 = Obstacle.GetMainCubeTransformWithRotation(Obstacle.MaxDistanceBeforeDestruction);
		FTransform CubeTransform2 = Obstacle.GetMainCubeTransformWithRotation(-Obstacle.MaxDistanceBeforeDestruction);
		FVector Extents = Obstacle.MainCube.GetComponentLocalBoundingBox().Extent * Obstacle.MainCube.WorldScale;
		DrawWireBox(CubeTransform1.Location, Extents, CubeTransform1.Rotation, FLinearColor::Red, 3);
		DrawWireBox(CubeTransform2.Location, Extents, CubeTransform2.Rotation, FLinearColor::Red, 3);
	}
}
#endif