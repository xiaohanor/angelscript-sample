event void FGarbageTruckEvent();

asset GarbageTruckSheet of UHazeCapabilitySheet
{
	Capabilities.Add(URemoteHackableGarbageTruckCapability);
	Capabilities.Add(URemoteHackableGarbageTruckDoorCapability);
};

UCLASS(Abstract)
class AGarbageTruck : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX_Wind;
	default FX_Wind.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	USceneComponent FX_DumpLocation;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TruckRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent FrontLeftThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent FrontRightThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent BackLeftThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent BackRightThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent TrashRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	UHazeCameraComponent InsideCameraComp;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	UFauxPhysicsAxisRotateComponent BottomLeftHatch;
	default BottomLeftHatch.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	UFauxPhysicsAxisRotateComponent BottomRightHatch;
	default BottomRightHatch.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	UBoxComponent PlayerTrigger;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	URemoteHackingResponseComponent HackingComp;
	default HackingComp.bAllowHacking = false;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent HackingExitComp;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USquishTriggerBoxComponent SquishComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(GarbageTruckSheet);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.0;

	UPROPERTY(EditDefaultsOnly)
	FText OpenHatchesTutorialText;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenBottomHatchesTimeLike;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UPROPERTY()
	FRemoteHackingEvent OnHacked;

	UPROPERTY()
	FGarbageTruckEvent OnPlayersLockedIn;

	UPROPERTY()
	FGarbageTruckEvent OnReachedEndOfSpline;
	bool bReachedEnd = false;

	FSplinePosition SplinePos;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 1250.0;

	UPROPERTY(EditAnywhere)
	bool bMoving = true;

	UPROPERTY(EditInstanceOnly)
	bool bPreviewPosition = false;
	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewFraction = 0.0;

	UPROPERTY(EditInstanceOnly)
	bool bResetOnEnd = false;

	UPROPERTY(EditInstanceOnly)
	bool bDetectPlayers = true;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HatchConstraintHitFF;

	bool bLockPlayersIn = false;

	TArray<AHazePlayerCharacter> PlayersInTruck;

	FVector StartLocation;
	FVector CurrentLocation;

	float HackTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewPosition)
		{
			FTransform PreviewTransform = SplineActor.Spline.GetWorldTransformAtSplineDistance(SplineActor.Spline.SplineLength * PreviewFraction);
			FRotator Rot = FRotator(PreviewTransform.Rotation);
			Rot.Pitch = Math::Clamp(Rot.Pitch, -8.0, 8.0);
			SetActorLocationAndRotation(PreviewTransform.Location, Rot);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Synced from Mio, since the hacking capabilities must be from Mio
		SetActorControlSide(Game::Mio);

		// But position is synced from Zoe
		SyncedActorPositionComp.OverrideControlSide(Game::Zoe);

		FX_Wind.DetachFromParent(true);

		OpenBottomHatchesTimeLike.BindUpdate(this, n"UpdateOpenBottomHatches");
		OpenBottomHatchesTimeLike.BindFinished(this, n"FinishOpenBottomHatches");

		if (SplineActor != nullptr)
		{
			SplinePos = FSplinePosition(SplineActor.Spline, SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation), true);
		}

		if (bDetectPlayers)
		{
			PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEnter");
			PlayerTrigger.OnComponentEndOverlap.AddUFunction(this, n"PlayerExit");
		}

		HackingComp.OnHackingStarted.AddUFunction(this, n"HackStarted");
		HackingComp.OnHackingStopped.AddUFunction(this, n"HackStopped");

		StartLocation = ActorLocation;
		CurrentLocation = ActorLocation;

		BottomRightHatch.OnMinConstraintHit.AddUFunction(this, n"FullyClosed");
		BottomRightHatch.OnMaxConstraintHit.AddUFunction(this, n"FullyOpened");

		MovementImpactCallbackComp.OnCeilingImpactedByPlayer.AddUFunction(this, n"HeadBonk");
	}

	UFUNCTION()
	private void HeadBonk(AHazePlayerCharacter Player)
	{
		if (!Player.IsZoe())
			return;

		UGarbageTruckEffectEventHandler::Trigger_HitHead(this);
	}

	UFUNCTION()
	void StartTrashCompactorSequence()
	{
		UGarbageTruckEffectEventHandler::Trigger_TrashCompactor_StartSequence(this);
	}

	UFUNCTION()
	private void FullyClosed(float Strength)
	{
		UGarbageTruckEffectEventHandler::Trigger_DoorFullyClosed(this);

		if (HatchConstraintHitFF != nullptr && HackingComp.bHacked)
			Game::Mio.PlayForceFeedback(HatchConstraintHitFF, false, true, this);

		if (bLockPlayersIn)
			return;

		// Only Zoe side can trigger it being closed, since her position on her screen is what matters
		if (!Game::Zoe.HasControl())
			return;

		if (!PlayersInTruck.Contains(Game::Zoe))
			return;

		CrumbFullyClosed();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFullyClosed()
	{
		Game::Mio.TeleportActor(HackingExitComp.WorldLocation, HackingExitComp.WorldRotation, this, false);
		LockPlayersIn();
	}

	UFUNCTION()
	private void FullyOpened(float Strength)
	{
		UGarbageTruckEffectEventHandler::Trigger_DoorFullyOpened(this);
	}

	UFUNCTION()
	private void HackStarted()
	{
		HackTime = 0.0;

		SetActorTickEnabled(true);

		OnHacked.Broadcast();

		UGarbageTruckEffectEventHandler::Trigger_MovingUp(this);
	}

	UFUNCTION()
	private void HackStopped()
	{
		if (bLockPlayersIn)
			return;

		UGarbageTruckEffectEventHandler::Trigger_MovingDown(this);
	}

	UFUNCTION()
	private void PlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (bLockPlayersIn)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (PlayersInTruck.Contains(Player))
			return;

		if (Player.IsPlayerDead())
			return;

		PlayersInTruck.Add(Player);
	}

	UFUNCTION()
	private void PlayerExit(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (bLockPlayersIn)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!PlayersInTruck.Contains(Player))
			return;

		PlayersInTruck.Remove(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{ 
		if (bMoving)
		{
			if (SplinePos.CurrentSpline != nullptr)
			{
				SplinePos.Move(MoveSpeed * DeltaTime);
				FRotator TargetRot = FRotator(SplinePos.WorldRotation);
				TargetRot.Pitch = Math::Clamp(TargetRot.Pitch, -8.0, 8.0);

				FVector Loc = Math::VInterpTo(ActorLocation, SplinePos.WorldLocation, DeltaTime, 3.0);
				FRotator Rot = Math::RInterpTo(ActorRotation, TargetRot, DeltaTime, 2.0);
				SetActorLocationAndRotation(Loc, Rot);

				if (!SplinePos.CurrentSpline.IsClosedLoop() && SplinePos.CurrentSplineDistance >= SplinePos.CurrentSpline.SplineLength)
				{
					if (bResetOnEnd)
					{
						SplinePos = FSplinePosition(SplineActor.Spline, 0.0, true);
						TeleportActor(SplinePos.WorldLocation, SplinePos.WorldRotation.Rotator(), this);
					}
					else
					{
						bReachedEnd = true;
						SetActorTickEnabled(false);
						OnReachedEndOfSpline.Broadcast();
					}
				}
			}
		}

		if (HackingComp.bAllowHacking && !bLockPlayersIn)
		{
			if(SyncedActorPositionComp.HasControl())
			{
				FVector TargetLoc = HackingComp.bHacked ? StartLocation + FVector(0.0, 0.0, 1100.0) : StartLocation;
				float InterpSpeed = HackingComp.bHacked ? 1.0 : 1.75;
				CurrentLocation = Math::VInterpTo(ActorLocation, TargetLoc, DeltaTime, InterpSpeed);
				SetActorLocation(CurrentLocation);
			}
			else
			{
				SetActorLocation(SyncedActorPositionComp.GetPosition().WorldLocation);
			}

			FVector TruckRootLoc = Math::VInterpConstantTo(TruckRoot.RelativeLocation, FVector::ZeroVector, DeltaTime, 10.0);
			TruckRoot.SetRelativeLocation(TruckRootLoc);
		}

		if (HackingComp.bHacked)
		{
			HackTime += DeltaTime;
			float HoverOffset = Math::Sin(HackTime * 1.5) * 8.0;

			float XOffset = Math::Sin(HackTime * 1.3) * 10.0;
			float YOffset = Math::Sin(HackTime * 2.2) * 5.0;
			TruckRoot.SetRelativeLocation(FVector(XOffset, YOffset, HoverOffset));
		}
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void StartMoving()
	{
		bMoving = true;

		UGarbageTruckEffectEventHandler::Trigger_StartMoving(this);
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void StopMoving()
	{
		bMoving = false;
	}

	UFUNCTION(BlueprintCallable)
	void ReleasePlayers()
	{
		Timer::SetTimer(this, n"OpenBottomHatches", 5.3);

		UGarbageTruckEffectEventHandler::Trigger_TrashCompactor_Dock(this);
	}

	UFUNCTION(DevFunction)
	void OpenBottomHatches()
	{
		BottomLeftHatch.AddDisabler(this);
		BottomRightHatch.AddDisabler(this);
		OpenBottomHatchesTimeLike.PlayFromStart();

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			ATrashCompactorGarbageTruckTrash Trash = Cast<ATrashCompactorGarbageTruckTrash>(Actor);
			if (Trash != nullptr)
				Trash.StartFalling(this);
		}

		UGarbageTruckEffectEventHandler::Trigger_TrashCompactor_OpenHatches(this);
	}

	UFUNCTION(DevFunction)
	void CloseBottomHatches()
	{
		OpenBottomHatchesTimeLike.ReverseFromEnd();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenBottomHatches(float CurValue)
	{
		float CurRot = Math::Lerp(0.0, 90.0, CurValue);
		BottomLeftHatch.SetRelativeRotation(FRotator(0.0, 0.0, CurRot));
		BottomRightHatch.SetRelativeRotation(FRotator(0.0, 0.0, -CurRot));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishOpenBottomHatches()
	{

	}

	UFUNCTION(BlueprintCallable)
	void LockPlayersIn()
	{
		if (bLockPlayersIn)
			return;

		HackingComp.Disable(Game::Mio);

		bLockPlayersIn = true;
		BP_LockPlayersIn();

		OnPlayersLockedIn.Broadcast();

		Timer::SetTimer(this, n"DisableHacking", 2.0);

		UGarbageTruckEffectEventHandler::Trigger_StartAlarm(this);
	}

	UFUNCTION()
	private void DisableHacking()
	{
		HackingComp.SetHackingAllowed(false);
		HackingComp.ExitLaunchForce = FVector::RightVector * 200.0;
	}

	UFUNCTION(BlueprintEvent)
	void BP_LockPlayersIn() {}

	UFUNCTION()
	void SetRelativePlayerTransforms()
	{
		UGarbageTruckSingleton Singleton = Game::GetSingleton(UGarbageTruckSingleton);
		Singleton.bTransformsSaved = true;

		FVector MioRelativeLoc = ActorTransform.InverseTransformPosition(Game::Mio.ActorLocation);
		MioRelativeLoc.X = Math::Clamp(MioRelativeLoc.X, -400.0, 500.0);
		MioRelativeLoc.Y = Math::Clamp(MioRelativeLoc.Y, -250.0, 250.0);
		FRotator MioRelativeRot = ActorTransform.InverseTransformRotation(Game::Mio.ActorRotation);
		Singleton.MioTransform = FTransform(MioRelativeRot, MioRelativeLoc);

		FVector ZoeRelativeLoc = ActorTransform.InverseTransformPosition(Game::Zoe.ActorLocation);
		ZoeRelativeLoc.X = Math::Clamp(ZoeRelativeLoc.X, -400.0, 500.0);
		ZoeRelativeLoc.Y = Math::Clamp(ZoeRelativeLoc.Y, -250.0, 250.0);
		FRotator ZoeRelativeRot = ActorTransform.InverseTransformRotation(Game::Zoe.ActorRotation);
		Singleton.ZoeTransform = FTransform(ZoeRelativeRot, ZoeRelativeLoc);
	}

	UFUNCTION(BlueprintPure)
	FTransform GetMioWorldTransform()
	{
		FVector Loc = ActorTransform.TransformPosition(GetSingleton().MioTransform.Location);
		FRotator Rot = ActorTransform.TransformRotation(GetSingleton().MioTransform.Rotator());
		return FTransform(Rot, Loc);
	}

	UFUNCTION(BlueprintPure)
	FTransform GetZoeWorldTransform()
	{
		FVector Loc = ActorTransform.TransformPosition(GetSingleton().ZoeTransform.Location);
		FRotator Rot = ActorTransform.TransformRotation(GetSingleton().ZoeTransform.Rotator());
		return FTransform(Rot, Loc);
	}

	UFUNCTION(BlueprintPure)
	UGarbageTruckSingleton GetSingleton()
	{
		return Game::GetSingleton(UGarbageTruckSingleton);
	}
}