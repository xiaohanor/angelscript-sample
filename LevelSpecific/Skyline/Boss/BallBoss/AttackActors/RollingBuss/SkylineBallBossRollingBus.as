class ASkylineBallBossRollingBus : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = BusVerticalRoot)
	UDeathTriggerComponent DeathTriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BusHorizontalRoot;

	UPROPERTY(DefaultComponent, Attach = BusHorizontalRoot)
	USceneComponent BusVerticalRoot;

	UPROPERTY(DefaultComponent, Attach = BusVerticalRoot)
	USkylineBallBossTractorBeamComponent TractorBeamVFXComp1;

	UPROPERTY(DefaultComponent, Attach = BusVerticalRoot)
	USkylineBallBossTractorBeamComponent TractorBeamVFXComp2;

	UPROPERTY()
	FHazeTimeLike RevealTimeLike;
	default RevealTimeLike.UseSmoothCurveZeroToOne();
	default RevealTimeLike.Duration = 10.0;

	UPROPERTY()
	FHazeTimeLike BounceTimeLike;
	default BounceTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	float BounceHeight = 1000.0;

	UPROPERTY()
	float BounceDistance = 1000.0;

	UPROPERTY()
	FVector BusExtent;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	ASkylineBallBoss BallBoss;

	TArray<UPrimitiveComponent> PrimitiveComponents;

	bool bActive = false;
	bool bFalling = false;
	bool bRotateAligningBoss = false;
	bool bDontKillMio = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BounceTimeLike.BindUpdate(this, n"BounceTimeLikeUpdate");
		BounceTimeLike.BindFinished(this, n"BounceTimeLikeFinished");
		RevealTimeLike.BindUpdate(this, n"RevealTimeLikeUpdate");
		RevealTimeLike.BindFinished(this, n"RevealTimeLikeFinished");
		BusHorizontalRoot.SetRelativeLocation(FVector::UpVector * -5000.0);
		AddActorDisable(this);
		
		BusVerticalRoot.GetChildrenComponentsByClass(UPrimitiveComponent, true, PrimitiveComponents);
	}

	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			float DeltaX = DeltaSeconds * BounceDistance / BounceTimeLike.Duration;
			float DeltaRoll = DeltaSeconds * 90.0 / BounceTimeLike.Duration;

			BusHorizontalRoot.AddRelativeLocation(FVector::ForwardVector * DeltaX);
			BusVerticalRoot.AddRelativeRotation(FRotator(0.0, 0.0, DeltaRoll));

			if (bFalling)
				BusVerticalRoot.AddRelativeLocation(FVector::UpVector * -2000 * DeltaSeconds);
		}
	}

	UFUNCTION()
	void Activate()
	{
		Timer::ClearTimer(this, n"Deactivate");
		Deactivate();

		TryCacheBallBoss();

		RemoveActorDisable(this);
		RevealTimeLike.PlayFromStart();

		DeathTriggerComp.EnableDeathTrigger(this);

		TractorBeamVFXComp1.Start();
		TractorBeamVFXComp2.Start();

		BossStartRotateAlign();

		Timer::SetTimer(this, n"ActivateCamera", 1.0);

		USkylineBallBossMiscVOEventHandler::Trigger_BusThrow(BallBoss);

		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn2)
		{
			for (auto PrimitiveComponent : PrimitiveComponents)
			{
				PrimitiveComponent.SetRenderedForPlayer(Game::Mio, false);
			}

			if (!bDontKillMio)
			{
				DeathTriggerComp.bKillsMio = false;
				UPlayerMovementComponent::Get(Game::Mio).AddMovementIgnoresActor(this, this);
			}
			
			bDontKillMio = true;
		}
	}

	private void TryCacheBallBoss()
	{
		if (BallBoss == nullptr)
		{
			TListedActors<ASkylineBallBoss> BallBosses;
			if (BallBosses.Num() == 1)
				BallBoss = BallBosses[0];
		}
	}

	UFUNCTION()
	private void RevealTimeLikeUpdate(float CurrentValue)
	{
		BusHorizontalRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(-3000.0, 0.0, CurrentValue));
	}

	UFUNCTION()
	private void RevealTimeLikeFinished()
	{
		BounceTimeLike.PlayFromStart();

		bActive = true;

		Timer::SetTimer(this, n"TractorBeamLetGo", 0.25);

		DeathTriggerComp.DisableDeathTrigger(this);
	}

	UFUNCTION()
	private void TractorBeamLetGo()
	{
		TractorBeamVFXComp1.TractorBeamLetGo();
		TractorBeamVFXComp2.TractorBeamLetGo();
		BossStopRotateAlign();
	}

	UFUNCTION()
	void Deactivate()
	{
		AddActorDisable(this);
		bActive = false;
		bFalling = false;
		BusVerticalRoot.SetRelativeRotation(FRotator(0.0, -90.0, 0.0));
		BusVerticalRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION()
	private void ActivateCamera()
	{
		//Apply camera settings
		for (auto Player : Game::GetPlayers())
			Player.ApplyCameraSettings(CameraSettings, 6.0, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION()
	private void BounceTimeLikeUpdate(float CurrentValue)
	{
		FVector PreviousPosition = BusVerticalRoot.WorldLocation;

		float Height = Math::Lerp(0.0, BounceHeight, CurrentValue);
		BusVerticalRoot.SetRelativeLocation(FVector::UpVector * Height);

		FVector NewPosition = BusVerticalRoot.WorldLocation;

		if (BounceTimeLike.Position > 0.5)
		{
			for(auto Player : Game::Players)
			{
				if (bDontKillMio && Player == Game::Mio)
					continue;
				
				auto MoveComp = UPlayerMovementComponent::Get(Player);

				// Sweep only against the player
				FHazeTraceSettings Trace = Trace::InitAgainstComponent(Player.CapsuleComponent);
				Trace.UseBoxShape(BusExtent, BusVerticalRoot.ComponentQuat);

				FHitResult Hit = Trace.QueryTraceComponent(PreviousPosition, NewPosition);
				if(Hit.bBlockingHit)
				{
					FVector DeathDir = (Hit.ImpactPoint - ActorLocation).GetSafeNormal();
					Player.KillPlayer(FPlayerDeathDamageParams(DeathDir, 2.0), BallBoss.ObjectLargeDeathEffect);
				}
			}
		}
}

	UFUNCTION()
	private void BounceTimeLikeFinished()
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);
		Trace.IgnoreActor(this);
		FHitResult HitResult = Trace.QueryTraceSingle(BusHorizontalRoot.WorldLocation, BusHorizontalRoot.WorldLocation + FVector::UpVector * -1000.0);

		if (HitResult.bBlockingHit)
		{
			BounceTimeLike.PlayFromStart();
			BP_Landed();
		}
		else
		{
			bFalling = true;
			Timer::SetTimer(this, n"Deactivate", 4.0);

			//Clear camera settings
			for (auto Player : Game::GetPlayers())
				Player.ClearCameraSettingsByInstigator(this, 6.0);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Landed()
	{
	}

	private void BossStartRotateAlign()
	{
		if (!bRotateAligningBoss)
		{
			bRotateAligningBoss = true;
			FBallBossAlignRotationData AlignData;
			AlignData.BallLocalDirection = FVector(0.5, 0.0, -1.0);
			AlignData.OverrideTargetComp = BusVerticalRoot;
			AlignData.bContinuousUpdate = true;
			AlignData.bSnapOverTime = true;
			BallBoss.AddRotationTarget(AlignData);
		}
	}

	private void BossStopRotateAlign()
	{
		if (bRotateAligningBoss)
		{
			bRotateAligningBoss = false;
			BallBoss.RemoveRotationTarget(BusVerticalRoot);
		}
	}
};

