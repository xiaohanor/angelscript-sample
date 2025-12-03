event void FPrisonBossBrainEyeRippedOutEvent();
event void FPrisonBossBrainEyeEvent();

UCLASS(Abstract)
class APrisonBossBrainEye : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent EyeRoot;

	UPROPERTY(DefaultComponent, Attach = EyeRoot)
	USceneComponent GlobeRoot;

	UPROPERTY(DefaultComponent, Attach = GlobeRoot)
	USceneComponent PulseSpawnRoot;

	UPROPERTY(DefaultComponent, Attach = EyeRoot)
	USceneComponent CableRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly)
	AActor MidPoint;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RipOutTimeLike;
	FVector RipOutStartLoc;
	FVector RipOutEndLoc;

	UPROPERTY()
	FPrisonBossBrainEyeRippedOutEvent OnEyeRippedOut;
	bool bEyeRippedOut = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APrisonBossBrainEyePulseAttack> PulseAttackClass;
	int PulsesSpawned = 0;
	FTimerHandle PulseAttackTimerHandle;
	FTimerHandle PulseAttackWaveTimerHandle;
	TArray<APrisonBossBrainEyePulseAttack> ActivePulseAttacks;

	bool bTrackPlayer = false;

	UPROPERTY(EditInstanceOnly)
	AActor WeakenedLocation;

	bool bWeakened = false;
	bool bInWeakenedPosition = false;

	UPROPERTY(EditAnywhere)
	float SplineOffset = -1150.0;

	FTransform SocketTransform;
	bool bReturningToSocket = false;

	UPROPERTY(EditAnywhere)
	float MinSplineDist = 0.0;

	UPROPERTY(EditAnywhere)
	float MaxSplineDist = 15000.0;

	bool bTwitching = false;

	FHazeAcceleratedFloat AccTrackPlayerSpeed;

	float TwitchStartTime = 0.0;

	APrisonBoss BossActor;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ReturnToSocketTimeLike;
	FVector ReturnToSocketStartLoc;
	FRotator ReturnToSocketStartRot;
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ReturnToSocketRotationCurve;
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ReturnToSocketVerticalCurve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor != nullptr)
			SplineComp = UHazeSplineComponent::Get(SplineActor);

		RipOutTimeLike.BindUpdate(this, n"UpdateRipOut");
		RipOutTimeLike.BindFinished(this, n"FinishRipOut");

		SocketTransform = ActorTransform;

		BossActor = TListedActors<APrisonBoss>().Single;

		ReturnToSocketTimeLike.BindUpdate(this, n"UpdateReturnToSocket");
		ReturnToSocketTimeLike.BindFinished(this, n"FinishReturnToSocket");
	}

	UFUNCTION()
	void RipOutEye()
	{
		AccTrackPlayerSpeed.SnapTo(0.0);

		RipOutStartLoc = ActorLocation;
		RipOutEndLoc = SplineComp.GetClosestSplineWorldLocationToWorldLocation(ActorLocation) + (ActorForwardVector * 600.0) + (FVector::UpVector * 200.0);

		RipOutTimeLike.PlayFromStart();

		BP_RipOutEye();

		UPrisonBossBrainEyeEffectEventHandler::Trigger_RipOut(this);

		BossActor.EyeRippedOut();
	}

	UFUNCTION(BlueprintEvent)
	void BP_RipOutEye() {}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRipOut(float CurValue)
	{
		FVector Loc = Math::Lerp(RipOutStartLoc, RipOutEndLoc, CurValue);
		SetActorLocation(Loc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRipOut()
	{
		SetEyeRippedOut(false);
	}

	UFUNCTION()
	void SetEyeRippedOut(bool bSnap)
	{	
		if (bEyeRippedOut)
			return;

		bEyeRippedOut = true;
		OnEyeRippedOut.Broadcast();

		if (bSnap)
		{
			float SplineDist = SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation) + SplineOffset;
			SplineDist = Math::Clamp(SplineDist, MinSplineDist, MaxSplineDist);

			FVector Loc = SplineComp.GetWorldLocationAtSplineDistance(SplineDist);
			Loc.Z += 400.0;
			SetActorLocation(Loc);

			FVector Dir = (Game::Mio.ActorCenterLocation - ActorLocation).GetSafeNormal();
			SetActorRotation(Dir.Rotation());
		}
	}

	UFUNCTION()
	void ActivatePulseAttack()
	{
		PulsesSpawned = 0;
		SpawnPulseWave();
	}

	UFUNCTION()
	void DeactivatePulseAttack()
	{
		PulseAttackTimerHandle.ClearTimerAndInvalidateHandle();
		PulseAttackWaveTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION(NotBlueprintCallable)
	void SpawnPulseWave()
	{
		PulsesSpawned = 0;
		PulseAttackTimerHandle = Timer::SetTimer(this, n"SpawnPulseAttack", PrisonBoss::PulseAttackInterval, true);
	}

	UFUNCTION(NotBlueprintCallable)
	void SpawnPulseAttack()
	{
		FVector TargetLoc = Game::Mio.ActorCenterLocation;
		TargetLoc.Z = MidPoint.ActorLocation.Z + 60.0;
		TargetLoc += Game::Mio.ActorHorizontalVelocity.GetSafeNormal() * 750.0;

		FVector DirToTargetLoc = (TargetLoc - PulseSpawnRoot.WorldLocation).GetSafeNormal();

		APrisonBossBrainEyePulseAttack PulseAttack = SpawnActor(PulseAttackClass, PulseSpawnRoot.WorldLocation, DirToTargetLoc.Rotation());
		ActivePulseAttacks.Add(PulseAttack);

		PulseAttack.OnAttackDestroyed.AddUFunction(this, n"PulseAttackDestroyed");
		
		PulsesSpawned++;
		if (PulsesSpawned >= PrisonBoss::PulsesAttacksPerWave)
		{
			PulseAttackTimerHandle.ClearTimer();
			PulseAttackWaveTimerHandle = Timer::SetTimer(this, n"SpawnPulseWave", PrisonBoss::PulseAttackWaveInterval, false);
		}
	}

	UFUNCTION()
	private void PulseAttackDestroyed(APrisonBossBrainEyePulseAttack Attack)
	{
		ActivePulseAttacks.Remove(Attack);
	}

	UFUNCTION()
	void DestroyActivePulseAttacks()
	{
		TArray<APrisonBossBrainEyePulseAttack> PulseAttacks = ActivePulseAttacks;
		int NumActiveAttacks = PulseAttacks.Num();
		for (int i = 0; i <= NumActiveAttacks - 1; i++)
		{
			PulseAttacks[i].Destroy();
		}
	}

	UFUNCTION()
	void SetTrackPlayerStatus(bool bTrack)
	{
		bTrackPlayer = bTrack;
	}

	UFUNCTION()
	void SetWeakened(bool bSnap = false)
	{
		bWeakened = true;
		if (bSnap)
		{
			SetActorLocationAndRotation(WeakenedLocation.ActorLocation, WeakenedLocation.ActorRotation);
			bInWeakenedPosition = true;
		}

		UPrisonBossBrainEyeEffectEventHandler::Trigger_Weakened(this);
	}

	UFUNCTION()
	void SetUnweakened()
	{
		bWeakened = false;
		bInWeakenedPosition = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bWeakened)
		{
			if (!bInWeakenedPosition)
			{
				FTransform Transform = FTransform(WeakenedLocation.ActorRotation, WeakenedLocation.ActorLocation);
				FVector Loc = Math::VInterpTo(ActorLocation, Transform.Location, DeltaTime, 1.0);
				FRotator Rot = Math::RInterpTo(ActorRotation, Transform.Rotator(), DeltaTime, 1.0);
				SetActorLocationAndRotation(Loc, Rot);

				if (Loc.Equals(WeakenedLocation.ActorLocation, 10.0) && Rot.Equals(WeakenedLocation.ActorRotation, 1.0))
					bInWeakenedPosition = true;
			}

			return;
		}

		if (bReturningToSocket)
		{
			/*FVector Loc = Math::VInterpTo(ActorLocation, SocketTransform.Location, DeltaTime, 2.0);
			FRotator Rot = Math::RInterpTo(ActorRotation, SocketTransform.Rotator(), DeltaTime, 2.0);
			SetActorLocationAndRotation(Loc, Rot);
			if (Loc.Equals(SocketTransform.Location, 10.0))
				UPrisonBossBrainEyeEffectEventHandler::Trigger_ReturnedToSocket(this);*/

			return;
		}

		if (bEyeRippedOut)
		{
			AccTrackPlayerSpeed.AccelerateTo(1.0, 2.0, DeltaTime);

			float SplineDist = SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation);
			SplineDist += SplineOffset;
			SplineDist = Math::Clamp(SplineDist, MinSplineDist, MaxSplineDist);

			FVector Loc = SplineComp.GetWorldLocationAtSplineDistance(SplineDist);
			Loc.Z += 400.0;
			Loc = Math::VInterpTo(ActorLocation, Loc, DeltaTime, AccTrackPlayerSpeed.Value * 1.0);
			SetActorLocation(Loc);

			FVector Dir = (Game::Mio.ActorCenterLocation - ActorLocation).GetSafeNormal();

			FRotator Rot = Math::RInterpTo(ActorRotation, Dir.Rotation(), DeltaTime, AccTrackPlayerSpeed.Value * 4.0);
			SetActorRotation(Rot);

			if (bTwitching)
			{
				TwitchStartTime += DeltaTime;
				FRotator TargetRotation = FRotator::ZeroRotator;
				TargetRotation.Yaw += Math::Sin(TwitchStartTime * 20.0) * 1.0;
				TargetRotation.Pitch += Math::Sin(TwitchStartTime * 15.0) * 1.2;
				GlobeRoot.SetRelativeRotation(TargetRotation);
			}
			else if (bTrackPlayer)
			{
				FVector DirToPlayer = ((Game::Mio.ActorCenterLocation + (FVector::UpVector * 250.0)) - GlobeRoot.WorldLocation).GetSafeNormal();

				FRotator TargetRot = DirToPlayer.Rotation();
				FRotator GlobeRot = Math::RInterpTo(GlobeRoot.WorldRotation, TargetRot, DeltaTime, 4.0);
				GlobeRoot.SetWorldRotation(GlobeRot);
			}
		}
	}

	UFUNCTION()
	void ReturnToSocket()
	{
		bReturningToSocket = true;
		bWeakened = false;

		ReturnToSocketStartLoc = ActorLocation;
		ReturnToSocketStartRot = ActorRotation;
		ReturnToSocketTimeLike.PlayFromStart();

		UPrisonBossBrainEyeEffectEventHandler::Trigger_StartReturnToSocket(this);
	}

	UFUNCTION()
	private void UpdateReturnToSocket(float CurValue)
	{
		FVector Loc = Math::Lerp(ReturnToSocketStartLoc, SocketTransform.Location, CurValue);
		Loc.Z += Math::Lerp(0.0, 600.0, ReturnToSocketVerticalCurve.GetFloatValue(CurValue));
		FRotator Rot = Math::LerpShortestPath(ReturnToSocketStartRot, SocketTransform.Rotator(), ReturnToSocketRotationCurve.GetFloatValue(CurValue));
		SetActorLocationAndRotation(Loc, Rot);
	}

	UFUNCTION()
	private void FinishReturnToSocket()
	{
		UPrisonBossBrainEyeEffectEventHandler::Trigger_ReturnedToSocket(this);
	}

	UFUNCTION()
	void DetachFromSocket()
	{
		bReturningToSocket = false;
		UPrisonBossBrainEyeEffectEventHandler::Trigger_DetachFromSocket(this);
	}

	UFUNCTION()
	void UpdateSplineOffset(float NewOffset)
	{
		SplineOffset = NewOffset;
	}

	UFUNCTION()
	void MagnetizeEye()
	{
		SetTwitchingEnabled(true);
		DestroyActivePulseAttacks();
		BP_MagnetizeEye();

		UPrisonBossBrainEyeEffectEventHandler::Trigger_Magnetized(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_MagnetizeEye() {}

	UFUNCTION()
	void DemagnetizeEye()
	{
		SetTwitchingEnabled(false);
		BP_DemagnetizeEye();

		UPrisonBossBrainEyeEffectEventHandler::Trigger_Demagnetized(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DemagnetizeEye() {}

	UFUNCTION()
	void SetTwitchingEnabled(bool bEnabled)
	{
		TwitchStartTime = 0.0;
		bTwitching = bEnabled;
	}
}