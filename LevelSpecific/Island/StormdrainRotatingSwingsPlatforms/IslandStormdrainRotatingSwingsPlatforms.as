enum EIslandStormdrainRotatingSwingsPlatformsExtendableStage
{
	First,
	Second,
	Third,
	Side,
	MAX
}

struct FIslandStormdrainRotatingSwingsPlatformsMeshData
{
	UPROPERTY()
	UStaticMesh Mesh;

	UPROPERTY()
	UMaterialInterface Material;

	UPROPERTY()
	FVector Scale = FVector(1.0);

	UPROPERTY()
	FVector StartingOffset;

	UPROPERTY()
	FVector EndingOffset;

	UPROPERTY()
	bool bDebugStartEndLocation;
}

enum EIslandStormdrainRotatingSwingsPlatformExtendableType
{
	First,
	Second,
	Third,
	MAX UMETA(Hidden)
}

enum EIslandStormdrainRotatingSwingsPlatformSideMeshScaleMode
{
	RelativeToActor,
	RelativeToExtendable
}

struct FIslandStormdrainRotatingSwingsPlatformsSideMeshData
{
	UPROPERTY()
	FIslandStormdrainRotatingSwingsPlatformsMeshData MeshData;

	UPROPERTY(Meta = (Bitmask, BitmaskEnum="/Script/Angelscript.EIslandStormdrainRotatingSwingsPlatformExtendableType"))
	int ExtendablesToExtendFrom = 1 + 2 + 4;

	UPROPERTY()
	EIslandStormdrainRotatingSwingsPlatformSideMeshScaleMode ScaleMode;

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool bOverrideFirstExtendableScale = false;

	UPROPERTY(Meta = (EditCondition = "bOverrideFirstExtendableScale"))
	FVector RelativeFirstExtendableScale = FVector(1.0);

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool bOverrideSecondExtendableScale = false;

	UPROPERTY(Meta = (EditCondition = "bOverrideSecondExtendableScale"))
	FVector RelativeSecondExtendableScale = FVector(1.0);

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool bOverrideThirdExtendableScale = false;

	UPROPERTY(Meta = (EditCondition = "bOverrideThirdExtendableScale"))
	FVector RelativeThirdExtendableScale = FVector(1.0);
	
	UPROPERTY()
	bool bHideWhenRetracted = true;
}

UCLASS(NotBlueprintable, NotPlaceable)
class UIslandStormdrainRotatingSwingsPlatformSideMeshComponent : UStaticMeshComponent
{
	UPROPERTY(BlueprintHidden, NotVisible)
	EIslandStormdrainRotatingSwingsPlatformsExtendableStage SectionType;

	UPROPERTY(BlueprintHidden, NotVisible)
	FVector RelativeForwardOfExtendableBase;
}

struct FIslandStormdrainRotatingSwingsPlatformParentData
{
	USceneComponent Parent;
	EIslandStormdrainRotatingSwingsPlatformsExtendableStage Section;
}

struct FIslandStormdrainRotatingSwingsPlatformsSectionEffectParams
{
	UPROPERTY()
	EIslandStormdrainRotatingSwingsPlatformsExtendableStage Section;
}

UCLASS(Abstract)
class UIslandStormdrainRotatingSwingsPlatformsEffectHandler : UHazeEffectEventHandler
{
	// Called when the first section of the rotating swings platform starts extending
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExtendStart() {}

	// Called when the last section and the sides have fully extended.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExtendComplete() {}

	// Called when the sides start extending
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSideExtendStart() {}

	// Called when each section fully extends.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSectionExtendComplete(FIslandStormdrainRotatingSwingsPlatformsSectionEffectParams Params) {}
}

UCLASS(Abstract)
class AIslandStormdrainRotatingSwingsPlatforms : AHazeActor
{
	access Visualizer = private, UIslandStormdrainRotatingSwingsPlatformsVisualizer;
	// Original root location in stormdrain level: (X=-600.000000,Y=-200.000000,Z=2600.000000)

	const FRotator PosXRotator = FRotator(0.0, 0.0, 0.0);
	const FRotator NegXRotator = FRotator(0.0, 180.0, 0.0);
	const FRotator PosYRotator = FRotator(0.0, 90.0, 0.0);
	const FRotator NegYRotator = FRotator(0.0, -90.0, 0.0);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CenterPlatform;
	default CenterPlatform.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent NonExtendableRoot;

	UPROPERTY(DefaultComponent, Attach = NonExtendableRoot)
	UStaticMeshComponent PosXNonExtendable;
	default PosXNonExtendable.bBlockVisualsOnDisable = false;
	default PosXNonExtendable.RelativeRotation = PosXRotator;

