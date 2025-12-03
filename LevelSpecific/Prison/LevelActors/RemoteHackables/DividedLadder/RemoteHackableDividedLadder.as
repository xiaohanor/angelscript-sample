UCLASS(Abstract)
class ARemoteHackableDividedLadder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LadderRoot;

	UPROPERTY(DefaultComponent, Attach = LadderRoot)
	USceneComponent SegmentsRoot;

	UPROPERTY(DefaultComponent, Attach = LadderRoot)
	UHazeMovablePlayerTriggerComponent PlayerTrigger;

	UPROPERTY(DefaultComponent, Attach = LadderRoot)
	USceneComponent HackableRoot;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	UBoxComponent ZoeAboveBlocker;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	UBoxComponent MioAboveBlocker;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	URemoteHackingResponseComponent RemoteHackingResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableDividedLadderCapability");

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;
	default CapabilityRequestComp.PlayerCapabilities.Add(n"RemoteHackableDividedLadderPlayerValidityCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedHackableOffset;
	default SyncedHackableOffset.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.0;

	UPROPERTY(EditInstanceOnly)
	ALadder RealLadder;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh SegmentMesh;

	UPROPERTY(EditAnywhere)
	int Segments = 26.0;

	float MaxSegmentSideOffset = 60.0;

	UPROPERTY(EditAnywhere)
	private float InitialHackableOffset = 800.0;
	float MaxHackableOffset;

	UPROPERTY(NotEditable, NotVisible)
	TArray<USceneComponent> SegmentRoots;

	UPROPERTY(NotEditable, NotVisible)
	TArray<USceneComponent> SegmentMeshes;

	TArray<int> ConnectedSegments;
	TArray<int> MovingToConnectSegments;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SegmentConnectedFF;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SegmentRoots.Empty();

		for (int i = 0; i <= Segments; i++)
		{
			USceneComponent SegmentRoot = USceneComponent::Create(this, FName(f"Segment_{i}"));
			SegmentRoot.AttachToComponent(SegmentsRoot);
			SegmentRoot.SetRelativeLocation(FVector(0.0, 0.0, 50.0 * i));
			
			UStaticMeshComponent LeftMeshComp = UStaticMeshComponent::Create(this, FName(f"LeftMesh_{i}"));
			LeftMeshComp.AttachToComponent(SegmentRoot);
			LeftMeshComp.SetRelativeLocation(FVector(0.0, MaxSegmentSideOffset, 0.0));
			LeftMeshComp.SetStaticMesh(SegmentMesh);
			LeftMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			LeftMeshComp.SetCullDistance(7500.0);

			UStaticMeshComponent RightMeshComp = UStaticMeshComponent::Create(this, FName(f"RightMesh_{i}"));
			RightMeshComp.AttachToComponent(SegmentRoot);
			RightMeshComp.SetRelativeRotation(FRotator(0.0, 180.0, 0.0));
			RightMeshComp.SetRelativeLocation(FVector(0.0, -MaxSegmentSideOffset, 0.0));
			RightMeshComp.SetStaticMesh(SegmentMesh);
			RightMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			RightMeshComp.SetCullDistance(7500.0);

			SegmentMeshes.Add(LeftMeshComp);
			SegmentMeshes.Add(RightMeshComp);

			SegmentRoots.Add(SegmentRoot);

			//Ugly last-day-of-free-submits-hack to make the bottom rung not show so it matches the hidden ladder in the level
			if (i == 0)
			{
				LeftMeshComp.SetHiddenInGame(true);
				RightMeshComp.SetHiddenInGame(true);
			}
		}

		HackableRoot.SetRelativeLocation(FVector(0.0, 0.0, InitialHackableOffset));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		SyncedHackableOffset.SetValue(InitialHackableOffset);
		
		MaxHackableOffset = (Segments * 50) - 200.0;

		if (RealLadder != nullptr)
			RealLadder.SetActorEnableCollision(false);

		UHazeMovementComponent MioMoveComp = UHazeMovementComponent::Get(Game::Mio);
		MioMoveComp.AddMovementIgnoresComponent(this, ZoeAboveBlocker);

		UHazeMovementComponent ZoeMoveComp = UHazeMovementComponent::Get(Game::Zoe);
		ZoeMoveComp.AddMovementIgnoresComponent(this, MioAboveBlocker);

		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"PlayerLeave");

		MioAboveBlocker.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ZoeAboveBlocker.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		URemoteHackableDividerLadderPlayerValidityComponent LadderComp = URemoteHackableDividerLadderPlayerValidityComponent::GetOrCreate(Player);
		LadderComp.Ladder = this;
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		URemoteHackableDividerLadderPlayerValidityComponent LadderComp = URemoteHackableDividerLadderPlayerValidityComponent::GetOrCreate(Player);
		LadderComp.Ladder = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HackableRoot.SetRelativeLocation(FVector(0.0, 0.0, SyncedHackableOffset.Value));

		float HackableOffsetAlpha = Math::GetMappedRangeValueClamped(FVector2D(50.0, MaxHackableOffset + 200.0), FVector2D(0.0, 1.0), SyncedHackableOffset.Value);

		int LastIndex = 0;
		for (int i = 0; i <= Segments; i++)
		{
			LastIndex = i;

			float IndexAsFloat = i;
			float SegmentAlpha = IndexAsFloat/Segments -0.025;

			float TargetOffset = 0.0;

			if (Math::IsNearlyEqual(HackableOffsetAlpha, SegmentAlpha, 0.15))
			{
				TargetOffset = 0.0;

				if (!MovingToConnectSegments.Contains(i))
				{
					MovingToConnectSegments.Add(i);
				
					FRemoteHackableBridgePieceEventData Data;
					Data.bInFront = SegmentMeshes[LastIndex * 2].WorldLocation.Z > HackableRoot.WorldLocation.Z;
					URemoteHackableBridgeEventHandler::Trigger_OnPiecesStartConnection(this, Data);
				}

			}
			else
			{
				TargetOffset = 60.0;

				if (MovingToConnectSegments.Contains(i))
				{				
					FRemoteHackableBridgePieceEventData Data;
					Data.bInFront = SegmentMeshes[LastIndex * 2].WorldLocation.Z > HackableRoot.WorldLocation.Z;

					URemoteHackableBridgeEventHandler::Trigger_OnPiecesDisconnect(this, Data);

					MovingToConnectSegments.RemoveSingleSwap(i);
				}
			}

			float CurOffset = Math::FInterpConstantTo(SegmentMeshes[LastIndex * 2].RelativeLocation.Y, TargetOffset, DeltaTime, 250.0);
			SegmentMeshes[LastIndex * 2].SetRelativeLocation(FVector(0.0, CurOffset, 0.0));
			SegmentMeshes[(LastIndex * 2) + 1].SetRelativeLocation(FVector(0.0, -CurOffset, 0.0));

			if (Math::IsNearlyEqual(CurOffset, 0.0))
			{
				if (!ConnectedSegments.Contains(i))
				{
					ConnectedSegments.Add(i);
					SegmentConnected();	
				}
			}
			else
			{
				if (ConnectedSegments.Contains(i))
				{
					ConnectedSegments.Remove(i);	
				}
			}
		}
	}

	bool TopSegmentConnected() const
	{
		if (ConnectedSegments.Num() != 0 && ConnectedSegments.Last() == Segments)
			return true;

		return false;
	}

	void SegmentConnected()
	{
		Game::Mio.PlayForceFeedback(SegmentConnectedFF, false, true, this);

		if (Game::Zoe.IsAnyCapabilityActive(PlayerMovementTags::Ladder))
			Game::Zoe.PlayForceFeedback(SegmentConnectedFF, false, true, this);
	}
}