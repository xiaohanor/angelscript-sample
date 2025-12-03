UCLASS(Abstract)
class ATundra_River_TotemPuzzle_MovingRoot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase RootsMesh;
	default RootsMesh.bVisible = false;
#if EDITOR
	default RootsMesh.bUpdateAnimationInEditor = true;
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	USceneComponent RotatingRoot;

	UPROPERTY(DefaultComponent, Attach = RotatingRoot)
	USceneComponent ExtendingRoot;

	UPROPERTY(DefaultComponent, Attach = ExtendingRoot)
	UStaticMeshComponent MovingRootMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedAlpha;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTundra_River_TotemPuzzle_MovingRoot_VisualizerComponent VisualizerComp;
#endif

	UPROPERTY(EditInstanceOnly)
	AActor LifeGivingActor;
	
	UPROPERTY(EditInstanceOnly)
	ATundra_River_TotemPuzzle_TreeControl TreeControl;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve HitCurve;
	default HitCurve.AddDefaultKey(0.0, 0.0);
	default HitCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveBackCurve;
	default MoveBackCurve.AddDefaultKey(0.0, 1.0);
	default MoveBackCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(EditDefaultsOnly)
	float HitDuration = 0.2;

	UPROPERTY(EditDefaultsOnly)
	float MoveBackDuration = 0.3;

	UPROPERTY(EditAnywhere)
	float TotemLockDuration = 0.5;

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<AActor> EditorActorToSnapRootsTo;

	UPROPERTY(EditAnywhere)
	FVector LocalRootTipDefaultLocation = FVector(0.0, 0.0, 250.0);

	UPROPERTY(EditAnywhere)
	FRotator LocalRootTipDefaultRotation = FRotator(-15.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	FVector LocalRootTipHitTargetLocation = FVector(200.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	FRotator LocalRootTipHitTargetRotation = FRotator(-60.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	bool bPreviewTargetInEditor = false;

	UPROPERTY(EditAnywhere)
	TArray<APropLine> PropLines;

	UPROPERTY(EditAnywhere)
	float SphereRadius = 400.0;

	UPROPERTY(EditAnywhere)
	FVector StartSphereMaskRelativeLocation = FVector(500.0, -575.0, 200.0);

	UPROPERTY(EditAnywhere)
	FVector EndSphereMaskRelativeLocation = FVector(500.0, 515.0, 200.0);

	ETundraTotemIndex CurrentTargetTotemIndex = ETundraTotemIndex::Middle;
	ATundra_River_TotemPuzzle CurrentTargetTotem;
	UTundraLifeReceivingComponent LifeComp;
	TOptional<float> TimeOfSetTarget;
	int PreviousInputTarget;
	float MaxInputSize;
	FVector CurrentLocalRootTipLocation;
	FRotator CurrentLocalRootTipRotation;
	FHazeAcceleratedFloat AcceleratedSplineAlpha;
	TArray<UMeshComponent> PropLineMeshes;
	FHazeAcceleratedFloat AcceleratedLifeGivingAlpha;
	bool bLifeGiving = false;
	float TargetAlpha;
	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		SyncedAlpha.Value = 0.5;
		CurrentLocalRootTipLocation = LocalRootTipDefaultLocation;
		CurrentLocalRootTipRotation = LocalRootTipDefaultRotation;

		if(TreeControl != nullptr)
		{
			TreeControl.ChangedTargetTotem.AddUFunction(this, n"OnChangedTargetTotem");
		}
		if(LifeGivingActor != nullptr)
		{
			LifeComp = UTundraLifeReceivingComponent::Get(LifeGivingActor);
			LifeComp.OnInteractStart.AddUFunction(this, n"OnLifegiveStart");
			LifeComp.OnInteractStop.AddUFunction(this, n"OnLifegiveStop");
			AcceleratedSplineAlpha.SnapTo(SyncedAlpha.Value);
		}

		for(APropLine PropLine : PropLines)
		{
			PropLine.GetComponentsByClass(UMeshComponent, PropLineMeshes);
		}
		
		HandleRootsGlow(0.0);
	}

	UFUNCTION()
	private void OnChangedTargetTotem(ATundra_River_TotemPuzzle TargetTotem)
	{
		if(CurrentTargetTotem != nullptr && bLifeGiving)
			UTundra_River_TotemPuzzle_MovingRoot_EffectHandler::Trigger_OnTotemStopBeingTargeted(this, FTundra_River_TotemPuzzle_MovingRoot_SwitchTotem_EffectParams(CurrentTargetTotem));

		CurrentTargetTotemIndex = TargetTotem.TotemIndex;
		CurrentTargetTotem = TargetTotem;

		if(bLifeGiving)
			UTundra_River_TotemPuzzle_MovingRoot_EffectHandler::Trigger_OnTotemStartBeingTargeted(this, FTundra_River_TotemPuzzle_MovingRoot_SwitchTotem_EffectParams(CurrentTargetTotem));
	}

	UFUNCTION()
	private void OnLifegiveStop(bool bForced)
	{
		if(CurrentTargetTotem != nullptr)
			UTundra_River_TotemPuzzle_MovingRoot_EffectHandler::Trigger_OnTotemStopBeingTargeted(this, FTundra_River_TotemPuzzle_MovingRoot_SwitchTotem_EffectParams(CurrentTargetTotem));

		UTundra_River_TotemPuzzle_MovingRoot_EffectHandler::Trigger_OnInteractStop(this);

		bLifeGiving = false;
		SnapbackDetector.ClearSnapbackDetection();
	}

	UFUNCTION()
	private void OnLifegiveStart(bool bForced)
	{
		if(CurrentTargetTotem != nullptr)
			UTundra_River_TotemPuzzle_MovingRoot_EffectHandler::Trigger_OnTotemStartBeingTargeted(this, FTundra_River_TotemPuzzle_MovingRoot_SwitchTotem_EffectParams(CurrentTargetTotem));

		UTundra_River_TotemPuzzle_MovingRoot_EffectHandler::Trigger_OnInteractStart(this);
		bLifeGiving = true;
		AcceleratedSplineAlpha.SnapTo(SyncedAlpha.Value);

		TargetAlpha = GetAlphaFromTargetTotem(CurrentTargetTotemIndex);
		SyncedAlpha.Value = TargetAlpha;
		SyncedAlpha.SnapRemote();
		AcceleratedSplineAlpha.SnapTo(SyncedAlpha.Value);
		TreeControl.SetTargetTotem(ETundraTotemIndex::Middle);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(LifeComp.IsCurrentlyLifeGiving())
		{
			UpdateTargetTotem();
			MoveRoot(DeltaSeconds);
		}

		HandleRootsGlow(DeltaSeconds);
	}

	void UpdateTargetTotem()
	{
		float PositionAlpha = Math::GetMappedRangeValueClamped(FVector2D(-450, 450), FVector2D(0, 1), MovingRoot.RelativeLocation.Y);
		TreeControl.SetTargetTotem(GetTargetTotemFromAlpha(PositionAlpha));
	}

	void MoveRoot(float DeltaTime)
	{
		if(HasControl())
		{
			FVector Stick = FVector(LifeComp.RawHorizontalInput, 0.0, 0.0);
			FVector Input = SnapbackDetector.RemoveStickSnapbackJitter(Stick, Stick);
			float InputSize = Math::Abs(Input.X);
			if(InputSize > 0.2 && InputSize > MaxInputSize - 0.2)
			{
				int InputTarget = Math::RoundToInt(Math::Sign(Input.X));
				if(PreviousInputTarget != InputTarget)
					TimeOfSetTarget.Reset();

				TrySetTargetTotem(Input.X);
				PreviousInputTarget = InputTarget;
				if(InputSize > MaxInputSize)
					MaxInputSize = InputSize;
			}
			else
			{
				TimeOfSetTarget.Reset();
				PreviousInputTarget = 0;
				MaxInputSize = 0;
			}

			SyncedAlpha.Value = Math::FInterpConstantTo(SyncedAlpha.Value, TargetAlpha, DeltaTime, 5.0);

#if !RELEASE
			TEMPORAL_LOG(this)
				.Value("RawInput", Stick.X)
				.Value("InputNoSnapback", Input.X)
				.Value("TimeOfSetTarget.IsSet()", TimeOfSetTarget.IsSet())
				.Value("MaxInputSize", MaxInputSize)
				.Value("CurrentTargetTotemIndex", CurrentTargetTotemIndex)
				.Value("PreviousInputTarget", PreviousInputTarget)
				.Value("TargetAlpha", TargetAlpha)
			;

			if(TimeOfSetTarget.IsSet())
				TEMPORAL_LOG(this).Value("TimeOfSetTarget", TimeOfSetTarget.Value);
#endif
		}

		AcceleratedSplineAlpha.AccelerateTo(SyncedAlpha.Value, 0.5, DeltaTime);
		float AcceleratedPosition = Math::Lerp(-430, 430, AcceleratedSplineAlpha.Value);
		FVector CurrentPosition = MovingRoot.RelativeLocation;
		MovingRoot.RelativeLocation = FVector(CurrentPosition.X, AcceleratedPosition, CurrentPosition.Z);
	}

	void HandleRootsGlow(float DeltaTime)
	{
		AcceleratedLifeGivingAlpha.AccelerateTo(LifeComp.IsCurrentlyLifeGiving() ? 1.0 : 0.0, 0.5, DeltaTime);
		FVector SphereLocation = Math::Lerp(SphereMaskStartPoint, SphereMaskEndPoint, AcceleratedSplineAlpha.Value);
		for(auto Mesh : PropLineMeshes)
		{
			Mesh.SetColorParameterValueOnMaterials(n"LifeGivingSphere", FLinearColor(SphereLocation.X, SphereLocation.Y, SphereLocation.Z, SphereRadius));
			Mesh.SetScalarParameterValueOnMaterials(n"LifeGivingAlpha", AcceleratedLifeGivingAlpha.Value);
		}
	}

	private void TrySetTargetTotem(float Input)
	{
		TEMPORAL_LOG(this).Status("TrySetTargetTotem", FLinearColor::Green);
		if(TimeOfSetTarget.IsSet() && Time::GetGameTimeSince(TimeOfSetTarget.Value) < 0.25)
		{
			TemporalLogFailReason("Set Target Less Than 0.25 secs ago");
			return;
		}

		ETundraTotemIndex TargetTotem = GetTargetTotemFromAlpha(TargetAlpha);
		if(Input > 0.0 && TargetTotem == ETundraTotemIndex::Right)
		{
			TemporalLogFailReason("Can't Move More Right");
			return;
		}

		if(Input < 0.0 && TargetTotem == ETundraTotemIndex::Left)
		{
			TemporalLogFailReason("Can't Move More Left");
			return;
		}

		int NewIndex = int(TargetTotem) + Math::RoundToInt(Math::Sign(Input));
		ETundraTotemIndex TotemIndex = ETundraTotemIndex(NewIndex);
		CrumbSetTargetTotem(TotemIndex);
		TimeOfSetTarget.Set(Time::GetGameTimeSeconds());
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetTargetTotem(ETundraTotemIndex TotemIndex)
	{
		TargetAlpha = GetAlphaFromTargetTotem(TotemIndex);
	}

	UFUNCTION()
	void LockTotem(ATundra_River_TotemPuzzle Totem)
	{
		TreeControl.GetTargetTotem().LockTotem();
		TimeOfSetTarget.Reset();
	}

	private void TemporalLogFailReason(FString Reason)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Value("Fail Set Target Reason", Reason);
#endif
	}

	float GetAlphaFromTargetTotem(ETundraTotemIndex Totem)
	{
		switch(Totem)
		{
			case ETundraTotemIndex::NONE:
				return 0.5;
			case ETundraTotemIndex::Left:
				return 0.0;
			case ETundraTotemIndex::Middle:
				return 0.5;
			case ETundraTotemIndex::Right:
				return 1.0;
		}
	}

	private ETundraTotemIndex GetTargetTotemFromAlpha(float Alpha)
	{
		if(Alpha < 0.3)
		{
			return ETundraTotemIndex::Left;
		}
		else if(Alpha > 0.3 && Alpha < 0.7)
		{
			return ETundraTotemIndex::Middle;
		}

		return ETundraTotemIndex::Right;
	}

	FVector GetSphereMaskStartPoint() const property
	{
		return ActorTransform.TransformPosition(StartSphereMaskRelativeLocation);
	}

	FVector GetSphereMaskEndPoint() const property
	{
		return ActorTransform.TransformPosition(EndSphereMaskRelativeLocation);
	}
};

struct FTundra_River_TotemPuzzle_MovingRoot_SwitchTotem_EffectParams
{
	FTundra_River_TotemPuzzle_MovingRoot_SwitchTotem_EffectParams(ATundra_River_TotemPuzzle In_Totem)
	{
		Totem = In_Totem;
	}

	UPROPERTY()
	ATundra_River_TotemPuzzle Totem;
}

UCLASS(Abstract)
class UTundra_River_TotemPuzzle_MovingRoot_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInteractStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInteractStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTotemStartBeingTargeted(FTundra_River_TotemPuzzle_MovingRoot_SwitchTotem_EffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTotemStopBeingTargeted(FTundra_River_TotemPuzzle_MovingRoot_SwitchTotem_EffectParams Params) {}
}

#if EDITOR
class UTundra_River_TotemPuzzle_MovingRoot_VisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundra_River_TotemPuzzle_MovingRoot_Visualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundra_River_TotemPuzzle_MovingRoot_VisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto MovingRoot = Cast<ATundra_River_TotemPuzzle_MovingRoot>(Component.Owner);
		DrawWireSphere(MovingRoot.SphereMaskStartPoint, MovingRoot.SphereRadius, FLinearColor::Red, 3.0);
		DrawWireSphere(MovingRoot.SphereMaskEndPoint, MovingRoot.SphereRadius, FLinearColor::Green, 3.0);
	}
}
#endif