struct FIslandRobotArmRotation
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float BaseRotation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float Arm1Rotation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float Arm2Rotation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float Arm3Rotation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float HeadRotation;

	FIslandRobotArmRotation(FIslandRobotArmRotation A, FIslandRobotArmRotation B, float Alpha, float Exponent, FVector2D BaseProgressRange, FVector2D ArmProgressRange, FVector2D HeadArmProgressRange, FVector2D HeadProgressRange)
	{
		float BaseAlpha = Math::GetMappedRangeValueClamped(BaseProgressRange, FVector2D(0, 1), Alpha);
		float ArmAlpha = Math::GetMappedRangeValueClamped(ArmProgressRange, FVector2D(0, 1), Alpha);
		float HeadArmAlpha = Math::GetMappedRangeValueClamped(HeadArmProgressRange, FVector2D(0, 1), Alpha);
		float HeadAlpha = Math::GetMappedRangeValueClamped(HeadProgressRange, FVector2D(0, 1), Alpha);

		if(Exponent > 1)
		{
			// Smooth out the alpha in the visualization, since the animation will interp towards the alphas
			BaseAlpha = Math::EaseInOut(0, 1, BaseAlpha, Exponent);
			ArmAlpha = Math::EaseInOut(0, 1, ArmAlpha, Exponent);
			HeadArmAlpha = Math::EaseInOut(0, 1, HeadArmAlpha, Exponent);
			HeadAlpha = Math::EaseInOut(0, 1, HeadAlpha, Exponent);
		}

		BaseRotation = Math::Lerp(A.BaseRotation, B.BaseRotation, BaseAlpha);
		Arm1Rotation = Math::Lerp(A.Arm1Rotation, B.Arm1Rotation, ArmAlpha);
		Arm2Rotation = Math::Lerp(A.Arm2Rotation, B.Arm2Rotation, ArmAlpha);
		Arm3Rotation = Math::Lerp(A.Arm3Rotation, B.Arm3Rotation, HeadArmAlpha);
		HeadRotation = Math::Lerp(A.HeadRotation, B.HeadRotation, HeadAlpha);
	}
};

enum EJawsPosition
{
	NONE,
	Open,
	Close
}

