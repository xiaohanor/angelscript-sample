struct FRemoteHackableBridgePieceEventData
{
	UPROPERTY()
	bool bInFront = false;
}

class ARemoteHackableBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BridgeRoot;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	USceneComponent HackableRoot;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	URemoteHackingResponseComponent HackingResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableBridgeCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedOffset;
	default SyncedOffset.SyncRate = EHazeCrumbSyncRate::Low;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	float MinOffset = 200.0;
	UPROPERTY(EditAnywhere)
	float MaxOffset = 2500.0;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh MeshAsset;

	UPROPERTY(EditAnywhere)
	int BridgePieceAmount = 20;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	TArray<FRemoteHackableBridgePieceData> PieceData;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect PiecesConnectedFF;

	float SideOffset = 600.0;

	// Made into a const member so that audio can track this
	const float BRIDGE_PIECE_CONNECTION_TRACKING_DISTANCE = 300.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PieceData.Empty();

		for (int i = 0; i < BridgePieceAmount; i++)
		{
			USceneComponent MeshRoot = USceneComponent::Create(this, FName(f"BridgePiece_{i}"));
			MeshRoot.AttachToComponent(BridgeRoot);
			MeshRoot.SetRelativeLocation(FVector(i * 100.0, 0.0, 0.0));

			FRemoteHackableBridgePieceData Data;
			Data.Root = MeshRoot;

			TArray<UStaticMeshComponent> MeshComps;

			UStaticMeshComponent LeftMeshComp = UStaticMeshComponent::Create(this, FName(f"BridgeMesh_{i}_Left"));
			LeftMeshComp.AttachToComponent(MeshRoot);
			LeftMeshComp.SetRelativeRotation(FRotator(0.0, 90.0, 0.0));
			LeftMeshComp.SetRelativeLocation(FVector(0.0, -SideOffset, 0.0));
			LeftMeshComp.SetStaticMesh(MeshAsset);
			LeftMeshComp.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
			LeftMeshComp.RemoveTag(ComponentTags::LedgeClimbable);
			Data.LeftMesh = LeftMeshComp;

			UStaticMeshComponent RightMeshComp = UStaticMeshComponent::Create(this, FName(f"BridgeMesh_{i}_Right"));
			RightMeshComp.AttachToComponent(MeshRoot);
			RightMeshComp.SetRelativeRotation(FRotator(0.0, -90.0, 0.0));
			RightMeshComp.SetRelativeLocation(FVector(0.0, SideOffset, 0.0));
			RightMeshComp.SetStaticMesh(MeshAsset);
			RightMeshComp.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
			RightMeshComp.RemoveTag(ComponentTags::LedgeClimbable);
			Data.RightMesh = RightMeshComp;

			PieceData.Add(Data);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		SyncedOffset.SetValue(200.0);

		for (FRemoteHackableBridgePieceData& Data : PieceData)
		{
			float TargetOffset = 0;

			if (Data.Root.WorldLocation.Dist2D(HackableRoot.WorldLocation) >= BRIDGE_PIECE_CONNECTION_TRACKING_DISTANCE)
			{
				// In the wall
				TargetOffset = 1200.0;
				Data.LeftMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				Data.RightMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				Data.bIsConnected = false;
			}
			else
			{
				// In the center (connected)
				TargetOffset = SideOffset;
				Data.LeftMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
				Data.RightMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
				Data.bIsConnected = true;
			}

			Data.LeftMesh.SetRelativeLocation(FVector(0.0, -TargetOffset, 0.0));
			Data.RightMesh.SetRelativeLocation(FVector(0.0, TargetOffset, 0.0));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HackableRoot.SetRelativeLocation(FVector(SyncedOffset.Value, 0.0, 10.0));

		for (FRemoteHackableBridgePieceData& Data : PieceData)
		{
			float TargetOffset = 0;
			const FVector ToHackableRoot = (Data.RightMesh.WorldLocation - HackableRoot.WorldLocation).GetSafeNormal();

			if (Data.Root.WorldLocation.Dist2D(HackableRoot.WorldLocation) >= BRIDGE_PIECE_CONNECTION_TRACKING_DISTANCE)
			{
				TargetOffset = 1200.0;
				Data.LeftMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				Data.RightMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

				if (Data.bIsConnected)
				{
					FRemoteHackableBridgePieceEventData EventData;
					EventData.bInFront = HackableRoot.ForwardVector.DotProduct(ToHackableRoot) > 0.0;
					URemoteHackableBridgeEventHandler::Trigger_OnPiecesDisconnect(this, EventData);
				}

				Data.bIsConnected = false;
			}
			else
			{
				TargetOffset = SideOffset;
				Data.LeftMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
				Data.RightMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

				if (!Data.bIsConnected)
				{
					FRemoteHackableBridgePieceEventData EventData;
					EventData.bInFront = HackableRoot.ForwardVector.DotProduct(ToHackableRoot) > 0.0;
					URemoteHackableBridgeEventHandler::Trigger_OnPiecesStartConnection(this, EventData);
				}

				Data.bIsConnected = true;
			}

			float CurOffset = Math::FInterpConstantTo(Data.RightMesh.RelativeLocation.Y, TargetOffset, DeltaTime, 1600.0);
			Data.LeftMesh.SetRelativeLocation(FVector(0.0, -CurOffset, 0.0));
			Data.RightMesh.SetRelativeLocation(FVector(0.0, CurOffset, 0.0));

			if (Math::IsNearlyEqual(CurOffset, SideOffset))
			{
				if (!Data.bFullyConnected)
				{
					Data.bFullyConnected = true;
					ForceFeedback::PlayWorldForceFeedback(PiecesConnectedFF, Data.Root.WorldLocation, true, this, 200.0, 200.0);
				}
			}
			else
			{
				Data.bFullyConnected = false;
			}
		}
	}
}

struct FRemoteHackableBridgePieceData
{
	USceneComponent Root;
	UStaticMeshComponent LeftMesh;
	UStaticMeshComponent RightMesh;

	bool bFullyConnected = false;

	//Audio
	bool bIsConnected = false;
}

class URemoteHackableBridgeCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ARemoteHackableBridge Bridge;

	float MoveSpeed = 550.0;
	float CurSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Bridge = Cast<ARemoteHackableBridge>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Bridge.SyncedOffset.OverrideSyncRate(EHazeCrumbSyncRate::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Bridge.SyncedOffset.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if(HasControl())
		{
			FVector Input = PlayerMoveComp.MovementInput;
			
			Input = Input.ConstrainToDirection(Bridge.ActorForwardVector);

			CurSpeed = Math::FInterpTo(CurSpeed, -Input.Y * MoveSpeed, DeltaTime, 4.0);
			const float CurrentOffset = Bridge.SyncedOffset.Value;
			const float NewOffset = Math::Clamp(CurrentOffset + (CurSpeed * DeltaTime), Bridge.MinOffset, Bridge.MaxOffset);
			Bridge.SyncedOffset.SetValue(NewOffset);
		}
	}
}

class URemoteHackableBridgeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnPiecesStartConnection(FRemoteHackableBridgePieceEventData EventData) {}

	UFUNCTION(BlueprintEvent)
	void OnPiecesDisconnect(FRemoteHackableBridgePieceEventData EventData) {}
}