	UPROPERTY(DefaultComponent, Attach = NonExtendableRoot)
	UStaticMeshComponent NegXNonExtendable;
	default NegXNonExtendable.bBlockVisualsOnDisable = false;
	default NegXNonExtendable.RelativeRotation = NegXRotator;

	UPROPERTY(DefaultComponent, Attach = NonExtendableRoot)
	UStaticMeshComponent PosYNonExtendable;
	default PosYNonExtendable.bBlockVisualsOnDisable = false;
	default PosYNonExtendable.RelativeRotation = PosYRotator;

	UPROPERTY(DefaultComponent, Attach = NonExtendableRoot)
	UStaticMeshComponent NegYNonExtendable;
	default NegYNonExtendable.bBlockVisualsOnDisable = false;
	default NegYNonExtendable.RelativeRotation = NegYRotator;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ExtendableRoots;

	// First extendable
	UPROPERTY(DefaultComponent, Attach = ExtendableRoots)
	USceneComponent FirstExtendableRoot;

	UPROPERTY(DefaultComponent, Attach = FirstExtendableRoot)
	UStaticMeshComponent FirstPosXExtendable;
	default FirstPosXExtendable.bBlockVisualsOnDisable = false;
	default FirstPosXExtendable.RelativeRotation = PosXRotator;

	UPROPERTY(DefaultComponent, Attach = FirstExtendableRoot)
	UStaticMeshComponent FirstNegXExtendable;
	default FirstNegXExtendable.bBlockVisualsOnDisable = false;
	default FirstNegXExtendable.RelativeRotation = NegXRotator;

	UPROPERTY(DefaultComponent, Attach = FirstExtendableRoot)
	UStaticMeshComponent FirstPosYExtendable;
	default FirstPosYExtendable.bBlockVisualsOnDisable = false;
	default FirstPosYExtendable.RelativeRotation = PosYRotator;

	UPROPERTY(DefaultComponent, Attach = FirstExtendableRoot)
	UStaticMeshComponent FirstNegYExtendable;
	default FirstNegYExtendable.bBlockVisualsOnDisable = false;
	default FirstNegYExtendable.RelativeRotation = NegYRotator;
	
	// Second extendable
	UPROPERTY(DefaultComponent, Attach = ExtendableRoots)
	USceneComponent SecondExtendableRoot;

	UPROPERTY(DefaultComponent, Attach = SecondExtendableRoot)
	UStaticMeshComponent SecondPosXExtendable;
	default SecondPosXExtendable.bBlockVisualsOnDisable = false;
	default SecondPosXExtendable.RelativeRotation = PosXRotator;

	UPROPERTY(DefaultComponent, Attach = SecondExtendableRoot)
	UStaticMeshComponent SecondNegXExtendable;
	default SecondNegXExtendable.bBlockVisualsOnDisable = false;
	default SecondNegXExtendable.RelativeRotation = NegXRotator;

	UPROPERTY(DefaultComponent, Attach = SecondExtendableRoot)
	UStaticMeshComponent SecondPosYExtendable;
	default SecondPosYExtendable.bBlockVisualsOnDisable = false;
	default SecondPosYExtendable.RelativeRotation = PosYRotator;

	UPROPERTY(DefaultComponent, Attach = SecondExtendableRoot)
	UStaticMeshComponent SecondNegYExtendable;
	default SecondNegYExtendable.bBlockVisualsOnDisable = false;
	default SecondNegYExtendable.RelativeRotation = NegYRotator;

	UPROPERTY(DefaultComponent, Attach = ExtendableRoots)
	USceneComponent ThirdExtendableRoot;

	UPROPERTY(DefaultComponent, Attach = ThirdExtendableRoot)
	UStaticMeshComponent ThirdPosXExtendable;
	default ThirdPosXExtendable.bBlockVisualsOnDisable = false;
	default ThirdPosXExtendable.RelativeRotation = PosXRotator;

	UPROPERTY(DefaultComponent, Attach = ThirdExtendableRoot)
	UStaticMeshComponent ThirdNegXExtendable;
	default ThirdNegXExtendable.bBlockVisualsOnDisable = false;
	default ThirdNegXExtendable.RelativeRotation = NegXRotator;

	UPROPERTY(DefaultComponent, Attach = ThirdExtendableRoot)
	UStaticMeshComponent ThirdPosYExtendable;
	default ThirdPosYExtendable.bBlockVisualsOnDisable = false;
	default ThirdPosYExtendable.RelativeRotation = PosYRotator;

	UPROPERTY(DefaultComponent, Attach = ThirdExtendableRoot)
	UStaticMeshComponent ThirdNegYExtendable;
	default ThirdNegYExtendable.bBlockVisualsOnDisable = false;
	default ThirdNegYExtendable.RelativeRotation = NegYRotator;