UCLASS(Abstract)
class AIslandRobotArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase RobotArmMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent MoveCamShakeFFComp;
	
	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent JawsCamShakeFFComp;

	#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	UIslandRobotArmEditorComponent EditorComp;
	#endif

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	AIslandOverloadShootablePanel PanelRef;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	bool bAttachPanel = false;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Meta = (EditCondition = "PanelRef != nullptr"))
	bool bReactToPanel = true;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Meta = (EditCondition = "bAttachPanel"))
	FName PanelSocketName;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	AActor AttachActor;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Meta = (EditCondition = "AttachActor != nullptr"))
	FName AttachActorSocketName;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	ARespawnPoint RespawnPointRef;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Rotation")
	FIslandRobotArmRotation BaseRotation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Rotation")
	FIslandRobotArmRotation TargetRotation;

	//Go to a new base rotation instead of the normal base rotation after reaching the target rotation.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Rotation")
	bool bUseAltBaseRotation = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Rotation", Meta = (EditCondition = "bUseAltBaseRotation"))
	FIslandRobotArmRotation AltBaseRotation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Ranges", Meta = (ClampMin = "0", ClampMax = "1"))
	FVector2D BaseProgressRange = FVector2D(0.0, 0.4);

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Ranges", Meta = (ClampMin = "0", ClampMax = "1"))
	FVector2D ArmProgressRange = FVector2D(0.3, 0.7);

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Ranges", Meta = (ClampMin = "0", ClampMax = "1"))
	FVector2D HeadArmProgressRange = FVector2D(0, 1);

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Ranges", Meta = (ClampMin = "0", ClampMax = "1"))
	FVector2D HeadProgressRange = FVector2D(0.5, 1.0);

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Jaws")
	EJawsPosition JawsInitialPosition = EJawsPosition::NONE;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Jaws")
	EJawsPosition JawsOnReachedTarget = EJawsPosition::NONE;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Jaws")
	EJawsPosition JawsOnReachedBase = EJawsPosition::NONE;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Jaws")
	EJawsPosition JawsOnMoveToTarget = EJawsPosition::NONE;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Jaws")
	EJawsPosition JawsOnMoveToBase = EJawsPosition::NONE;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float MoveForwardDuration = 3.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float MoveBackwardDuration = 3.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float EaseInOutExponent = 2.0;

	UPROPERTY(EditAnywhere, Category = "Visualize")
	bool bShowVisualizer = false;

	#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Visualize")
	bool bAnimateVisualization = false;

	//Visualize the alternate base rotation instead of normal base rotation.
	UPROPERTY(EditAnywhere, Category ="Visualize", Meta = (EditCondition = "bUseAltBaseRotation"))
	bool bVisualizeAltBaseRotation = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bAnimateVisualization"), Category = "Visualize")
	float VisualizeDuration = 5;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bAnimateVisualization", UIMin = "0.0", UIMax = "1.0"), Category = "Visualize")
	float VisualizeProgress = 1.0;
	#endif
	
	UPROPERTY(BlueprintReadOnly)
	bool bHasSnapped = false;

	bool bIsMoving = false;
	bool bHasStoppedMovingOnce = false;
	bool bIsMovingToTarget = true;
	bool bJawsOpen = false;
	float TimeOfStartMove = 0.0;
	float MoveAlpha;
	int WiggleAfterSnap = 0;

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Tools")
	void RunConstructionScriptForAll() 
	{
		TListedActors<AIslandRobotArm> ListedRobotArms;
		for(AIslandRobotArm Arm : ListedRobotArms.Array)
		{
			Arm.RerunConstructionScripts();
			
		}
	}

	UFUNCTION(CallInEditor, Category = "Tools")
	void EnableVisualizerForAll() 
	{
		TListedActors<AIslandRobotArm> ListedRobotArms;
		for(AIslandRobotArm Arm : ListedRobotArms.CopyAndInvalidate())
		{
			Arm.bShowVisualizer = true;
			Editor::NotifyPropertyModified(Arm, n"bShowVisualizer");
		}
	}

	UFUNCTION(CallInEditor, Category = "Tools")
	void DisableVisualizerForAll() 
	{
		TListedActors<AIslandRobotArm> ListedRobotArms;
		for(AIslandRobotArm Arm : ListedRobotArms.CopyAndInvalidate())
		{
			Arm.bShowVisualizer = false;
			Editor::NotifyPropertyModified(Arm, n"bShowVisualizer");
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PanelRef != nullptr && bReactToPanel)
		{
			PanelRef.OnOvercharged.AddUFunction(this, n"HandleOvercharge");
			PanelRef.OnReset.AddUFunction(this, n"HandleReset");
		}

		MoveCamShakeFFComp.AttachToComponent(RobotArmMeshComp, n"Head");
		JawsCamShakeFFComp.AttachToComponent(RobotArmMeshComp, n"Head");

		InitJaws();
	}

	UFUNCTION()
	private void InitJaws()
	{
		if(JawsInitialPosition == EJawsPosition::NONE)
			return;

		if(JawsInitialPosition == EJawsPosition::Open)
		{
			OpenJaws();
		}
		else
		{
			CloseJaws();
		}
	}

	UFUNCTION()
	private void HandleReset()
	{
		BP_HandlePanelReset();
	}

	UFUNCTION()
	private void HandleOvercharge()
	{
		BP_HandlePanelOvercharge();
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandlePanelOvercharge() {}

	UFUNCTION(BlueprintEvent)
	void BP_HandlePanelReset() {}

	UFUNCTION()
	void MoveToTargetPose()
	{
		bIsMoving = true;
		bIsMovingToTarget = true;
		TimeOfStartMove = Time::GetGameTimeSeconds();

		if(PanelRef != nullptr)
			PanelRef.DisablePanel();

		if(JawsOnMoveToTarget != EJawsPosition::NONE)
		{
			if(JawsOnMoveToTarget == EJawsPosition::Open)
			{
				OpenJaws();
			}
			else
			{
				CloseJaws();
			}
		}
	}

	UFUNCTION()
	void MoveToBasePose()
	{
		bIsMoving = true;
		bIsMovingToTarget = false;
		TimeOfStartMove = Time::GetGameTimeSeconds();

		if(JawsOnMoveToBase != EJawsPosition::NONE)
		{
			if(JawsOnMoveToBase == EJawsPosition::Open)
			{
				OpenJaws();
			}
			else
			{
				CloseJaws();
			}
		}
	}

	UFUNCTION()
	void SnapToTargetPose()
	{
		bHasSnapped = true;
		bIsMoving = true;
		bIsMovingToTarget = true;
		MoveAlpha = 1.0;
		WiggleAfterSnap = 3;
	}

	UFUNCTION()
	void SnapToBasePose()
	{
		bHasSnapped = true;
		bIsMoving = true;
		bIsMovingToTarget = false;
		MoveAlpha = 0.0;
	}

	UFUNCTION()
	void OpenJaws()
	{
		bJawsOpen = true;

		UIslandRobotArmEventHandler::Trigger_OnOpenJaw(this);
	}

	UFUNCTION()
	void CloseJaws()
	{
		bJawsOpen = false;

		FHazeTraceSettings TraceSettings = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
		TraceSettings.UseSphereShape(200);
		FTransform HeadTransform = RobotArmMeshComp.GetSocketTransform(n"Head");

		auto TraceHit = TraceSettings.QueryOverlaps(HeadTransform.Location + HeadTransform.TransformVectorNoScale(FVector::UpVector * 250));

		if(TraceHit.HasBlockHit())
		{
			for (auto Hit : TraceHit.BlockHits)
			{
				auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				Player.KillPlayer();
			}
		}

		JawsCamShakeFFComp.ActivateCameraShakeAndForceFeedback();

		UIslandRobotArmEventHandler::Trigger_OnCloseJaw(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsMoving)
		{
			float Duration = bIsMovingToTarget ? MoveForwardDuration : MoveBackwardDuration;

			float TimeSinceStartMove = Time::GetGameTimeSince(TimeOfStartMove);
			MoveAlpha = Math::Saturate(TimeSinceStartMove / Duration);

			if(MoveAlpha == 1.0)
			{
				if(!bHasSnapped)
				{
					bIsMoving = false;
					BP_OnStopMoving(bIsMovingToTarget);
				}
				bHasStoppedMovingOnce = true;
			}

			if(!bIsMovingToTarget)
				MoveAlpha = 1.0 - MoveAlpha;
		}

		if (WiggleAfterSnap > 0)
		{
			ActorLocation = ActorLocation + FVector(0, 0, 0.01);
			WiggleAfterSnap -= 1;
		}
	}

	FIslandRobotArmRotation GetCurrentBaseRotation() const
	{
		if(bHasStoppedMovingOnce && bUseAltBaseRotation)
			return AltBaseRotation;

		return BaseRotation;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStopMoving(bool bMovingForwards) 
	{
		if(bMovingForwards)
		{
			if(JawsOnReachedTarget != EJawsPosition::NONE)
			{
				if(JawsOnReachedTarget == EJawsPosition::Open)
				{
					OpenJaws();
				}
				else
				{
					CloseJaws();
				}
			}
		}
		else
		{
			if(JawsOnReachedBase != EJawsPosition::NONE)
			{
				if(JawsOnReachedBase == EJawsPosition::Open)
				{
					OpenJaws();
				}
				else
				{
					CloseJaws();
				}
			}
		}

		MoveCamShakeFFComp.ActivateCameraShakeAndForceFeedback();
	}

};

#if EDITOR
UCLASS(NotBlueprintable)
class UIslandRobotArmEditorComponent : UActorComponent
{
};

UCLASS(NotBlueprintable)
class UIslandRobotArmEditorVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandRobotArmEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		if(Editor::IsPlaying())
			return;

		const auto RobotArm = Cast<AIslandRobotArm>(Component.Owner);

		if(!RobotArm.bShowVisualizer)
			return;

		if(!IsValid(RobotArm))
			return;

		float Progress = RobotArm.VisualizeProgress;
		if(RobotArm.bAnimateVisualization)
		{
			Progress = (Time::GameTimeSeconds % RobotArm.VisualizeDuration) / RobotArm.VisualizeDuration;
			if(Time::GameTimeSeconds % (RobotArm.VisualizeDuration * 2) > RobotArm.VisualizeDuration)
				Progress = 1 - Progress;
		}

		FTransform BaseRelativeTransform = RobotArm.RobotArmMeshComp.GetSocketTransform(n"Base", ERelativeTransformSpace::RTS_ParentBoneSpace);
		FTransform Arm1RelativeTransform = RobotArm.RobotArmMeshComp.GetSocketTransform(n"Arm1", ERelativeTransformSpace::RTS_ParentBoneSpace);
		FTransform Arm2RelativeTransform = RobotArm.RobotArmMeshComp.GetSocketTransform(n"Arm2", ERelativeTransformSpace::RTS_ParentBoneSpace);
		FTransform Arm3RelativeTransform = RobotArm.RobotArmMeshComp.GetSocketTransform(n"Arm3", ERelativeTransformSpace::RTS_ParentBoneSpace);
		FTransform HeadRelativeTransform = RobotArm.RobotArmMeshComp.GetSocketTransform(n"Head", ERelativeTransformSpace::RTS_ParentBoneSpace);

		const FIslandRobotArmRotation Rotation = FIslandRobotArmRotation(
			RobotArm.bVisualizeAltBaseRotation ? RobotArm.AltBaseRotation : RobotArm.BaseRotation,
			RobotArm.TargetRotation,
			Progress,
			2,
			RobotArm.BaseProgressRange,
			RobotArm.ArmProgressRange,
			RobotArm.HeadArmProgressRange,
			RobotArm.HeadProgressRange
		);

		BaseRelativeTransform = FTransform(FRotator(0, Rotation.BaseRotation, 0.0), FVector::ZeroVector) * BaseRelativeTransform;
		Arm1RelativeTransform = FTransform(FRotator(-Rotation.Arm1Rotation, 0, 0), FVector::ZeroVector) * Arm1RelativeTransform;
		Arm2RelativeTransform = FTransform(FRotator(Rotation.Arm2Rotation, 0, 0), FVector::ZeroVector) * Arm2RelativeTransform;
		Arm3RelativeTransform = FTransform(FRotator(Rotation.Arm3Rotation, 0, 0), FVector::ZeroVector) * Arm3RelativeTransform;
		HeadRelativeTransform = FTransform(FRotator(0, Rotation.HeadRotation, 0), FVector::ZeroVector) * HeadRelativeTransform;

		const FTransform ComponentTransform = RobotArm.RobotArmMeshComp.WorldTransform;
		const FTransform BaseTransform = BaseRelativeTransform * ComponentTransform;
		const FTransform Arm1Transform = Arm1RelativeTransform * BaseTransform;
		const FTransform Arm2Transform = Arm2RelativeTransform * Arm1Transform;
		const FTransform Arm3Transform = Arm3RelativeTransform * Arm2Transform;
		const FTransform HeadTransform = HeadRelativeTransform * Arm3Transform;

		DrawWorldString(f"Progress: {Progress:.2}", BaseTransform.Location, FLinearColor::White, 1, -1, false,);

		DrawRobotArmCylinder(BaseTransform, FVector(0, 0, 50), 270, 50, FLinearColor::Gray);
		DrawRobotArmBox(FInstigator(RobotArm, n"Arm1"),Arm1Transform, FVector(0, -100, 400), FVector(100, 100, 500), FLinearColor::Gray);
		DrawRobotArmBox(FInstigator(RobotArm, n"Arm2"), Arm2Transform, FVector(0, 70, 150), FVector(100, 60, 400), FLinearColor::Gray);
		DrawRobotArmBox(FInstigator(RobotArm, n"Arm3"), Arm3Transform, FVector(0, 60, 80), FVector(100, 120, 160), FLinearColor::Gray);
		DrawRobotArmBox(FInstigator(RobotArm, n"Head"), HeadTransform, FVector(0, 0, 190), FVector(240, 50, 200), FLinearColor::Gray);
	
		DrawAttachedActors(RobotArm, HeadTransform);
	}

	void DrawRobotArmCylinder(FTransform BoneRoot, FVector BoxOffset, float Radius, float Height, FLinearColor Color) const
	{
		DrawWireCylinder(BoneRoot.TransformPositionNoScale(BoxOffset), BoneRoot.Rotator(), Color, Radius, Height, 16, 5, true);
	}

	void DrawRobotArmBox(FInstigator Instigator, FTransform BoneRoot, FVector BoxOffset, FVector BoxExtents, FLinearColor Color) const
	{
		DrawSolidBox(Instigator, BoneRoot.TransformPositionNoScale(BoxOffset), BoneRoot.Rotation, BoxExtents, Color, 1, 0);
		//DrawWireBox(BoneRoot.TransformPositionNoScale(BoxOffset), BoxExtents, BoneRoot.Rotation, Color, 3, true);
	}

	void DrawAttachedActors(const AIslandRobotArm RobotArm, FTransform FinalHeadTransform) const
	{
		TArray<AActor> AttachedActors;
		RobotArm.GetAttachedActors(AttachedActors, true, true);

		const FTransform InitialHeadTransform = RobotArm.RobotArmMeshComp.GetSocketTransform(n"Head", ERelativeTransformSpace::RTS_World);

		for(const auto AttachedActor : AttachedActors)
		{
			const FTransform OffsetToOriginalTransform = AttachedActor.ActorTransform.GetRelativeTransform(InitialHeadTransform);
			const FTransform FinalActorTransform = OffsetToOriginalTransform * FinalHeadTransform;
			DrawAttachedActor(AttachedActor, FinalActorTransform);
		}
	}

	void DrawAttachedActor(const AActor AttachedActor, const FTransform ActorTransform) const
	{
		auto Material = Cast<UMaterialInterface>(LoadObject(nullptr, KineticActorVisualizer::MainMaterialPath));
		
		TArray<UStaticMeshComponent> MeshComponents;
		AttachedActor.GetComponentsByClass(MeshComponents);

		for(auto MeshComponent : MeshComponents)
		{
			const FTransform RelativeTransform = MeshComponent.WorldTransform.GetRelativeTransform(MeshComponent.Owner.ActorTransform);
			const FTransform MeshTransform = RelativeTransform * ActorTransform;

			DrawMeshWithMaterial(
				MeshComponent.StaticMesh,
				Material,
				MeshTransform.Location,
				MeshTransform.Rotation,
				MeshTransform.Scale3D
			);
		}
	}
};
#endif

UCLASS(Abstract)
class UIslandRobotArmEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenJaw() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseJaw() {}
};