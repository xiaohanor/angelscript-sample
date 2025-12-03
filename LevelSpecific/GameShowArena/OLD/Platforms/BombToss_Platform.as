

class ABombToss_Platform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BaseRailingRoot;

	UPROPERTY(DefaultComponent, Attach = BaseRailingRoot)
	UStaticMeshComponent BaseRailing;

	UPROPERTY(DefaultComponent, Attach = BaseRailingRoot)
	USceneComponent RailingRoot;

	UPROPERTY(DefaultComponent, Attach = RailingRoot)
	UStaticMeshComponent RailingMesh;

	UPROPERTY(DefaultComponent, Attach = RailingRoot)
	USceneComponent PlatformRotationRoot;
	default PlatformRotationRoot.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = PlatformRotationRoot)
	USceneComponent PlatformMeshRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformMeshRoot)
	UStaticMeshComponent PlatformMesh;
	default PlatformMesh.AddTag(n"WallRunnable");

	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UStaticMeshComponent PlatformDetailMesh01;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BombTossPlatformMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BombTossPlatformMalfunctionCapability");

	UPROPERTY(EditAnywhere)
	FGameShowArenaPlatformMoveData LayoutMoveData;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem MalfunctionEffect;

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaPlatformArm LinkedArm;

	UPROPERTY()
	UCurveFloat WiggleCurve;

	EBombTossPlatformPosition TargetPosition;

	FBombTossPlatformPositionValues CurrentPositionValues;
	FBombTossPlatformPositionValues TargetPositionValues;

	FRotator TargetRailingRot;
	FRotator TargetPlatformRot;

	AGameShowArenaPlatformManager PlatformManager;

	float TimeWhenShouldStartMoving = 0;

	bool bShouldBeMoving = false;
	bool bIsMalfunctioning = false;

	UPROPERTY(EditInstanceOnly)
	EBombTossPlatformPosition CurrentPosition = EBombTossPlatformPosition::MAX;

	float MoveDuration = 0;
	float MoveDelay = 0;

	UPROPERTY(VisibleAnywhere)
	FGuid PlatformGuid;

	UPROPERTY(DefaultComponent)
	UGameShowArenaDisplayDecalPlatformComponent DisplayDecalComp;

	UMaterialInstanceDynamic DynamicMaterial;

#if EDITOR
	// UFUNCTION(BlueprintOverride)
	// void OnVisualizeInEditor() const
	// {
	// 	// auto Color = PlatformGuid.IsValid() ? FLinearColor::Green : FLinearColor::Red;
	// 	// Debug::DrawDebugString(ActorLocation + FVector::UpVector * 1000, PlatformGuid.ToString(), Color);
	// 	if (LinkedArm != nullptr)
	// 	{
	// 		Debug::DrawDebugLine(PlatformMesh.WorldLocation, LinkedArm.PlatformArm.GetSocketLocation(n"PlatformAttach"), FLinearColor::Green, 50);
	// 	}
	// 	else
	// 	{
	// 		Debug::DrawDebugLine(PlatformMesh.WorldLocation, PlatformMesh.WorldLocation + FVector::UpVector * 2000, FLinearColor::Red, 10);
	// 	}
	// }

	UFUNCTION(CallInEditor)
	void EditorFindArmAbove()
	{
		FHazeTraceSettings TraceSettings;
		TraceSettings.IgnoreActor(this);
		TraceSettings.TraceWithChannel(ECollisionChannel::ECC_WorldDynamic);
		TraceSettings.UseLine();
		auto Results = TraceSettings.QueryTraceMulti(PlatformMesh.WorldLocation, PlatformMesh.WorldLocation + FVector::UpVector * 2000);
		for (auto Result : Results)
		{
			auto PlatformArm = Cast<AGameShowArenaPlatformArm>(Result.Actor);
			if (PlatformArm != nullptr)
			{
				LinkedArm = PlatformArm;
				break;
			}
		}
	}
#endif