	UPROPERTY(DefaultComponent, Attach = ExtendableRoots)
	USceneComponent SideExtendableRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandStormdrainRotatingSwingsPlatformsVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Automatic Generation")
	FIslandStormdrainRotatingSwingsPlatformsMeshData CenterMesh;

	UPROPERTY(EditInstanceOnly, Category = "Automatic Generation")
	FIslandStormdrainRotatingSwingsPlatformsMeshData NonExtendableMesh;

	UPROPERTY(EditInstanceOnly, Category = "Automatic Generation")
	FIslandStormdrainRotatingSwingsPlatformsMeshData FirstExtendableMesh;

	UPROPERTY(EditInstanceOnly, Category = "Automatic Generation")
	FIslandStormdrainRotatingSwingsPlatformsMeshData SecondExtendableMesh;

	UPROPERTY(EditInstanceOnly, Category = "Automatic Generation")
	FIslandStormdrainRotatingSwingsPlatformsMeshData ThirdExtendableMesh;

	UPROPERTY(EditInstanceOnly, Category = "Automatic Generation")
	FIslandStormdrainRotatingSwingsPlatformsSideMeshData SideMesh;

	UPROPERTY(EditAnywhere)
	float ExtendDuration = 2.0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve ExtendInterpolation;
	default ExtendInterpolation.AddDefaultKey(0.0, 0.0);
	default ExtendInterpolation.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	FRotator RotationRate = FRotator::ZeroRotator;

	bool bSectionsShouldExtend = false;
	bool bSectionsAreFullyExtended = false;
	float SectionExtendAlpha = 0.0;
	EIslandStormdrainRotatingSwingsPlatformsExtendableStage CurrentExtendingSection = EIslandStormdrainRotatingSwingsPlatformsExtendableStage::First;
	TArray<UIslandStormdrainRotatingSwingsPlatformSideMeshComponent> SideExtendables;

	float RotationRateChangeCrumbTime = 0.0;
	FRotator RotationRateChangeBaseValue;

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Automatic Generation")
	void AutomaticallyGenerate()
	{
		// Main extendables
		ApplyMeshDataToComp(CenterPlatform, CenterMesh);
		ApplyMeshDataToChildren(NonExtendableRoot, NonExtendableMesh);
		ApplyMeshDataToChildren(FirstExtendableRoot, FirstExtendableMesh);
		ApplyMeshDataToChildren(SecondExtendableRoot, SecondExtendableMesh);
		ApplyMeshDataToChildren(ThirdExtendableRoot, ThirdExtendableMesh);

		SetRelativeLocationOfChildrenRelativeToComponent(NonExtendableRoot, CenterPlatform, FVector(), false);
		SetRelativeLocationOfChildrenRelativeToChildren(FirstExtendableRoot, NonExtendableRoot, FirstExtendableMesh.StartingOffset, true);
		SetRelativeLocationOfChildrenRelativeToChildren(SecondExtendableRoot, FirstExtendableRoot, SecondExtendableMesh.StartingOffset, true);
		SetRelativeLocationOfChildrenRelativeToChildren(ThirdExtendableRoot, SecondExtendableRoot, ThirdExtendableMesh.StartingOffset, true);

		// Side extendables
		TArray<UIslandStormdrainRotatingSwingsPlatformSideMeshComponent> TempSideExtendables;
		GetComponentsByClass(UIslandStormdrainRotatingSwingsPlatformSideMeshComponent, TempSideExtendables);
		for(UIslandStormdrainRotatingSwingsPlatformSideMeshComponent SideExtendable : TempSideExtendables)
		{
			Editor::DestroyAndRenameInstanceComponentInEditor(SideExtendable);
		}

		for(int i = 0; i < int(EIslandStormdrainRotatingSwingsPlatformExtendableType::MAX); i++)
		{
			// If bitmask is not set to this section we ignore it!
			if((SideMesh.ExtendablesToExtendFrom & (1 << uint(i))) == 0)
				continue;

			auto ExtendableType = EIslandStormdrainRotatingSwingsPlatformExtendableType(i);
			USceneComponent SectionParent = GetSectionParent(ExtendableType);
			TArray<UStaticMeshComponent> MeshComps;
			SectionParent.GetChildrenComponentsByClass(UStaticMeshComponent, false, MeshComps);

			for(UStaticMeshComponent Extendable : MeshComps)
			{
				SetupSideMesh(Extendable, FRotator(0.0, 90.0, 0.0), ExtendableType);
				SetupSideMesh(Extendable, FRotator(0.0, -90.0, 0.0), ExtendableType);
			}
		}
	}

