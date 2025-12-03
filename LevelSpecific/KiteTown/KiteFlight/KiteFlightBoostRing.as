UCLASS(Abstract)
class AKiteFlightBoostRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RingRoot;

	UPROPERTY(DefaultComponent, Attach = RingRoot)
	USceneComponent RespawnRoot;

	UPROPERTY(DefaultComponent, Attach = RingRoot)
	USceneComponent RotatorRoot;

	UPROPERTY(DefaultComponent, Attach = RingRoot)
	UHazeMovablePlayerTriggerComponent PlayerTriggerBox;

	UPROPERTY(DefaultComponent, Attach = RingRoot)
	UHazeMovablePlayerTriggerComponent PlayerSphereTrigger;
	default PlayerSphereTrigger.Shape = FHazeShapeSettings::MakeSphere(550.0);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent MissTrigger1;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent MissTrigger2;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent MissTrigger3;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent MissTrigger4;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UKiteFlightBoostRingComponenent KiteFlightBoostRingComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UKiteFlightBoostRingDrawComponent DrawComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 25000.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(EditAnywhere)
	float BoostValue = 2500.0;

	FHazeAcceleratedFloat AccRotationSpeed;
	float RotationSpeed = 30.0;

	float HoverTimeOffset;

	UPROPERTY(EditDefaultsOnly)
	FKiteHoverValues HoverValues;

	UPROPERTY(EditAnywhere)
	bool bEnabled = true;

	UPROPERTY(EditAnywhere)
	bool bHasRespawnPoint = true;
	ARespawnPoint RespawnPoint;

	UPROPERTY(EditAnywhere)
	FRotator RespawnRotationOffset = FRotator::ZeroRotator;

	UPROPERTY(EditAnywhere)
	float MissTriggerSize = 1000.0;

	UPROPERTY(EditAnywhere)
	bool bMovable = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		RespawnRoot.SetRelativeRotation(FRotator(RespawnRotationOffset.Pitch, RespawnRotationOffset.Yaw, 0.0));

		TArray<UBoxComponent> MissTriggers;
		MissTriggers.Add(MissTrigger1);
		MissTriggers.Add(MissTrigger2);
		MissTriggers.Add(MissTrigger3);
		MissTriggers.Add(MissTrigger4);
		for (UBoxComponent MissTrigger : MissTriggers)
		{
			MissTrigger.SetBoxExtent(FVector(50.0, MissTriggerSize, MissTriggerSize));
		}

		RootComp.SetMobility(bMovable ? EComponentMobility::Movable : EComponentMobility::Static);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTriggerBox.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");

		HoverTimeOffset = Math::RandRange(0.0, 2.0);

		if (bHasRespawnPoint)
		{
			RespawnPoint = SpawnActor(ARespawnPoint, bDeferredSpawn = true);
			RespawnPoint.MakeNetworked(this);
			FinishSpawningActor(RespawnPoint);
			RespawnPoint.AttachToComponent(RespawnRoot);
			RespawnPoint.OnRespawnAtRespawnPoint.AddUFunction(this, n"PlayerRespawned");
		}

		AccRotationSpeed.SnapTo(RotationSpeed);

		MissTrigger1.OnComponentBeginOverlap.AddUFunction(this, n"Missed");
		MissTrigger2.OnComponentBeginOverlap.AddUFunction(this, n"Missed");
		MissTrigger3.OnComponentBeginOverlap.AddUFunction(this, n"Missed");
		MissTrigger4.OnComponentBeginOverlap.AddUFunction(this, n"Missed");
	}

	UFUNCTION()
	private void Missed(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (PlayerSphereTrigger.IsPlayerInTrigger(Player))
			return;

		UKiteTownVOEffectEventHandler::Trigger_MissFlightRing(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
		Print("MISSEED! get gud scrub");
	}

	UFUNCTION()
	private void PlayerRespawned(AHazePlayerCharacter RespawningPlayer)
	{
		UKiteFlightPlayerComponent KiteFlightPlayerComp = UKiteFlightPlayerComponent::Get(RespawningPlayer);
		KiteFlightPlayerComp.ActivateFlight(ActorForwardVector);
	}

	UFUNCTION()
	void Enable()
	{
		bEnabled = true;
		BP_Enable();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Enable() {}

	UFUNCTION()
	void Disable()
	{
		BP_Disable();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Disable() {}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (!bEnabled)
			return;

		if (!PlayerSphereTrigger.IsPlayerInTrigger(Player))
			return;

		UKiteFlightPlayerComponent KiteFlightPlayerComp = UKiteFlightPlayerComponent::Get(Player);
		if (KiteFlightPlayerComp.bFlightActive)
			KiteFlightPlayerComp.TriggerBoost(BoostValue);
		else
		{
			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
			FVector PlayerDir = MoveComp.Velocity.GetSafeNormal();

			FVector BoostDir = ActorForwardVector;
			if (PlayerDir.DotProduct(ActorForwardVector) < 0)
				BoostDir = -ActorForwardVector;

			KiteFlightPlayerComp.ActivateFlight(BoostDir);
		}

		Player.PlayCameraShake(CamShake, this, 0.25);

		Player.SetStickyRespawnPoint(RespawnPoint);

		AccRotationSpeed.SnapTo(RotationSpeed * 6.0);

		UKiteFlightBoostRingEffectEventHandler::Trigger_Boost(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bEnabled)
			return;

		AccRotationSpeed.AccelerateTo(RotationSpeed, 4.0, DeltaTime);
		RotatorRoot.AddLocalRotation(FRotator(0.0, 0.0, AccRotationSpeed.Value * DeltaTime));

		float Time = Time::GameTimeSeconds + HoverTimeOffset;
		float Roll = Math::DegreesToRadians(Math::Sin(Time * HoverValues.HoverRollSpeed) * HoverValues.HoverRollRange);
		float Pitch = Math::DegreesToRadians(Math::Cos(Time * HoverValues.HoverPitchSpeed) * HoverValues.HoverPitchRange);
		FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

		RingRoot.SetRelativeRotation(Rotation);

		float XOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.X) * HoverValues.HoverOffsetRange.X;
		float YOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Y) * HoverValues.HoverOffsetRange.Y;
		float ZOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Z) * HoverValues.HoverOffsetRange.Z;

		FVector Offset = (FVector(XOffset, YOffset, ZOffset));

		RingRoot.SetRelativeLocation(Offset);
	}
}

class UKiteFlightBoostRingComponenent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	bool bVisualizeRange = false;

	float Range = 16000.0;
}

class UKiteFlightBoostRingDrawComponent : UHazeEditorRenderedComponent
{
	default bIsEditorOnly = true;
	default SetHiddenInGame(true);

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		UKiteFlightBoostRingComponenent Comp = Owner.GetComponentByClass(UKiteFlightBoostRingComponenent);
		if (Comp == nullptr)
			return;

		SetActorHitProxy();

		if(Comp.bVisualizeRange)
		{
			DrawArc(Comp.WorldLocation, 30.0, Comp.Range, Comp.Owner.ActorForwardVector, FLinearColor::Green, 20.0, Comp.Owner.ActorUpVector, 24);
			DrawArc(Comp.WorldLocation, 30.0, Comp.Range, Comp.Owner.ActorForwardVector, FLinearColor::Green, 20.0, Comp.Owner.ActorRightVector, 24);
			DrawLine(Comp.WorldLocation, Comp.WorldLocation + (Comp.Owner.ActorForwardVector * Comp.Range), FLinearColor::Green, 20.0);
		}
		
		ClearHitProxy();
#endif
	}
}