#if EDITOR
	void SetPlatformGuid(FGuid Guid)
	{
		PlatformGuid = Guid;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// CreateDynamicMaterial();
		// EditorSetPreviewLocation(FGameShowArenaPlatformMoveData(CurrentPosition), bCalledFromConstructionScript = true);
	}

	UFUNCTION(CallInEditor)
	void EditorSetPreviewLocation(FGameShowArenaPlatformMoveData InLayoutMoveData, bool bCalledFromConstructionScript = false)
	{
		if (!bCalledFromConstructionScript)
			PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();

		if (PlatformManager == nullptr)
			return;

		LayoutMoveData = InLayoutMoveData;
		CurrentPositionValues = PlatformManager.GetCorrespondingValuesToPosition(InLayoutMoveData.Position);
		BaseRailingRoot.SetRelativeLocation(CurrentPositionValues.BaseRailingRootLoc);
		BaseRailingRoot.SetRelativeRotation(CurrentPositionValues.BaseRailingRootRot);
		PlatformMeshRoot.SetRelativeRotation(CurrentPositionValues.PlatformMeshRootRot);
		RailingRoot.SetRelativeRotation(CurrentPositionValues.RailingRootRot);
	}

	UFUNCTION(CallInEditor)
	void EditorSaveCurrentValuesToPlatformLocation(EBombTossPlatformPosition PlatformLocation)
	{
		if (!devEnsure(PlatformRotationRoot.RelativeRotation == FRotator::ZeroRotator, "PlatformRotationRoot needs to be at Zero Rotation! Setting it back to Zero."))
		{
			PlatformRotationRoot.SetRelativeRotation(FRotator::ZeroRotator);
			return;
		}

		PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();

		FBombTossPlatformPositionValues NewPosValues;
		NewPosValues.BaseRailingRootLoc = BaseRailingRoot.RelativeLocation;
		NewPosValues.BaseRailingRootRot = BaseRailingRoot.RelativeRotation;
		NewPosValues.PlatformMeshRootRot = PlatformMeshRoot.RelativeRotation;
		NewPosValues.RailingRootRot = RailingRoot.RelativeRotation;
		auto EditorComp = UGameShowArenaPlatformManagerEditorComponent::Get(PlatformManager);
		EditorComp.SaveNewPlatformPositionValues(PlatformLocation, NewPosValues);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();
		CurrentPositionValues = PlatformManager.GetCorrespondingValuesToPosition(EBombTossPlatformPosition::Hidden);
		//DisplayDecalComp.TargetMeshComp = PlatformMesh;
		SnapToPosition(FGameShowArenaPlatformMoveData(EBombTossPlatformPosition::Hidden));
		LayoutMoveData.Position = EBombTossPlatformPosition::Hidden;
	}

	UMaterialInstanceDynamic GetDynamicMaterial()
	{
		if (DynamicMaterial == nullptr)
			DynamicMaterial = PlatformMesh.CreateDynamicMaterialInstance(0);

		return DynamicMaterial;
	}

	void ForceUpdateCollision()
	{
		AddActorCollisionBlock(this);
		RemoveActorCollisionBlock(this);
	}

	UFUNCTION()
	void SnapToPosition(FGameShowArenaPlatformMoveData InLayoutMoveData)
	{
		if (ActorNameOrLabel.Contains("60"))
			Print("Cool", 0);
		CurrentPosition = InLayoutMoveData.Position;
		LayoutMoveData = InLayoutMoveData;
		CurrentPositionValues = PlatformManager.GetCorrespondingValuesToPosition(LayoutMoveData.Position);
		BaseRailingRoot.SetRelativeLocation(CurrentPositionValues.BaseRailingRootLoc);
		BaseRailingRoot.SetRelativeRotation(CurrentPositionValues.BaseRailingRootRot);
		PlatformMeshRoot.SetRelativeRotation(CurrentPositionValues.PlatformMeshRootRot);
		RailingRoot.SetRelativeRotation(CurrentPositionValues.RailingRootRot);
		ForceUpdateCollision();
		bShouldBeMoving = false;
	}

	void StartMovingPlatform(FGameShowArenaPlatformMoveData InLayoutMoveData)
	{
		if (CurrentPosition == InLayoutMoveData.Position)
			return;

		if (ActorNameOrLabel.Contains("60"))
			Print("Cool", 0);

		bShouldBeMoving = true;
		LayoutMoveData = InLayoutMoveData;
		CurrentPosition = LayoutMoveData.Position;
		TimeWhenShouldStartMoving = Time::GameTimeSeconds + LayoutMoveData.MoveDelay;
		TargetPositionValues = PlatformManager.GetCorrespondingValuesToPosition(LayoutMoveData.Position);
	}

	UFUNCTION()
	void StartMalfunctioning()
	{
		bIsMalfunctioning = true;
	}

	UFUNCTION()
	void StopMalfunctioning()
	{
		bIsMalfunctioning = false;
	}
}