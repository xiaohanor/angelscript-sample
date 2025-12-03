UCLASS(Abstract)
class AMaxSecurityBackdropLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaserRoot;

	UPROPERTY(DefaultComponent, Attach = LaserRoot)
	UNiagaraComponent LaserEffectComp;

	UPROPERTY(EditAnywhere)
	bool bRotate = false;

	UPROPERTY(EditAnywhere)
	float MaxRot = 60.0;

	UPROPERTY(EditAnywhere)
	float RotateDelay = 2.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike RotateTimeLike;

	UPROPERTY(EditAnywhere)
	float MaxLength = 3200.0;
	float LaserLength = 0.0;

	UPROPERTY(EditAnywhere)
	float LaserWidth = 25.0;

	UPROPERTY(EditAnywhere)
	float ExtendSpeed = 3000.0;

	bool bExtending = true;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		LaserEffectComp.SetVectorParameter(n"BeamEnd", FVector(MaxLength, 0.0, 0.0));
		LaserEffectComp.SetFloatParameter(n"BeamWidth", LaserWidth);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserEffectComp.SetVectorParameter(n"BeamEnd", FVector::ZeroVector);
		LaserEffectComp.DeactivateImmediately();

		RotateTimeLike.BindUpdate(this, n"UpdateRotate");
	}

	UFUNCTION(NotBlueprintCallable)
	private void UpdateRotate(float CurValue)
	{
		float Rot = Math::Lerp(0.0, MaxRot, CurValue);
		LaserRoot.SetRelativeRotation(FRotator(Rot, 0.0, 0.0));
	}

	UFUNCTION()
	void Extend()
	{
		bExtending = true;
		SetActorTickEnabled(true);
		LaserEffectComp.Activate(true);

		if (bRotate)
			Timer::SetTimer(this, n"StartRotating", RotateDelay);
	}

	UFUNCTION()
	void SnapExtend(float RotDelay)
	{
		bExtending = true;
		LaserLength = MaxLength;
		SetActorTickEnabled(true);
		LaserEffectComp.Activate(true);

		if (bRotate)
		{
			if (RotDelay == 0.0)
				StartRotating();
			else
				Timer::SetTimer(this, n"StartRotating", RotDelay);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void StartRotating()
	{
		RotateTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void Retract()
	{
		bExtending = false;
		SetActorTickEnabled(true);
	}

	FVector GetClosestPointOnLine(const FVector Position)
	{
		if (Math::IsNearlyZero(LaserLength))
			return LaserRoot.WorldLocation;

		return Math::ClosestPointOnLine(LaserRoot.WorldLocation, LaserRoot.WorldLocation + LaserRoot.ForwardVector * LaserLength, Position);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		int ExtendDir = bExtending ? 1 : -1;

		LaserLength = Math::Clamp(LaserLength + (ExtendSpeed * ExtendDir * DeltaTime), 0.0, MaxLength);
		LaserEffectComp.SetVectorParameter(n"BeamEnd", FVector(LaserLength, 0.0, 0.0));

		if((LaserLength < KINDA_SMALL_NUMBER && !bExtending) || (bExtending && LaserLength > MaxLength - KINDA_SMALL_NUMBER))
		{
			SetActorTickEnabled(false);
		}
	}
}

UCLASS(Abstract)
class AMaxSecurityBackdropLaserCenter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaserRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMaxSecurityBackdropLaser> LaserClass;

	int LaserAmount = 18;
	float LaserLength = 3450.0;

	float RotSpeed = 0.0;

	bool bSpinning = false;

	TArray<AMaxSecurityBackdropLaser> LasersToReveal;

	FTimerHandle RevealLaserTimerHandle;

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<ASpotSound> SpotSoundActor;	

	UFUNCTION(CallInEditor)
	void CreateLasers()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			AMaxSecurityBackdropLaser Laser = Cast<AMaxSecurityBackdropLaser>(Actor);
			if (Laser != nullptr)
				Actor.DestroyActor();
		}

		for (int i = 0; i <= LaserAmount + 1; i++)
		{
			AMaxSecurityBackdropLaser Laser = SpawnActor(LaserClass, ActorLocation, FRotator(0.0, ActorRotation.Yaw + (i * LaserAmount), 0.0));
			Laser.AttachToComponent(LaserRoot, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			Laser.SetActorLocation(Laser.ActorLocation + (Laser.ActorForwardVector * 1365.0) - (FVector::UpVector * 850.0));
			Laser.LaserEffectComp.SetVectorParameter(n"BeamEnd", FVector(3275, 0.0, 0.0));
			Laser.LaserEffectComp.SetFloatParameter(n"BeamWidth", 25.0);
			Laser.LaserRoot.SetRelativeRotation(FRotator(-72.6, 0.0, 0.0));
			Laser.MaxLength = LaserLength;
		}
	}

	UFUNCTION(DevFunction)
	void RevealLasers()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			AMaxSecurityBackdropLaser Laser = Cast<AMaxSecurityBackdropLaser>(Actor);
			if (Laser != nullptr)
				LasersToReveal.Add(Laser);
		}

		StartSpinning();
		RevealLaserTimerHandle = Timer::SetTimer(this, n"RevealLaser", 0.1, true);

		ASpotSound SpotSound = SpotSoundActor.Get();
		if(SpotSound != nullptr)
		{
			auto SpotSoundComp = Cast<USpotSoundComponent>(SpotSound.SpotSoundComponent);
			SpotSoundComp.Start();

			// SoundDef lives on SpotSound-actor
			UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_LasersRevealing(SpotSound);
		}

		UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_LasersRevealing(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void RevealLaser()
	{
		LasersToReveal[0].Extend();
		LasersToReveal.RemoveAt(0);

		if (LasersToReveal.Num() == 0)
			RevealLaserTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION()
	void SnapRevealLasers()
	{
		// If it's already spinning, early out.
		if (bSpinning)
			return;

		bSpinning = true;
		RotSpeed = 25.0;

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			AMaxSecurityBackdropLaser Laser = Cast<AMaxSecurityBackdropLaser>(Actor);
			if (Laser != nullptr)
				Laser.SnapExtend(0.0);
		}

		ASpotSound SpotSound = SpotSoundActor.Get();
		if (SpotSound != nullptr)
		{
			UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_StartSpinning(SpotSound);
			UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_LasersRevealing(SpotSound);
		}

		UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_StartSpinning(this);
		UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_LasersRevealing(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void StartSpinning()
	{
		bSpinning = true;

		ASpotSound SpotSound = SpotSoundActor.Get();
		if(SpotSound != nullptr)
		{
			UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_StartSpinning(SpotSound);
		}

		UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_StartSpinning(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bSpinning)
			return;

		RotSpeed = Math::Clamp(RotSpeed + (10.0 * DeltaTime), 0.0, 25.0);
		AddActorWorldRotation(FRotator(0.0, RotSpeed * DeltaTime, 0.0));
	}

	UFUNCTION()
	void RetractLasers()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor :  AttachedActors)
		{
			AMaxSecurityBackdropLaser Laser = Cast<AMaxSecurityBackdropLaser>(Actor);
			if (Laser != nullptr)
				Laser.Retract();
		}

		ASpotSound SpotSound = SpotSoundActor.Get();
		if(SpotSound != nullptr)
		{
			UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_LasersRetracting(SpotSound);
		}

		UMaxSecurityBackDropLaserCenterEffectEventHandler::Trigger_LasersRetracting(this);
	}

	UFUNCTION()
	void DisableLasers()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor :  AttachedActors)
		{
			AMaxSecurityBackdropLaser Laser = Cast<AMaxSecurityBackdropLaser>(Actor);
			if (Laser != nullptr)
				Laser.AddActorDisable(this);
		}
	}

	UFUNCTION()
	void StopRotating()
	{
		SetActorTickEnabled(false);
	}
}