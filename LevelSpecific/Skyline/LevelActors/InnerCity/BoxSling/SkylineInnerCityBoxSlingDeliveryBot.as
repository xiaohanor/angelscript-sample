class ASkylineInnerCityBoxSlingDeliveryBot : AHazeActor
{	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BodyMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PropellerMesh;

	UPROPERTY(DefaultComponent, Attach = BodyMesh)
	UHazeTEMPCableComponent Cable;
	default Cable.bAutoCableLength = true;
	default Cable.CableFriction = 1.0;
	default Cable.CableWidth = 5.0;
	default Cable.bEnableStiffness = true;

	UPROPERTY(EditInstanceOnly)
	ASplineActor EntrySplineRoute;

	UPROPERTY(EditInstanceOnly)
	ASplineActor ExitSplineRoute;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineInnerCityBoxSlingDeliveryBotClaws> ClawClass;

	ASkylineInnerCityBoxSlingDeliveryBotClaws Claws;

	ASkylineInnerCityBoxSling CarriedBox;

	UPROPERTY(EditDefaultsOnly)
	float RopeLength = 200.0;
	UPROPERTY(EditDefaultsOnly)
	float PropellerRotationSpeedDegreesPerSecond = 360.0 * 6.0; // how many turns per second?
	private float PropellerYaw = 0.0;

	FHazeRuntimeSpline RopeRuntimeSpline;
	FHazeAcceleratedVector AccClawPosition;

	float RopeMeshHeight = 1.0;

	float DropOffTime = 1.0;
	float DropOffTimer = 0.0;
	bool bEntering = false;
	bool bDelivering = false;

	FSkylineInnerCityBoxSlingDeliveryBotEventTriggers Triggers;

	FHazeAcceleratedVector AccPosition;
	FHazeAcceleratedFloat AccSpeed;
	
	ASkylineInnerCityBoxSlingSpawner MySpawner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector LocationBeneath = ActorLocation;
		LocationBeneath.Z -= RopeLength;
		Claws = SpawnActor(ClawClass, LocationBeneath, ActorRotation, bDeferredSpawn = true);
		Claws.MakeNetworked(this, 0);
		FinishSpawningActor(Claws);
		AccClawPosition.SnapTo(LocationBeneath);

		
	}

	UFUNCTION()
	private void HandlePlayerCrushed(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                 UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                 const FHitResult&in SweepResult)
	{
	}

	void SetBox(ASkylineInnerCityBoxSling Boxy) // The Set Box is a SetBox again hehe lol
	{
		if (EntrySplineRoute == nullptr)
			return;
		if (bDelivering)
			return;
		Triggers = FSkylineInnerCityBoxSlingDeliveryBotEventTriggers();
		{
			Triggers.bTriggeredStart = true;
			USkylineInnerCityBoxSlingDeliveryBotEventHandler::Trigger_OnDeliveryBotStart(this);
		}
		bDelivering = true;
		CarriedBox = Boxy;
		CarriedBox.AttachToActor(Claws);
		CarriedBox.SetActorRelativeLocation(FVector(0.0, 0.0, -200.0));
		CarriedBox.SetActorRelativeRotation(FRotator(0, -90, 0));
		CarriedBox.GravityWhipTargetComponent.Disable(this);
		CarriedBox.InteractionComp.Disable(this);
		DropOffTimer = 0.0;
		bEntering= true;
		FHitResult Unused;
		FVector EntryLocation = EntrySplineRoute.Spline.GetWorldLocationAtSplineDistance(0.0);
		SetActorLocation(EntryLocation, false, Unused, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateRope();
		UpdatePropeller(DeltaSeconds);
		UpdateSplinePosition(DeltaSeconds);
	}

	void UpdatePropeller(float DeltaSeconds)
	{
		PropellerYaw += DeltaSeconds * PropellerRotationSpeedDegreesPerSecond;
		FRotator RelativeRot = PropellerMesh.RelativeRotation;
		
		if (PropellerYaw > 360.0)
			PropellerYaw -= 360.0;
		if (PropellerYaw < 0.0)
			PropellerYaw += 360.0;

		RelativeRot.Yaw = PropellerYaw;
		PropellerMesh.SetRelativeRotation(RelativeRot);
	}

	void UpdateRope()
	{
		Cable.StartLocation = FVector::ZeroVector;
		Cable.EndLocation = ActorTransform.InverseTransformPositionNoScale(Claws.ActorLocation);
	}

	private void UpdateSplinePosition(float DeltaSeconds)
	{
		if (EntrySplineRoute == nullptr || ExitSplineRoute == nullptr)
			return;
		if (!bDelivering)
			return;
		if (bEntering)
			MoveAlongSpline(EntrySplineRoute, DeltaSeconds, false);
		else if (DropOffTimer < DropOffTime)
			DropTheBox(DeltaSeconds);
		else
		{
			if (!Triggers.bTriggeredRetractStop)
			{
				Triggers.bTriggeredRetractStop = true;
				USkylineInnerCityBoxSlingDeliveryBotEventHandler::Trigger_OnDeliveryRetractStop(this);
			}
			MoveAlongSpline(ExitSplineRoute, DeltaSeconds, true);
		}
	}

	private void DropTheBox(float DeltaSeconds)
	{
		// USanctuaryLavamoleEventHandler::Trigger_OnBoulderTelegraph(Owner, FSanctuaryLavamoleOnBoulderTelegraphEventData(ProjectileLauncher.LaunchLocation));

		DropOffTimer += DeltaSeconds;
		float DropDuration = DropOffTime * 0.75;
		float RetractDuration = DropOffTime - DropDuration;

		if (!Triggers.bTriggeredDropStart)
		{
			Triggers.bTriggeredDropStart = true;
			USkylineInnerCityBoxSlingDeliveryBotEventHandler::Trigger_OnDeliveryDropStart(this);
		}

		if (DropOffTimer < DropDuration)
		{
			Claws.SetOpenClaws(true);
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);
			TraceSettings.IgnoreActor(this);
			TraceSettings.IgnoreActor(CarriedBox);
			TraceSettings.IgnorePlayers();
			FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + FVector::DownVector * 1500.0);

			FVector ClawTargetPos = Hit.ImpactPoint;
			ClawTargetPos.Z += CarriedBox.MeshSlingbox.BoundsExtent.Z * 2.0;
			ClawTargetPos.Z += 30.0;
			AccClawPosition.AccelerateTo(ClawTargetPos, DropDuration, DeltaSeconds);
			Claws.SetActorLocation(AccClawPosition.Value);
		}
		else
		{
			if (!Triggers.bTriggeredDropStop)
			{
				Triggers.bTriggeredDropStop = true;
				USkylineInnerCityBoxSlingDeliveryBotEventHandler::Trigger_OnDeliveryDropStop(this);
			}
			if (!Triggers.bTriggeredRetractStart)
			{
				Triggers.bTriggeredRetractStart = true;
				USkylineInnerCityBoxSlingDeliveryBotEventHandler::Trigger_OnDeliveryRetractStart(this);
			}

			if (CarriedBox != nullptr)
			{
				CarriedBox.DeactivateDeathBox();
				CarriedBox.PlayDoorAnimation();
				CarriedBox.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
				CarriedBox.GravityWhipTargetComponent.Enable(this);
				CarriedBox.InteractionComp.Enable(this);
				CarriedBox.OnSkylineInnerCityBoxSlingLanded.Broadcast();
				MySpawner.OnSkylineInnerCityBoxSlingLanded.Broadcast(CarriedBox);
				CarriedBox = nullptr;
			}

			FVector ClawOriginalPos = ActorLocation;
			ClawOriginalPos.Z -= RopeLength;
			AccClawPosition.AccelerateTo(ClawOriginalPos, RetractDuration, DeltaSeconds);
			Claws.SetActorLocation(AccClawPosition.Value);
		}
	}

	private void MoveAlongSpline(ASplineActor SplineActor, float DeltaSeconds, bool bExitSpline)
	{
		float Distance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		
		float TravesedPercent = (Distance / SplineActor.Spline.SplineLength) * 2.0;
		if (TravesedPercent > 1.0)
			TravesedPercent = 1.0 - (TravesedPercent - 1.0);

		float MinSpeed = bExitSpline ? 200.0 : 100.0;
		float MaxSpeed = bExitSpline ? 100.0 : 500.0;
		AccSpeed.AccelerateTo(Math::Lerp(MinSpeed, MaxSpeed, TravesedPercent), 0.2, DeltaSeconds);

		float NewDistance = Distance + AccSpeed.Value;
		if (NewDistance >= SplineActor.Spline.SplineLength)
		{
			if (bExitSpline)
			{
				if (!Triggers.bTriggeredStop)
				{
					Triggers.bTriggeredStop = true;
					USkylineInnerCityBoxSlingDeliveryBotEventHandler::Trigger_OnDeliveryBotStop(this);
				}

				bDelivering = false;
			}
			else
			{
				bEntering = false;
			}
		}
		Distance = Math::Clamp(Distance + AccSpeed.Value, 0.0, SplineActor.Spline.SplineLength);
		FVector NewTargetPos = SplineActor.Spline.GetWorldLocationAtSplineDistance(Distance);
		AccPosition.AccelerateTo(NewTargetPos, 1.0, DeltaSeconds);
		SetActorLocation(AccPosition.Value);

		FVector ClawPos = ActorLocation;
		ClawPos.Z -= RopeLength;
		AccClawPosition.AccelerateTo(ClawPos, 0.3, DeltaSeconds);
		Claws.SetActorLocation(AccClawPosition.Value);
	}
};

