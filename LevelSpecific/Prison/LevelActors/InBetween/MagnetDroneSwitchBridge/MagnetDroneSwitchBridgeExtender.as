event void FMagnetDroneSwitchBridgeExtenderEvent();

UCLASS(Abstract)
class AMagnetDroneSwitchBridgeExtender : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BridgeRoot;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	USceneComponent LeftBridgeRoot;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	USceneComponent RightBridgeRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnSegmentTimeLike;
	float SpawnSegmentStartOffset = 0.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> SpawnSegmentCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SpawnSegmentFF;

	UPROPERTY()
	FMagnetDroneSwitchBridgeExtenderEvent OnFullyExtended;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh BridgeMesh;

	float SegmentLength = 250.0;
	int SegmentsSpawned = 0;
	int MaxSegments = 18;

	bool bExtending = false;

	bool bPlayFeedbackEffects = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnSegmentTimeLike.BindUpdate(this, n"UpdateSpawnSegment");
		SpawnSegmentTimeLike.BindFinished(this, n"FinishSpawnSegment");
	}

	UFUNCTION()
	private void UpdateSpawnSegment(float CurValue)
	{
		float Offset = Math::Lerp(SpawnSegmentStartOffset, SpawnSegmentStartOffset + 250.0, CurValue);
		BridgeRoot.SetRelativeLocation(FVector(Offset, 0.0, 0.0));
	}

	UFUNCTION()
	private void FinishSpawnSegment()
	{
		if (SegmentsSpawned < MaxSegments)
		{
			SpawnSegment();
		}
		else
		{
			OnFullyExtended.Broadcast();
			UMagnetDroneSwitchBridgeExtenderEffectEventHandler::Trigger_FullyExtended(this);
		}

		if (bPlayFeedbackEffects)
		{
			for (AHazePlayerCharacter Player : Game::GetPlayers())
				Player.PlayWorldCameraShake(SpawnSegmentCamShake, this, BridgeRoot.WorldLocation, 4000.0, 6000.0, 1.0, 0.2);

			ForceFeedback::PlayWorldForceFeedback(SpawnSegmentFF, BridgeRoot.WorldLocation, true, this, 4000.0, 2000.0);
			bPlayFeedbackEffects = false;
		}
		else
		{
			bPlayFeedbackEffects = true;
		}
	}

	UFUNCTION()
	void ExtendBridge()
	{
		if (bExtending)
			return;

		bExtending = true;
		SpawnSegmentTimeLike.PlayFromStart();

		UMagnetDroneSwitchBridgeExtenderEffectEventHandler::Trigger_StartExtending(this);
	}

	void SpawnSegment()
	{
		UStaticMeshComponent LeftSegment = UStaticMeshComponent::Create(this);
		LeftSegment.AttachToComponent(LeftBridgeRoot);
		LeftSegment.SetRelativeLocation(FVector(-250.0 - (250.0 * SegmentsSpawned), 0.0, 0.0));
		LeftSegment.SetStaticMesh(BridgeMesh);
		LeftSegment.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		UStaticMeshComponent RightSegment = UStaticMeshComponent::Create(this);
		RightSegment.AttachToComponent(RightBridgeRoot);
		RightSegment.SetRelativeLocation(FVector(250.0 + (250.0 * SegmentsSpawned), 0.0, 0.0));
		RightSegment.SetStaticMesh(BridgeMesh);
		RightSegment.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		SpawnSegmentStartOffset = BridgeRoot.RelativeLocation.X;

		SegmentsSpawned++;

		SpawnSegmentTimeLike.PlayFromStart();

		UMagnetDroneSwitchBridgeExtenderEffectEventHandler::Trigger_SpawnSegment(this);
	}
}

class UMagnetDroneSwitchBridgeExtenderEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartExtending() {}
	UFUNCTION(BlueprintEvent)
	void SpawnSegment() {}
	UFUNCTION(BlueprintEvent)
	void FullyExtended() {}
}