	access:Visualizer void SetupSideMesh(UStaticMeshComponent Extendable, FRotator RelativeRotationOffset, EIslandStormdrainRotatingSwingsPlatformExtendableType SectionType)
	{
		auto NewSideMesh = UIslandStormdrainRotatingSwingsPlatformSideMeshComponent::Create(this);
		NewSideMesh.AttachTo(SideExtendableRoot);
		NewSideMesh.RelativeRotation = (RelativeRotationOffset.Quaternion() * Extendable.RelativeRotation.Quaternion()).Rotator();
		NewSideMesh.SectionType = EIslandStormdrainRotatingSwingsPlatformsExtendableStage(SectionType);
		NewSideMesh.RelativeForwardOfExtendableBase = Extendable.RelativeRotation.ForwardVector;

		ApplyMeshDataToComp(NewSideMesh, SideMesh.MeshData);

		FVector RelevantScale = GetRelevantScaleForSideMesh(SectionType);
		if(SideMesh.ScaleMode == EIslandStormdrainRotatingSwingsPlatformSideMeshScaleMode::RelativeToExtendable)
		{
			NewSideMesh.RelativeScale3D = FVector(Extendable.RelativeScale3D.Y, Extendable.RelativeScale3D.X,  Extendable.RelativeScale3D.Z) * RelevantScale;
		}
		else if(SideMesh.ScaleMode == EIslandStormdrainRotatingSwingsPlatformSideMeshScaleMode::RelativeToActor)
		{
			NewSideMesh.RelativeScale3D = RelevantScale;
		}
		else
			devError("Forgot to add case");
		
		SetRelativeLocationOfComponentRelativeToComponent(NewSideMesh, Extendable, SideMesh.MeshData.StartingOffset, true);
	}

	access:Visualizer FVector GetRelevantScaleForSideMesh(EIslandStormdrainRotatingSwingsPlatformExtendableType SectionType)
	{
		if(SectionType == EIslandStormdrainRotatingSwingsPlatformExtendableType::First)
		{
			if(SideMesh.bOverrideFirstExtendableScale)
				return SideMesh.RelativeFirstExtendableScale;
		}
		else if(SectionType == EIslandStormdrainRotatingSwingsPlatformExtendableType::Second)
		{
			if(SideMesh.bOverrideSecondExtendableScale)
				return SideMesh.RelativeSecondExtendableScale;
		}
		else if(SectionType == EIslandStormdrainRotatingSwingsPlatformExtendableType::Third)
		{
			if(SideMesh.bOverrideThirdExtendableScale)
				return SideMesh.RelativeThirdExtendableScale;
		}

		return SideMesh.MeshData.Scale;
	}

	access:Visualizer void ApplyMeshDataToComp(UStaticMeshComponent Comp, FIslandStormdrainRotatingSwingsPlatformsMeshData MeshData)
	{
		if(MeshData.Mesh != nullptr)
		{
			Comp.StaticMesh = MeshData.Mesh;

			if(MeshData.Material != nullptr)
				Comp.SetMaterial(0, MeshData.Material);

			Comp.RelativeScale3D = MeshData.Scale;
		}
	}

	access:Visualizer void ApplyMeshDataToChildren(USceneComponent Parent, FIslandStormdrainRotatingSwingsPlatformsMeshData MeshData)
	{
		TArray<UStaticMeshComponent> MeshComps;
		Parent.GetChildrenComponentsByClass(UStaticMeshComponent, false, MeshComps);

		for(UStaticMeshComponent Current : MeshComps)
		{
			ApplyMeshDataToComp(Current, MeshData);
		}
	}

	access:Visualizer void SetRelativeLocationOfChildrenRelativeToComponent(USceneComponent ParentToSetLocationOfChildren, UStaticMeshComponent ComponentToBeRelativeTo, FVector RelativeStartingOffset, bool bRetracted)
	{
		TArray<UStaticMeshComponent> ChildrenToSetLocationOf;
		ParentToSetLocationOfChildren.GetChildrenComponentsByClass(UStaticMeshComponent, false, ChildrenToSetLocationOf);

		for(UStaticMeshComponent Child : ChildrenToSetLocationOf)
		{
			SetRelativeLocationOfComponentRelativeToComponent(Child, ComponentToBeRelativeTo, RelativeStartingOffset, bRetracted);
		}
	}

	access:Visualizer void SetRelativeLocationOfChildrenRelativeToChildren(USceneComponent ParentToSetLocationOfChildren, USceneComponent ParentToBeRelativeTo, FVector RelativeStartingOffset, bool bRetracted)
	{
		TArray<UStaticMeshComponent> ChildrenToSetLocationOf;
		ParentToSetLocationOfChildren.GetChildrenComponentsByClass(UStaticMeshComponent, false, ChildrenToSetLocationOf);

		TArray<UStaticMeshComponent> ChildrenToBeRelativeTo;
		ParentToBeRelativeTo.GetChildrenComponentsByClass(UStaticMeshComponent, false, ChildrenToBeRelativeTo);

		for(UStaticMeshComponent Child : ChildrenToSetLocationOf)
		{
			UStaticMeshComponent RelativeChild = GetRelativeChild(Child, ChildrenToBeRelativeTo);
			SetRelativeLocationOfComponentRelativeToComponent(Child, RelativeChild, RelativeStartingOffset, bRetracted);
		}
	}

