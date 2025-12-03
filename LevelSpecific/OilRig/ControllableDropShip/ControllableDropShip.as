event void FControllableDropShipEvent();

class AControllableDropShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DropShipRoot;

	UPROPERTY(DefaultComponent, Attach = DropShipRoot)
	UHazeSkeletalMeshComponentBase ShipSkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = DropShipRoot)
	USceneComponent PilotAttachmentComp;

	UPROPERTY(DefaultComponent, Attach = ShipSkelMeshComp, AttachSocket = "TurretBase")
	USceneComponent TurretBase;

	UPROPERTY(DefaultComponent, Attach = ShipSkelMeshComp, AttachSocket = "LeftThruster")
	USceneComponent LeftTrusterRoot;

	UPROPERTY(DefaultComponent, Attach = ShipSkelMeshComp, AttachSocket = "RightThruster")
	USceneComponent RightThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = DropShipRoot)
	USceneComponent SteerTutorialAttachComp;

	UPROPERTY(DefaultComponent)
	UControllableDropShipShotResponseComponent ShotResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY()
	FControllableDropShipEvent OnEnemyDestroyed;

	UPROPERTY()
	FControllableDropShipEvent OnHeroesDamaged;

	UPROPERTY()
	FControllableDropShipEvent OnEnemyIncoming;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedShipPosition;
	default SyncedShipPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;
	default SyncedShipPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedShipPitch;
	default SyncedShipPitch.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedTurretRotation;
	default SyncedTurretRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"ControllableDropShipFollowPlayersCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"ControllableDropShipShootAtSplineCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"ControllableDropShipShootHaphazardlyCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"ControllableDropShipPlayerFlyCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"ControllableDropShipPlayerTurretCapability");

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent VelocityTrackerComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UControllableDropShipDrawComponent DrawComp;
#endif

	UPROPERTY()
	FControllableDropShipEvent OnShootSplineFinished;

	UPROPERTY()
	FControllableDropShipEvent OnCrash;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> PilotPassiveCamShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> PassengerPassiveCamShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ShootCamShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AControllableDropShipEnemyShip> EnemyShipClass;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset PilotCamSettings;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect VeerForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ShootForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect CrashForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureHijackGunner GunnerFeature;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> ShootPlayerDamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> ShootPlayerDeathEffect;

	bool bFlying = false;

	FVector2D PilotInput;

	FVector2D PassengerInput;
	float TurretYaw = 0.0;
	float TurretPitch = 0.0;
	float CurrentTurretPitchClamp = -30.0;
	bool bTighteningTurretClamp = false;

	bool bShootingAtPlayers = false;
	bool bShootLeft = false;

	UPROPERTY(EditInstanceOnly)
	ASplineActor ShootAtPlayersSpline;
	UHazeSplineComponent ShootAtPlayersSplineComp;

	UPROPERTY(EditDefaultsOnly)
	UPlayerHealthSettings PlayerHealthSettings;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FlyFollowSpline;

	UPROPERTY(BlueprintReadOnly)
	bool bTurretControlledByPlayer = false;

	UPlayerAimingComponent PassengerAimComp;

	bool bCanDieFromDamage = true;
	int MaxHealth = 200;
	int CurrentDamageTaken = 0;

	FTimerHandle SpawnEnemyShipTimerHandle;
	TArray<AControllableDropShipEnemyShip> EnemyShips;
	int EnemyShipIdentifier = 0;
	
	int EnemySpawnOffsetIndex = 0;
	TArray<float> EnemyShipSpawnVerticalOffsets;
	default EnemyShipSpawnVerticalOffsets.Add(1700.0);
	default EnemyShipSpawnVerticalOffsets.Add(2800.0);
	default EnemyShipSpawnVerticalOffsets.Add(4000.0);
	default EnemyShipSpawnVerticalOffsets.Add(2400.0);
	default EnemyShipSpawnVerticalOffsets.Add(1500.0);
	default EnemyShipSpawnVerticalOffsets.Add(3200.0);

	TArray<float> EnemyShipSpawnAngleOffsets;
	default EnemyShipSpawnAngleOffsets.Add(5.0);
	default EnemyShipSpawnAngleOffsets.Add(-30.0);
	default EnemyShipSpawnAngleOffsets.Add(30.0);
	default EnemyShipSpawnAngleOffsets.Add(-40.0);
	default EnemyShipSpawnAngleOffsets.Add(20.0);
	default EnemyShipSpawnAngleOffsets.Add(-12.0);

	TArray<float> EnemyShipDodgeVerticalOffsets;
	default EnemyShipDodgeVerticalOffsets.Add(4000.0);
	default EnemyShipDodgeVerticalOffsets.Add(1500.0);
	default EnemyShipDodgeVerticalOffsets.Add(1600.0);
	default EnemyShipDodgeVerticalOffsets.Add(2800.0);
	default EnemyShipDodgeVerticalOffsets.Add(4000.0);
	default EnemyShipDodgeVerticalOffsets.Add(1600.0);

	TArray<float> EnemyShipDodgeAngleOffsets;
	default EnemyShipDodgeAngleOffsets.Add(-12.0);
	default EnemyShipDodgeAngleOffsets.Add(5.0);
	default EnemyShipDodgeAngleOffsets.Add(-20.0);
	default EnemyShipDodgeAngleOffsets.Add(10.0);
	default EnemyShipDodgeAngleOffsets.Add(10.0);
	default EnemyShipDodgeAngleOffsets.Add(8.0);

	bool bCrashed = false;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike VeerTimeLike;
	FTimerHandle VeerTimerHandle;
	bool bVeering = false;
	bool bVeeringLeft = false;
	float VeerStartYaw;
	float VeerEndYaw;

	float CurrentYaw = 0.0;
	float OriginalYaw;

	float CurrentRoll = 0.0;

	bool bSnapActivated = false;

	bool bShootingHaphazardly = false;
	ASplineActor ShootSpline;

	bool bFollowingPlayers = false;

	UPROPERTY(EditAnywhere, Category = "Audio")
	float MaxPassbyDistance = 1000;
	private float MaxPassbyDistanceSqrd = 0;

	UPROPERTY(BlueprintReadOnly)
	AControllableDropShipTurret Turret;
	bool bTurretShooting = false;

	FVector2D FlyValues;
	bool bHovering = false;

	UPROPERTY(EditAnywhere)
	FOilRigDropShipHoverValues HoverValues;

	FVector2D CurrentSplineOffset = FVector2D::ZeroVector;

	UFUNCTION(BlueprintEvent)
	void BP_ActivatePassenger() {}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			Turret = Cast<AControllableDropShipTurret>(Actor);
			if (Turret != nullptr)
				break;
		}

		if (ShootAtPlayersSpline != nullptr)
			ShootAtPlayersSplineComp = ShootAtPlayersSpline.Spline;

		SetActorControlSide(Game::Mio);
		SyncedShipPosition.OverrideControlSide(Game::Mio);
		SyncedShipPitch.OverrideControlSide(Game::Mio);
		SyncedTurretRotation.OverrideControlSide(Game::Zoe);

		PassengerAimComp = UPlayerAimingComponent::Get(Game::Zoe);

		ShotResponseComp.OnHit.AddUFunction(this, n"ShotAt");

		VeerTimeLike.BindUpdate(this, n"UpdateVeer");
		VeerTimeLike.BindFinished(this, n"FinishVeer");

		MaxPassbyDistanceSqrd = Math::Square(MaxPassbyDistance);
	}

	UFUNCTION(DevFunction)
	void DisableDeathByDamage()
	{
		bCanDieFromDamage = false;
	}

	UFUNCTION()
	private void ShotAt()
	{
		if (Game::Mio.GetGodMode() == EGodMode::God)
			return;

		if (!bCanDieFromDamage)
			return;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			// Player.DamagePlayerHealth(1.0/MaxHealth);
		}

		CurrentDamageTaken++;
		if (CurrentDamageTaken >= MaxHealth)
		{
			if (HasControl())
				CrumbCrash();
		}
		if (CurrentDamageTaken > (3.0 * MaxHealth)/4.0)
		{
			OnHeroesDamaged.Broadcast();
		}
	}

	UFUNCTION()
	void ResetShotsTaken()
	{
		CurrentDamageTaken = 0;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			// Player.HealPlayerHealth(1.0);
		}
	}

	UFUNCTION()
	void StartFollowingPlayers()
	{
		bFollowingPlayers = true;
	}

	UFUNCTION()
	void StopFollowingPlayers()
	{
		bFollowingPlayers = false;
	}

	UFUNCTION(DevFunction)
	void StartShootingAtPlayers()
	{
		bShootingAtPlayers = true;
	}

	UFUNCTION()
	void StopShootingAtPlayers()
	{
		bShootingAtPlayers = false;
	}

	void SetHapzardShootingAllowed(bool bAllowed)
	{
		bShootingHaphazardly = bAllowed;
	}

	UFUNCTION()
	void StartShootingHaphazardly()
	{
		StartShootingAtPlayers();
		BP_StartShootingHaphazardly();
	}

	UFUNCTION()
	void StopShootingHapzardly()
	{
		bShootingHaphazardly = false;
		BP_StopShootingHaphazardly();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartShootingHaphazardly() {}

	UFUNCTION(BlueprintEvent)
	void BP_StopShootingHaphazardly() {}

	UFUNCTION(NotBlueprintCallable)
	void ShootAtPlayers()
	{
		FVector TurretLoc = Turret.SkelMeshComp.GetSocketLocation(n"TurretGunBase");
		FVector TurretDir = Turret.SkelMeshComp.GetSocketRotation(n"TurretGunBase").ForwardVector;
		Shoot(TurretLoc + (TurretDir * 20000.0), bLocal = true);
	}

	void Shoot(FVector TargetLoc, bool bLocal = false)
	{
		UArrowComponent MuzzleComp = !bShootLeft ? Turret.LeftMuzzleComp : Turret.RightMuzzleComp;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(this);
		Trace.UseLine();

		FHitResult Hit = Trace.QueryTraceSingle(MuzzleComp.WorldLocation, TargetLoc);
		UControllableDropShipShotResponseComponent ResponseComp;
		
		FVector EndLocation = TargetLoc;
		if (Hit.bBlockingHit)
		{
			ResponseComp = UControllableDropShipShotResponseComponent::Get(Hit.Actor);
			EndLocation = Hit.ImpactPoint;

			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if (Player != nullptr)
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(Hit.ImpactPoint + (Hit.ImpactNormal * 20.0), 5.0), ShootPlayerDamageEffect, ShootPlayerDeathEffect);
		}

		bool bHit = Hit.bBlockingHit;
		if (bLocal)
		{
			SpawnShootEffects(bHit, EndLocation, Hit.ImpactNormal);
			if (HasControl() && IsValid(ResponseComp))
				NetTriggerHitResponse(ResponseComp);
		}
		else
		{
			NetShoot(bHit, ResponseComp, EndLocation, Hit.ImpactNormal);
		}

		for(auto Player : Game::GetPlayers())
		{
			FVector ProjectedPassbyLocation = Math::ClosestPointOnLine(MuzzleComp.WorldLocation, TargetLoc, Player.ActorLocation);
			const float PassbyDistSqrd = ProjectedPassbyLocation.DistSquared(Player.ActorLocation);
			if(PassbyDistSqrd <= MaxPassbyDistanceSqrd)
			{
				const FVector ShotDir = (TargetLoc - MuzzleComp.WorldLocation).GetSafeNormal();
				const FVector PlayerCameraForward = Player.ControlRotation.ForwardVector;
				const float NormalizedDirectionValue = PlayerCameraForward.DotProduct(ShotDir) * -1;

				FWeaponProjectileFlybyHitScanParams Params;
				Params.TargetPlayer = Player;
				Params.Distance = ProjectedPassbyLocation.Distance(Player.ActorLocation) / MaxPassbyDistance;
				Params.NormalizedDirection = NormalizedDirectionValue;

				UHitscanProjectileEffectEventHandler::Trigger_HitscanProjectilePassby(this, Params);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetShoot(bool bHit, UControllableDropShipShotResponseComponent ResponseComp, FVector ImpactPoint, FVector ImpactNormal)
	{
		SpawnShootEffects(bHit, ImpactPoint, ImpactNormal);

		if (ResponseComp != nullptr)
		{
			UControllableDropShipCrosshair Crosshair = Cast<UControllableDropShipCrosshair>(PassengerAimComp.GetCrosshairWidget(this));
			if (Crosshair != nullptr)
				Crosshair.Hit();
			TriggerHitResponse(ResponseComp);
		}
	}

	private void SpawnShootEffects(bool bHit, FVector ImpactPoint, FVector ImpactNormal)
	{
		bShootLeft = !bShootLeft;

		UArrowComponent MuzzleComp = bShootLeft ? Turret.LeftMuzzleComp : Turret.RightMuzzleComp;

		if (bHit)
		{
			FControllableDropShipShotImpactParams ShotImpactParams;
			ShotImpactParams.ImpactLocation = ImpactPoint;
			ShotImpactParams.ImpactNormal = ImpactNormal;
			UControllableDropShipEffectEventHandler::Trigger_ShotImpact(this, ShotImpactParams);

			FControllableDropShipProjectileImpactParams AudioProjectileImpactParams;
			AudioProjectileImpactParams.ImpactLocation = ImpactPoint;

			FHazeTraceSettings TraceParams;
			TraceParams.TraceWithChannel(ECollisionChannel::AudioTrace);

			auto PhysMat = AudioTrace::GetPhysMaterialFromLocation(ImpactPoint, ImpactNormal, TraceParams);
			if(PhysMat != nullptr)
				AudioProjectileImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);

			//PrintToScreenScaled(""+Params.AudioPhysMat.GetName());
			UControllableDropShipProjectileEffectEventHandler::Trigger_ShotImpact(this, AudioProjectileImpactParams);
			
		}

		FControllabeDropShipShootParams Params;
		Params.MuzzleComp = MuzzleComp;
		Params.EndLocation = ImpactPoint;
		UControllableDropShipEffectEventHandler::Trigger_ShotFired(this, Params);
	}

	UFUNCTION(NetFunction)
	private void NetTriggerHitResponse(UControllableDropShipShotResponseComponent ResponseComp)
	{
		TriggerHitResponse(ResponseComp);
	}

	private void TriggerHitResponse(UControllableDropShipShotResponseComponent ResponseComp)
	{
		if (IsValid(ResponseComp))
			ResponseComp.Hit();
	}

	UFUNCTION()
	void ActivatePilot()
	{
		UControllableDropShipPlayerComponent DropShipComp = UControllableDropShipPlayerComponent::Get(Game::Mio);
		DropShipComp.CurrentDropShip = this;
	}

	UFUNCTION()
	void ActivatePassenger()
	{
		UControllableDropShipPlayerComponent DropShipComp = UControllableDropShipPlayerComponent::Get(Game::Zoe);
		DropShipComp.CurrentDropShip = this;
		bTurretControlledByPlayer = true;

		StopShootingAtPlayers();

		PassengerAimComp = UPlayerAimingComponent::Get(Game::Zoe);

		BP_ActivatePassenger();
	}

	UFUNCTION()
	void ActivateBothPlayers(bool bSnap = false)
	{
		bSnapActivated = bSnap;

		ActivatePilot();
		ActivatePassenger();
	}

	UFUNCTION()
	void StartFlying(bool bTurnAround = true)
	{
		CurrentYaw = ActorRotation.Yaw;

		Game::Zoe.PlayCameraShake(PassengerPassiveCamShake, this);

		BP_StartFlying(bTurnAround);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ApplySettings(PlayerHealthSettings, this);
			Player.BlockCapabilities(n"Death", this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartFlying(bool bTurnAround) {}

	UFUNCTION()
	void SetFlyingStarted()
	{
		bFlying = true;
	}

	UFUNCTION()
	void StopFlying()
	{
		bFlying = false;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION()
	void SetOriginalYaw()
	{
		OriginalYaw = ActorRotation.Yaw;
		CurrentYaw = OriginalYaw;
	}

	UFUNCTION()
	void ShootAtSpline(ASplineActor Spline)
	{
		StopShootingHapzardly();
		ShootSpline = Spline;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector LocalTranslation = ActorTransform.TransformVector(VelocityTrackerComp.GetLastFrameDeltaTranslation());
		FVector2D Local2D = FVector2D(LocalTranslation.Y, LocalTranslation.X);
		FlyValues.X = Math::GetMappedRangeValueClamped(FVector2D(-20.0, 20.0), FVector2D(-1.0, 1.0), Local2D.X);
		FlyValues.Y = Math::GetMappedRangeValueClamped(FVector2D(-20.0, 20.0), FVector2D(-1.0, 1.0), -Local2D.Y);

		bHovering = !bFlying;

		float Time = Time::GameTimeSeconds;
		float Roll = Math::DegreesToRadians(Math::Sin(Time * HoverValues.HoverRollSpeed) * HoverValues.HoverRollRange);
		float Pitch = Math::DegreesToRadians(Math::Cos(Time * HoverValues.HoverPitchSpeed) * HoverValues.HoverPitchRange);
		FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

		DropShipRoot.SetRelativeRotation(Rotation);

		float XOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.X) * HoverValues.HoverOffsetRange.X;
		float YOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Y) * HoverValues.HoverOffsetRange.Y;
		float ZOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Z) * HoverValues.HoverOffsetRange.Z;

		FVector Offset = (FVector(XOffset, YOffset, ZOffset));

		DropShipRoot.SetRelativeLocation(Offset);
	}

	UFUNCTION()
	void SetVeeringEnabled(bool bEnabled)
	{
		if (!HasControl())
			return;

		bVeering = bEnabled;

		if (bVeering)
			VeerTimerHandle = Timer::SetTimer(this, n"TriggerRandomVeer", Math::RandRange(4.0, 6.0));
		else
			VeerTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION()
	private void TriggerRandomVeer()
	{
		if (!HasControl())
			return;

		bVeeringLeft = Math::RandBool();
		CrumbTriggerVeer(bVeeringLeft);
	}

	UFUNCTION()
	void TriggerForcedVeer(bool bLeft)
	{
		if (!HasControl())
			return;

		bVeeringLeft = bLeft;
		CrumbTriggerVeer(bVeeringLeft);
	}
	
	UFUNCTION(CrumbFunction)
	private void CrumbTriggerVeer(bool bLeft)
	{
		BP_Veer(bVeeringLeft);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayForceFeedback(VeerForceFeedback, false, true, this);

		if (HasControl())
		{
			bVeeringLeft = bLeft;
			VeerStartYaw = ActorRotation.Yaw;
			VeerEndYaw = bVeeringLeft ? VeerStartYaw + 20.0 : VeerStartYaw - 20.0;
			VeerEndYaw = Math::Clamp(VeerEndYaw, OriginalYaw - ControllableDropShip::FlyingMaxYaw, OriginalYaw + ControllableDropShip::FlyingMaxYaw);
			VeerTimeLike.PlayFromStart();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Veer(bool bLeft) {}
	
	UFUNCTION()
	private void UpdateVeer(float CurValue)
	{
		float Yaw = Math::Lerp(VeerStartYaw, VeerEndYaw, CurValue);
		SetActorRotation(FRotator(0.0, Yaw, 0.0));
		CurrentYaw = Yaw;
	}

	UFUNCTION()
	private void FinishVeer()
	{
		if (bVeering)
			VeerTimerHandle = Timer::SetTimer(this, n"TriggerRandomVeer", Math::RandRange(2.0, 4.0));
	}

	UFUNCTION(CrumbFunction)
	void CrumbCrash()
	{
		if (bCrashed)
			return;

		bCrashed = true;
		BP_Crash();
		OnCrash.Broadcast();

		StopSpawningEnemyShips();

		TArray<AControllableDropShipEnemyShip> Ships = EnemyShips;
		for (AControllableDropShipEnemyShip Ship : Ships)
		{
			Ship.StopShootingAtPlayers();
		}

		AddActorDisable(this);
		Turret.AddActorDisable(this);
		
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayForceFeedback(CrashForceFeedback, false, true, this, 2.0);
			Player.BlockCapabilities(CapabilityTags::Visibility, this);
			Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		}
		
		PlayerHealth::TriggerGameOver();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Crash() {}

	UFUNCTION()
	void StartSpawningEnemyShips()
	{
		if (Game::Zoe.HasControl())
		{
			SpawnEnemyShip();
			SpawnEnemyShipTimerHandle = Timer::SetTimer(this, n"SpawnEnemyShip", ControllableDropShip::EnemySpawnRate, true);
		}
	}

	UFUNCTION()
	private void SpawnEnemyShip()
	{
		CrumbSpawnEnemyShip();

		OnEnemyIncoming.Broadcast(); //for VO
	}

	UFUNCTION()
	void SnapTurretClamp()
	{
		CurrentTurretPitchClamp = ControllableDropShip::TurretMinPitch;
	}

	UFUNCTION()
	void TightenTurretClamp()
	{
		bTighteningTurretClamp = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnEnemyShip()
	{
		float SpawnOffset = EnemyShipSpawnVerticalOffsets[EnemySpawnOffsetIndex];
		float SpawnAngle = EnemyShipSpawnAngleOffsets[EnemySpawnOffsetIndex];

		FVector SpawnLoc = Game::Mio.ActorLocation;
		FVector SpawnDir = -Game::Mio.ActorForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		SpawnDir = SpawnDir.RotateAngleAxis(SpawnAngle, FVector::UpVector);
		SpawnLoc += SpawnDir * ControllableDropShip::EnemyDistance;
		float VertOffset = ControllableDropShip::EnemySpawnVerticalOffset;
		if (SpawnLoc.Y > 0)
			VertOffset = -ControllableDropShip::EnemySpawnVerticalOffset;
		SpawnLoc += FVector::UpVector * VertOffset;
		AControllableDropShipEnemyShip EnemyShip = SpawnActor(EnemyShipClass, SpawnLoc, bDeferredSpawn = true);
		EnemyShipIdentifier++;
		EnemyShip.MakeNetworked(this, EnemyShipIdentifier);
		FinishSpawningActor(EnemyShip);

		EnemyShip.Spawn(SpawnOffset, SpawnAngle, EnemyShipDodgeVerticalOffsets[EnemySpawnOffsetIndex], EnemyShipDodgeAngleOffsets[EnemySpawnOffsetIndex]);
		EnemyShip.OnShipDestroyed.AddUFunction(this, n"EnemyShipDestroyed");

		EnemyShips.Add(EnemyShip);

		if (EnemySpawnOffsetIndex >= EnemyShipSpawnVerticalOffsets.Num() - 1)
			EnemySpawnOffsetIndex = 0;
		else
			EnemySpawnOffsetIndex++;
	}

	UFUNCTION()
	private void EnemyShipDestroyed(AControllableDropShipEnemyShip Ship)
	{
		EnemyShips.Remove(Ship);
		OnEnemyDestroyed.Broadcast();
	}

	UFUNCTION()
	void StopSpawningEnemyShips()
	{
		SpawnEnemyShipTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION()
	void DestroyEnemyShips()
	{
		StopSpawningEnemyShips();

		TArray<AControllableDropShipEnemyShip> Ships = EnemyShips;
		for (AControllableDropShipEnemyShip Ship : Ships)
		{
			Ship.Destroy();
		}
	}

	UFUNCTION()
	void DisableEnemyShips()
	{
		StopSpawningEnemyShips();

		TArray<AControllableDropShipEnemyShip> Ships = EnemyShips;
		for (AControllableDropShipEnemyShip Ship : Ships)
		{
			Ship.AddActorDisable(this);
		}
	}
}