class ASkylineInnerCityBoxSlingDeliveryBotClaws : AHazeActor
{	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Claw1Mesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Claw2Mesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Claw3Mesh;

	private FHazeAcceleratedFloat AccClawsPitchRot;
	private const float OpenPitch = 0.0;
	private const float ClosedPitch = 15.0;
	private bool bOpen = false;
	private float LastPitch = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccClawsPitchRot.SnapTo(Claw1Mesh.RelativeRotation.Pitch);
		LastPitch = AccClawsPitchRot.Value;
	}

	void SetOpenClaws(bool YesOpen)
	{
		bOpen = YesOpen;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float TargetPitch = bOpen ? OpenPitch : ClosedPitch;
		AccClawsPitchRot.SpringTo(TargetPitch, 20.0, 0.7, DeltaSeconds);
		if (!Math::IsNearlyEqual(LastPitch, AccClawsPitchRot.Value))
		{
			LastPitch = AccClawsPitchRot.Value;
			SetPitch(Claw1Mesh, AccClawsPitchRot.Value);
			SetPitch(Claw2Mesh, AccClawsPitchRot.Value);
			SetPitch(Claw3Mesh, AccClawsPitchRot.Value);
		}
	}

	private void SetPitch(UStaticMeshComponent ClawMesh, float Pitch)
	{
		FRotator RelativeRot = ClawMesh.RelativeRotation;
		RelativeRot.Pitch = Pitch;
		ClawMesh.SetRelativeRotation(RelativeRot);
	}
};