	access:Visualizer void SetRelativeLocationOfComponentRelativeToComponent(UStaticMeshComponent Component, UStaticMeshComponent ComponentToBeNextTo, FVector RelativeStartingOffset, bool bRetracted)
	{
		FBox RelativeToBounds = ComponentToBeNextTo.GetBoundingBoxRelativeToTransform(ComponentToBeNextTo.WorldTransform);
		FBox ComponentBounds = Component.GetBoundingBoxRelativeToTransform(ComponentToBeNextTo.WorldTransform);

		FVector CombinedExtent = bRetracted ? RelativeToBounds.Extent - ComponentBounds.Extent : RelativeToBounds.Extent + ComponentBounds.Extent;
		float Distance = GetBoundingBoxExtentInDirection(Component.ForwardVector, ComponentToBeNextTo.WorldTransform, CombinedExtent);
		FVector RelativeForward = ComponentToBeNextTo.WorldTransform.InverseTransformVectorNoScale(Component.ForwardVector);
		FVector RelativeLocation = RelativeForward * Distance;
		FVector WorldStartingOffset = ComponentToBeNextTo.WorldTransform.TransformVectorNoScale(RelativeStartingOffset);
		FVector WorldLocation = ComponentToBeNextTo.WorldTransform.TransformPosition(RelativeLocation) + WorldStartingOffset;
		Component.RelativeLocation = Component.AttachParent.WorldTransform.InverseTransformPosition(WorldLocation);
	}
#endif

	UFUNCTION()
	void OnPlayerAttachedToSwing(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		//UPlayerMovementComponent::Get(Player).ApplyCrumbSyncedRelativePosition(this, SwingPoint);
	}

	UFUNCTION()
	void OnPlayerDetachedFromSwing(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		//UPlayerMovementComponent::Get(Player).ClearCrumbSyncedRelativePosition(this);
	}

	UFUNCTION()
	void ExtendSections()
	{
		if(!bSectionsShouldExtend)
		{
			UIslandStormdrainRotatingSwingsPlatformsEffectHandler::Trigger_OnExtendStart(this);
		}

		bSectionsShouldExtend = true;
	}

	/* Will extend all sections instantly without calling any events (call this when starting from progress point) */
	UFUNCTION()
	void SnapExtendSections()
	{
		bSectionsShouldExtend = true;
		while(!bSectionsAreFullyExtended)
		{
			float CurrentAlpha = 1.0;
			MoveStep(0.0, CurrentAlpha, false);
		}

		SectionExtendAlpha = 1.0;
	}

	UFUNCTION()
	void RetractSections()
	{
		bSectionsShouldExtend = false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(UIslandStormdrainRotatingSwingsPlatformSideMeshComponent, SideExtendables);
		if(SideMesh.bHideWhenRetracted)
		{
			for(UIslandStormdrainRotatingSwingsPlatformSideMeshComponent SideExtendable : SideExtendables)
			{
				SideExtendable.AddComponentVisualsBlocker(this);
				SideExtendable.AddComponentCollisionBlocker(this);
			}
		}
	}

	UFUNCTION()
	void StartRotating(FRotator NewRotationRate)
	{
		if (HasControl())
			NetChangeRotationRate(Time::GetActorControlCrumbTrailTime(this), NewRotationRate, ActorRotation);
	}

	UFUNCTION(NetFunction)
	private void NetChangeRotationRate(float ActorControlCrumbTrailTime, FRotator NewRotationRate, FRotator BaseRotation)
	{
		RotationRateChangeCrumbTime = ActorControlCrumbTrailTime;
		RotationRate = NewRotationRate;
		RotationRateChangeBaseValue = BaseRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!RotationRate.IsZero())
		{
			FRotator TotalRotation = RotationRateChangeBaseValue;

			float RotationTime = (Time::GetActorControlPredictedCrumbTrailTime(this) - RotationRateChangeCrumbTime);
			TotalRotation.Yaw += Acceleration::GetDistanceAtTimeWithAcceleration(RotationTime, 6.0, 0.0, RotationRate.Yaw);
			TotalRotation.Pitch += Acceleration::GetDistanceAtTimeWithAcceleration(RotationTime, 6.0, 0.0, RotationRate.Pitch);
			TotalRotation.Roll += Acceleration::GetDistanceAtTimeWithAcceleration(RotationTime, 6.0, 0.0, RotationRate.Roll);

			ActorRotation = TotalRotation;
		}

