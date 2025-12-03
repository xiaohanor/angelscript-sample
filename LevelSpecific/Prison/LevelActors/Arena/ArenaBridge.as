event void FArenaBridgeEvent();

UCLASS(Abstract)
class AArenaBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BridgeRoot;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	USceneComponent FloorGateRoot;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	USceneComponent WalkwayRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike CloseFloorGatesTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RotateBridgeTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ExtendBridgeTimeLike;

	UPROPERTY()
	FArenaBridgeEvent OnBridgeRotated;

	UPROPERTY(EditAnywhere)
	bool bFloorGatesOpen = true;

	bool bExtending = true;

	TArray<UStaticMeshComponent> FloorGateMeshes;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<UStaticMeshComponent> MeshComps;
		FloorGateRoot.GetChildrenComponentsByClass(UStaticMeshComponent, true, MeshComps);
		if (bFloorGatesOpen)
		{
			for (UStaticMeshComponent MeshComp : MeshComps)
			{
				FVector Loc = FVector(MeshComp.RelativeRotation.RightVector * 400.0);
				MeshComp.SetRelativeLocation(Loc);
			}
		}
		else
		{
			for (UStaticMeshComponent MeshComp : MeshComps)
			{
				MeshComp.SetRelativeLocation(FVector::ZeroVector);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FloorGateRoot.GetChildrenComponentsByClass(UStaticMeshComponent, true, FloorGateMeshes);

		CloseFloorGatesTimeLike.BindUpdate(this, n"UpdateCloseFloorGates");
		CloseFloorGatesTimeLike.BindFinished(this, n"FinishCloseFloorGates");

		RotateBridgeTimeLike.BindUpdate(this, n"UpdateRotateBridge");
		RotateBridgeTimeLike.BindFinished(this, n"FinishRotateBridge");

		ExtendBridgeTimeLike.BindUpdate(this, n"UpdateExtend");
		ExtendBridgeTimeLike.BindFinished(this, n"FinishExtend");
	}

	UFUNCTION()
	void CloseFloorGates()
	{
		CloseFloorGatesTimeLike.PlayFromStart();

		UArenaBridgeEffectEventHandler::Trigger_StartClosingFloorGates(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateCloseFloorGates(float CurValue)
	{
		for (UStaticMeshComponent MeshComp : FloorGateMeshes)
		{
			FVector Loc = Math::Lerp(MeshComp.RelativeRotation.RightVector * 400.0, FVector::ZeroVector, CurValue);
			MeshComp.SetRelativeLocation(Loc);
		}

		float Rot = Math::Lerp(0.0, 180.0, CurValue);
		FloorGateRoot.SetRelativeRotation(FRotator(0.0, Rot, 0.0));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishCloseFloorGates()
	{
		UArenaBridgeEffectEventHandler::Trigger_FinishClosingFloorGates(this);
	}

	UFUNCTION(BlueprintCallable)
	void ExtendBridge()
	{
		ExtendBridgeTimeLike.PlayFromStart();
	}

	UFUNCTION(BlueprintCallable)
	void RotateBridge()
	{
		bExtending = true;
		RotateBridgeTimeLike.PlayFromStart();

		UArenaBridgeEffectEventHandler::Trigger_StartExtendingBridge(this);
	}

	UFUNCTION(BlueprintCallable)
	void RetractBridge()
	{
		bExtending = false;
		ExtendBridgeTimeLike.ReverseFromEnd();

		UArenaBridgeEffectEventHandler::Trigger_StartRetractingBridge(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRotateBridge(float CurValue)
	{
		float Rot = Math::Lerp(0.0, -8.4, CurValue);
		BridgeRoot.SetRelativeRotation(FRotator(Rot, 0.0, 0.0));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRotateBridge()
	{
		if (bExtending)
		{
			// ExtendBridgeTimeLike.PlayFromStart();
			OnBridgeRotated.Broadcast();

			UArenaBridgeEffectEventHandler::Trigger_FinishExtendingBridge(this);
		}
		else
		{
			UArenaBridgeEffectEventHandler::Trigger_FinishRetractingBridge(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateExtend(float CurValue)
	{
		float Length = Math::Lerp(0.15, 1.55, CurValue);
		WalkwayRoot.SetRelativeScale3D(FVector(Length, 1.0, 1.0));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishExtend()
	{
		if (!bExtending)
			RotateBridgeTimeLike.ReverseFromEnd();
	}
}