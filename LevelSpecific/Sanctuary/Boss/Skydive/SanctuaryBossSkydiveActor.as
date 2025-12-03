event void FSanctuaryBossSkydiveActorSignature();

struct FSanctuaryBossSkydiveActorData
{
	UPROPERTY()
	float Distance = 0.0;

	UPROPERTY()
	AActor TriggerActor;
}

class USanctuaryBossSkydiveActorVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryBossSkydiveVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto SkydiveActor = Cast<ASanctuaryBossSkydiveActor>(Component.Owner);

		if (SkydiveActor.SplineActor == nullptr)
			return;

		float Spacing = 500.0;
		float Segments = SkydiveActor.SplineActor.Spline.SplineLength / Spacing;
		for (int i = 0; i < Segments; i++)
		{
			FTransform Transform = SkydiveActor.SplineActor.Spline.GetWorldTransformAtSplineDistance(i * Spacing);
			DrawCircle(Transform.Location, SkydiveActor.ConstrainRadius, FLinearColor::Green, 10.0, Transform.Rotation.ForwardVector, 24);
		}

		for (auto AttackData : SkydiveActor.AttackData)
		{
			if (AttackData.TriggerActor == nullptr)
				continue;

			FVector DistanceLocation = SkydiveActor.SplineActor.Spline.GetWorldLocationAtSplineDistance(AttackData.Distance);
			DrawPoint(DistanceLocation, FLinearColor::Green, 40.0);
			DrawDashedLine(DistanceLocation, AttackData.TriggerActor.ActorLocation, FLinearColor::Green, 5.0, 20.0);
		}
	}
}

class USanctuaryBossSkydiveVisualizerComponent : UActorComponent
{

}

UCLASS(HideCategories = "InternalHiddenObjects")
class ASanctuaryBossSkydiveActor : AHazeCameraActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

    UPROPERTY(OverrideComponent = Camera, ShowOnActor)
    UFocusTargetCamera Camera;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CameraFocusTarget;

	UPROPERTY(DefaultComponent)
	UCameraWeightedTargetComponent FocusTargetComponent;

	UPROPERTY(DefaultComponent, EditDefaultsOnly)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryBossSkydiveVisualizerComponent VisualizerComponent;

	UPROPERTY(EditAnywhere)
	float Speed = 3000.0;

	UPROPERTY(EditAnywhere)
	float ForwardDistance = 1000.0;

	UPROPERTY(EditAnywhere)
	float ConstrainRadius = 500.0;

	UPROPERTY(EditAnywhere)
	float HydraOffset = 0.0;

	UPROPERTY(EditAnywhere)
	FTransform MioStartTransform;

	UPROPERTY(EditAnywhere)
	FTransform ZoeStartTransform;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossHydraBase HydraBase;

	FSplinePosition SplinePosition;

	UPROPERTY(EditAnywhere)
	TArray<FSanctuaryBossSkydiveActorData> AttackData;
	int AttackIndex = 0;

	FVector DeltaMove;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		UpdateAttackActors();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto KeepInViewData = Cast<UCameraFocusTargetUpdater>(CameraData);
		auto& Settings = KeepInViewData.UpdaterSettings;
		Settings.Init(HazeUser);
	
		#if EDITOR

		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			KeepInViewData.FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();
			KeepInViewData.PrimaryTargets = FocusTargetComponent.GetEditorPreviewPrimaryTargets();
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				KeepInViewData.FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
				KeepInViewData.PrimaryTargets = FocusTargetComponent.GetPrimaryTargetsOnly(PlayerOwner);
			}
		}

		KeepInViewData.UseFocusLocation();		
	}

	UFUNCTION(BlueprintOverride)	
	void BeginPlay()
	{
		if (SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);
		}
	
		if (HydraBase != nullptr)
			HydraOffset = HydraBase.RootComponent.RelativeLocation.X;
	}

	void UpdateAttackActors()
	{
		AttackData.Reset();

		if (SplineActor != nullptr)
		{
			TArray<AActor> EditorAttackActors;
			EditorAttackActors = Editor::GetAllEditorWorldActorsOfClass(ASanctuaryBossSkydiveAttackActor);

			for (auto EditorAttackActor : EditorAttackActors)
			{
				auto SkydiveAttackActor = Cast<ASanctuaryBossSkydiveAttackActor>(EditorAttackActor);
				if (SkydiveAttackActor == nullptr)
					continue;

				SkydiveAttackActor.Spline = SplineActor.Spline;

				float Distance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(SkydiveAttackActor.ActorLocation);

				FSanctuaryBossSkydiveActorData Data;
				Data.Distance = Distance;
				Data.TriggerActor = SkydiveAttackActor;

				int InsertIndex = 0;
				for (int i = 0; i < AttackData.Num(); i++)
				{
					if (Distance > AttackData[i].Distance)
					{
						if (AttackData.IsValidIndex(i + 1) && Distance > AttackData[i + 1].Distance)
						{
							continue;
						}
						else
						{
							InsertIndex = i + 1;
							break;
						}
					}
				}

				AttackData.Insert(Data, InsertIndex);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePosition.Move(Speed * DeltaSeconds);

		float MinRemainingDistance = Math::Min(HydraOffset, Spline.SplineLength - SplinePosition.CurrentSplineDistance); 
		HydraBase.RootComponent.RelativeLocation = FVector(MinRemainingDistance, 0.0, 0.0);

		DeltaMove = SplinePosition.WorldLocation - ActorLocation;

		SetActorLocationAndRotation(
			SplinePosition.WorldLocation,
			SplinePosition.WorldRotation
		);
	
		while (AttackIndex < AttackData.Num() && SplinePosition.CurrentSplineDistance > AttackData[AttackIndex].Distance)
		{
			auto TriggerComp = USanctuaryBossSkydiveTriggerComponent::Get(AttackData[AttackIndex].TriggerActor);
			if (TriggerComp != nullptr)
				TriggerComp.Trigger();

			AttackIndex++;
		}
	}

	UFUNCTION(DevFunction)
	void StartSkydive()
	{
		SetActorTickEnabled(true);

		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);

		for (auto Player : Game::Players)
		{
			Player.ActivateCamera(Camera, 0.0, this, EHazeCameraPriority::VeryHigh);

			FHazeCameraWeightedFocusTargetInfo FocusTarget;
			FocusTarget.SetFocusToComponent(CameraFocusTarget);
			FocusTargetComponent.AddFocusTarget(FocusTarget, this);

			CapabilityRequestComponent.StartInitialSheetsAndCapabilities(Player, this);

			auto PlayerComp = USanctuaryBossSkydivePlayerComponent::Get(Player);
			PlayerComp.SkydiveActor = this;
		}

		BP_StartSkydive();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartSkydive() { }

	UFUNCTION(DevFunction)
	void EndSkydive()
	{
		if (!IsActorTickEnabled())
			return;

		SetActorTickEnabled(false);

		Game::Mio.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
		
		for (auto Player : Game::Players)
		{
			Player.DeactivateCameraByInstigator(this);

		//	FocusTargetComponent.BP_RemoveAllAddFocusTargetsByInstigator(this); // Why BP_ ???
		
			CapabilityRequestComponent.StopInitialSheetsAndCapabilities(Player, this);
		}
	
		BP_EndSkydive();
	}

	UFUNCTION(BlueprintEvent)
	void BP_EndSkydive() { }
};