		float PreviousAlpha = SectionExtendAlpha;
		SectionExtendAlpha += DeltaTime / ExtendDuration * (bSectionsShouldExtend ? 1.0 : -1.0);
		SectionExtendAlpha = Math::Saturate(SectionExtendAlpha);
		if(PreviousAlpha == SectionExtendAlpha)
			return;

		MoveStep(PreviousAlpha, SectionExtendAlpha, true);
	}

	private void MoveStep(float PreviousAlpha, float& CurrentAlpha, bool bTriggerEvents = false)
	{
		float PreviousValue = ExtendInterpolation.GetFloatValue(PreviousAlpha);
		float CurrentValue = ExtendInterpolation.GetFloatValue(CurrentAlpha);

		float ValueDelta = CurrentValue - PreviousValue;
		USceneComponent Parent = GetSectionParent(CurrentExtendingSection);
		FIslandStormdrainRotatingSwingsPlatformsMeshData MeshData = GetSectionMeshData(CurrentExtendingSection);
		TArray<FIslandStormdrainRotatingSwingsPlatformParentData> NextParents = GetNextParents();
		
		TArray<UStaticMeshComponent> Children;
		Parent.GetChildrenComponentsByClass(UStaticMeshComponent, false, Children);

		for(UStaticMeshComponent Child : Children)
		{
			TArray<UStaticMeshComponent> RelativeChildren = GetRelativeChildrenFromParents(Child, NextParents);

			FBox BoundingBox = Child.GetBoundingBoxRelativeToTransform(Parent.WorldTransform);
			float Distance = GetBoundingBoxExtentInDirection(Child.ForwardVector, Parent.WorldTransform, BoundingBox.Extent);
			FVector Delta = (Child.ForwardVector * (Distance * 2.0) + Child.WorldTransform.TransformVectorNoScale(-MeshData.StartingOffset + MeshData.EndingOffset)) * ValueDelta;
			Child.WorldLocation += Delta;
			for(int i = 0; i < RelativeChildren.Num(); i++)
			{
				RelativeChildren[i].WorldLocation += Delta;
			}
		}

		if(CurrentAlpha == (bSectionsShouldExtend ? 1.0 : 0.0))
		{
			EIslandStormdrainRotatingSwingsPlatformsExtendableStage NewSection = GetNextSection(CurrentExtendingSection, bSectionsShouldExtend, true);
			if(NewSection == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::MAX)
			{
				if(!bSectionsAreFullyExtended)
				{
					bSectionsAreFullyExtended = true;

					if(bTriggerEvents)
					{
						OnFullyExtended();

						if(bSectionsShouldExtend)
						{
							OnSectionExtended(CurrentExtendingSection);
							UIslandStormdrainRotatingSwingsPlatformsEffectHandler::Trigger_OnExtendComplete(this);

							FIslandStormdrainRotatingSwingsPlatformsSectionEffectParams Params;
							Params.Section = CurrentExtendingSection;
							UIslandStormdrainRotatingSwingsPlatformsEffectHandler::Trigger_OnSectionExtendComplete(this, Params);
						}
						else
						{
							OnSectionRetracted(CurrentExtendingSection);
						}
					}
				}
				return;
			}

			if(NewSection == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Side && bTriggerEvents)
				UIslandStormdrainRotatingSwingsPlatformsEffectHandler::Trigger_OnSideExtendStart(this);

			if(bTriggerEvents)
			{
				if(bSectionsShouldExtend)
				{
					OnSectionExtended(CurrentExtendingSection);

					FIslandStormdrainRotatingSwingsPlatformsSectionEffectParams Params;
					Params.Section = CurrentExtendingSection;
					UIslandStormdrainRotatingSwingsPlatformsEffectHandler::Trigger_OnSectionExtendComplete(this, Params);
				}
				else
					OnSectionRetracted(CurrentExtendingSection);
			}

			if(NewSection == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Side)
			{
				if(SideMesh.bHideWhenRetracted)
				{
					for(UIslandStormdrainRotatingSwingsPlatformSideMeshComponent SideExtendable : SideExtendables)
					{
						SideExtendable.RemoveComponentVisualsBlocker(this);
						SideExtendable.RemoveComponentCollisionBlocker(this);
					}
				}
			}
			else if(CurrentExtendingSection == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Side)
			{
				if(SideMesh.bHideWhenRetracted)
				{
					for(UIslandStormdrainRotatingSwingsPlatformSideMeshComponent SideExtendable : SideExtendables)
					{
						SideExtendable.AddComponentVisualsBlocker(this);
						SideExtendable.AddComponentCollisionBlocker(this);
					}
				}
			}

			CurrentExtendingSection = NewSection;
			CurrentAlpha = bSectionsShouldExtend ? 0.0 : 1.0;
		}
		else
			bSectionsAreFullyExtended = false;
	}

	UFUNCTION(BlueprintEvent)
	void OnFullyExtended() {}

	UFUNCTION(BlueprintEvent)
	void OnSectionExtended(EIslandStormdrainRotatingSwingsPlatformsExtendableStage Section) {}

	UFUNCTION(BlueprintEvent)
	void OnSectionRetracted(EIslandStormdrainRotatingSwingsPlatformsExtendableStage Section) {}

	access:Visualizer float GetBoundingBoxExtentInDirection(FVector WorldDirection, FTransform BoundsTransform, FVector BoundsExtent) const
	{
		FVector RelativeForward = BoundsTransform.InverseTransformVectorNoScale(WorldDirection);
		FVector AbsRelativeForward = FVector(Math::Abs(RelativeForward.X), Math::Abs(RelativeForward.Y), Math::Abs(RelativeForward.Z));
		return AbsRelativeForward.DotProduct(BoundsExtent);
	}

	access:Visualizer UStaticMeshComponent GetRelativeChild(UStaticMeshComponent MainChild, const TArray<UStaticMeshComponent>& ChildrenToBeRelativeTo)
	{
		for(UStaticMeshComponent Child : ChildrenToBeRelativeTo)
		{
			if(Child.ForwardVector.Equals(MainChild.ForwardVector))
				return Child;
		}

		devError("This shouldn't happen!");
		return nullptr;
	}

	access:Visualizer TArray<UStaticMeshComponent> GetRelativeChildrenFromParents(UStaticMeshComponent MainChild, const TArray<FIslandStormdrainRotatingSwingsPlatformParentData>& Parents)
	{
		TArray<UStaticMeshComponent> OutRelativeChildren;

		for(FIslandStormdrainRotatingSwingsPlatformParentData Parent : Parents)
		{
			TArray<UStaticMeshComponent> Children;
			Parent.Parent.GetChildrenComponentsByClass(UStaticMeshComponent, false, Children);
			UStaticMeshComponent Child = GetRelativeChild(MainChild, Children);
			OutRelativeChildren.Add(Child);

			TArray<UStaticMeshComponent> SideChildren = GetSideChildrenToExtendable(Child, Parent.Section);
			OutRelativeChildren.Append(SideChildren);
		}

		TArray<UStaticMeshComponent> SideChildren = GetSideChildrenToExtendable(MainChild, CurrentExtendingSection);
		OutRelativeChildren.Append(SideChildren);

		return OutRelativeChildren;
	}

	access:Visualizer TArray<UStaticMeshComponent> GetSideChildrenToExtendable(UStaticMeshComponent Extendable, EIslandStormdrainRotatingSwingsPlatformsExtendableStage CurrentSection)
	{
		TArray<UStaticMeshComponent> OutArray;
		for(UIslandStormdrainRotatingSwingsPlatformSideMeshComponent SideExtendable : SideExtendables)
		{
			if(SideExtendable.SectionType == CurrentSection && SideExtendable.RelativeForwardOfExtendableBase.Equals(Extendable.RelativeRotation.ForwardVector))
				OutArray.Add(SideExtendable);
		}

		return OutArray;
	}

	access:Visualizer USceneComponent GetSectionParent(EIslandStormdrainRotatingSwingsPlatformsExtendableStage Section) const
	{
		if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::First)
			return FirstExtendableRoot;
		else if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Second)
			return SecondExtendableRoot;
		else if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Third)
			return ThirdExtendableRoot;
		else if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Side)
			return SideExtendableRoot;
		else if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::MAX)
			return nullptr;
		else
			devError("Forgot to implement case!");

		return nullptr;
	}

	access:Visualizer USceneComponent GetSectionParent(EIslandStormdrainRotatingSwingsPlatformExtendableType Type) const
	{
		if(Type == EIslandStormdrainRotatingSwingsPlatformExtendableType::First)
			return FirstExtendableRoot;
		else if(Type == EIslandStormdrainRotatingSwingsPlatformExtendableType::Second)
			return SecondExtendableRoot;
		else if(Type == EIslandStormdrainRotatingSwingsPlatformExtendableType::Third)
			return ThirdExtendableRoot;
		else if(Type == EIslandStormdrainRotatingSwingsPlatformExtendableType::MAX)
			return nullptr;
		else
			devError("Forgot to implement case!");

		return nullptr;
	}

	access:Visualizer EIslandStormdrainRotatingSwingsPlatformsExtendableStage GetNextSection(EIslandStormdrainRotatingSwingsPlatformsExtendableStage CurrentSection, bool bAdd, bool bIncludeSideMesh)
	{
		if(bAdd && int(CurrentSection) == int(EIslandStormdrainRotatingSwingsPlatformsExtendableStage::MAX) - 1)
			return EIslandStormdrainRotatingSwingsPlatformsExtendableStage::MAX;
		else if(!bAdd && int(CurrentSection) == 0)
			return EIslandStormdrainRotatingSwingsPlatformsExtendableStage::MAX;

		auto Out = EIslandStormdrainRotatingSwingsPlatformsExtendableStage(int(CurrentSection) + (bAdd ? 1 : -1));
		if(!bIncludeSideMesh && Out == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Side)
			return EIslandStormdrainRotatingSwingsPlatformsExtendableStage::MAX;

		return Out;
	}

	access:Visualizer TArray<FIslandStormdrainRotatingSwingsPlatformParentData> GetNextParents()
	{
		TArray<FIslandStormdrainRotatingSwingsPlatformParentData> OutParents;
		USceneComponent LastParent = GetSectionParent(CurrentExtendingSection);
		
		EIslandStormdrainRotatingSwingsPlatformsExtendableStage Section = CurrentExtendingSection;
		while(LastParent != nullptr)
		{
			Section = GetNextSection(Section, true, false);
			LastParent = GetSectionParent(Section);
			if(LastParent == nullptr)
				break;
			
			FIslandStormdrainRotatingSwingsPlatformParentData NewData;
			NewData.Parent = LastParent;
			NewData.Section = Section;
			OutParents.Add(NewData);
		}

		return OutParents;
	}

	access:Visualizer FIslandStormdrainRotatingSwingsPlatformsMeshData GetSectionMeshData(EIslandStormdrainRotatingSwingsPlatformsExtendableStage Section)
	{
		if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::First)
			return FirstExtendableMesh;
		else if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Second)
			return SecondExtendableMesh;
		else if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Third)
			return ThirdExtendableMesh;
		else if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::Side)
			return SideMesh.MeshData;
		else if(Section == EIslandStormdrainRotatingSwingsPlatformsExtendableStage::MAX)
			return FIslandStormdrainRotatingSwingsPlatformsMeshData();

		devError("Forgot to add case");
		return FIslandStormdrainRotatingSwingsPlatformsMeshData();
	}
}

#if EDITOR
class UIslandStormdrainRotatingSwingsPlatformsDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AIslandStormdrainRotatingSwingsPlatforms;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		HideProperty(n"CenterMesh.StartingOffset");
		HideProperty(n"CenterMesh.EndingOffset");
		HideProperty(n"CenterMesh.bDebugStartEndLocation");

		HideProperty(n"NonExtendableMesh.StartingOffset");
		HideProperty(n"NonExtendableMesh.EndingOffset");
		HideProperty(n"NonExtendableMesh.bDebugStartEndLocation");
	}
}

class UIslandStormdrainRotatingSwingsPlatformsVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandStormdrainRotatingSwingsPlatformsVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandStormdrainRotatingSwingsPlatformsVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto SwingsPlatforms = Cast<AIslandStormdrainRotatingSwingsPlatforms>(Component.Owner);

		EIslandStormdrainRotatingSwingsPlatformsExtendableStage Section = EIslandStormdrainRotatingSwingsPlatformsExtendableStage::First;
		while(Section != EIslandStormdrainRotatingSwingsPlatformsExtendableStage::MAX)
		{
			FIslandStormdrainRotatingSwingsPlatformsMeshData MeshData = SwingsPlatforms.GetSectionMeshData(Section);
			if(MeshData.bDebugStartEndLocation)
			{
				USceneComponent Parent = SwingsPlatforms.GetSectionParent(Section);
				
				TArray<UStaticMeshComponent> Children;
				Parent.GetChildrenComponentsByClass(UStaticMeshComponent, false, Children);

				for(UStaticMeshComponent Child : Children)
				{
					FBox BoundingBox = Child.GetBoundingBoxRelativeToTransform(Parent.WorldTransform);
					float Distance = SwingsPlatforms.GetBoundingBoxExtentInDirection(Child.ForwardVector, Parent.WorldTransform, BoundingBox.Extent);
					FVector TotalDelta = (Child.ForwardVector * (Distance * 2.0) + Child.WorldTransform.TransformVectorNoScale(-MeshData.StartingOffset + MeshData.EndingOffset));

					FBox LocalBoundingBox = Child.GetComponentLocalBoundingBox();
					FVector Center = Child.WorldTransform.TransformPosition(LocalBoundingBox.Center);
					FVector Extent = LocalBoundingBox.Extent * Child.WorldTransform.Scale3D;
					DrawWireBox(Center, Extent, Child.ComponentQuat, FLinearColor::Green);
					DrawWireBox(Center + TotalDelta, Extent, Child.ComponentQuat, FLinearColor::Red);
				}
			}

			Section = EIslandStormdrainRotatingSwingsPlatformsExtendableStage(int(Section) + 1);
		}
	}
}
#endif