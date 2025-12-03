asset CoastBossBossSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UCoastBossAttackWithDronesQueueCapability);
	Capabilities.Add(UCoastBossMoveManyDronesBossCapability);
	Capabilities.Add(UCoastBossMoveDronesCapability);

	Capabilities.Add(UCoastBossAttackWithGunsQueueCapability);
	Capabilities.Add(UCoastBossMoveGunBossCapability);

	Capabilities.Add(UCoastBossQueuePowerUpsCapability);
	Capabilities.Add(UCoastBossMovePickupsCapability);
	
	Capabilities.Add(UCoastBossMoveBulletsCapability);
	Capabilities.Add(UCoastBossChangePhaseCapability);
	Capabilities.Add(UCoastBossDebugTimerCapability);

	Capabilities.Add(UCoastBossHideBossCapability);
	Capabilities.Add(UCoastBossDeathCapability);
}

enum ECoastBossState
{
	Idle,
	Shooting,
}

enum ECoastBossPhase
{
	LerpIn,
	Phase1,
	Phase2,
	Phase3,
	Phase4,
	Phase5,
	Phase6,
}

event void FCoastBossChangedPhase(ECoastBossPhase NewPhase);

class ACoastBoss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase BossMeshComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent DeathVFX;
	default DeathVFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = BossMeshComp, AttachSocket = "BottomHatchAttach")
	UWingsuitBossMineLauncher MineLauncher;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(CoastBossBossSheet);

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent AttackActionQueue;
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent PowerUpActionQueue;

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent VelocityTracker;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;
	UPROPERTY(DefaultComponent)
	UCoastBossHealthBarComponent BallBossHealthBarComp;
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedBossBP;
	default SyncedBossBP.SyncRate = EHazeCrumbSyncRate::Low;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> BossDiedCamShake;

	UPROPERTY(EditInstanceOnly)
	ECoastBossState State;

	float LerpInDuration = 10.0;

	private ECoastBossPhase Phase = ECoastBossPhase::LerpIn;
	int DronesKilledDuringPhase = 0;
	int AliveDrones = 24;
	int PhaseNumWeakpoints = 4;
	bool bStarted = false;
	bool bDead = false;
	bool bFullyDead = false;
	bool bQueuedDeath = false;
	bool bHackyMadeHealthBarAppear = false;

	float LeftGunShootVisualsStartTimeStamp = 0.0;
	float RightGunShootVisualsStartTimeStamp = 0.0;
	bool bLeftGunShotUp;
	bool bRightGunShotUp;

	bool bRemoveDrone = false;

	UPROPERTY(BlueprintReadWrite)
	FCoastBossChangedPhase OnChangedPhase;
	UPROPERTY(BlueprintReadOnly)
	float WhirlwindAlpha = 0.0;
	UPROPERTY(BlueprintReadOnly)
	float DrillSpeedAlpha = 0.0;

	float BossPitchRadians = 0.0;
	float BossRollRadians = 0.0;

	bool bExitCloud = false;
	bool bRainRecover = false;
	bool bDrilling = false;
	float ChargeAlpha = 0.0;
	FVector2D PingPongWaveDirection = FVector2D::ZeroVector;
	AHazePlayerCharacter RightMostPlayer;

	TArray<ACoastBossDroneActor> DroneActors;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossBulletBall> BulletBallClass;
	TArray<ACoastBossBulletBall> ActiveBalls;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossBulletBall> BulletAutoBallClass;
	TArray<ACoastBossBulletBall> ActiveAutoBalls;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossBulletMill> BulletMillClass;
	TArray<ACoastBossBulletMill> ActiveMills;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossBulletMine> BulletMineClass;
	TArray<ACoastBossBulletMine> ActiveMines;

	ECoastBossMovementMode GunBossMovementMode = ECoastBossMovementMode::IdleBobbing;

	UPROPERTY(EditDefaultsOnly)
	TArray<TSubclassOf<ACoastBossFormationTemplate>> BossFormations;
	TMap<ECoastBossFormation, ACoastBossFormationTemplate> Formations;
	ECoastBossFormation CurrentFormation;

	private TMap<FInstigator, FCoastBossGunRotateData> GunRotationInstigators;
	FHazeAcceleratedFloat AccCoastBossStartOffset;
	
	FVector2D ManualRelativeLocation;
	FVector2D OGBossLocation;

	ACoastBoss2DPlane CoastBossPlane2D;

	bool bSentEvent = false;
	bool bShouldDevKill = false;
	float TimeOfDevKill;
	FCoastBossAnimData AnimData;

	const FName BottomLeftMuzzleName = n"LeftLowerTurretMuzzle";
	const FName TopLeftMuzzleName = n"LeftUpperTurretMuzzle";
	const FName BottomRightMuzzleName = n"RightLowerTurretMuzzle";
	const FName TopRightMuzzleName = n"RightUpperTurretMuzzle";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		AnimData.Init(BossMeshComp);
		UBasicAIHealthBarSettings::SetHealthBarSegments(this, 6, this);
		FakeBeginPlay();

		if (State == ECoastBossState::Shooting)
		{
			if (HasDevForcedPhase())
				OnForcePhaseChanged(FName());
			CoastBossDevToggles::ForcePhase.BindOnChanged(this, n"OnForcePhaseChanged");
			CoastBossDevToggles::ForcePhase.MakeVisible();
		}

		TListedActors<ACoastBossDroneActor> Drones;
		DroneActors = Drones.GetArray();
		for (int iDrone = 0; iDrone < 24; ++iDrone)
			DroneActors[iDrone].DroneMesh.DroneID = iDrone;

		for (int iFormation = 0; iFormation < BossFormations.Num(); ++iFormation)
		{
			ACoastBossFormationTemplate Formation = SpawnActor(BossFormations[iFormation], ActorLocation, ActorRotation);
			Formation.SetActorHiddenInGame(true);
			Formations.Add(Formation.Phase, Formation);
		}

		CoastBossDevToggles::UseManyDrones.MakeVisible();

		FCoastBossGunRotateData LowestData;
		LowestData.bUseBossPitchRot = false;
		LowestData.TargetShootAngle = 0.0;
		AddRotateReqeuster(this, LowestData);
		
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
	}

	UFUNCTION(BlueprintPure)
	FVector2D GetVelocityScreenSpace()
	{
		if (CoastBossPlane2D == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			CoastBossPlane2D = Refs.Single.CoastBossPlane2D;
		}
		FVector RelativeVelocity = GetRawLastFrameTranslationVelocity() - CoastBossPlane2D.GetRawLastFrameTranslationVelocity();
		return CoastBossPlane2D.GetDirectionOnPlane(RelativeVelocity);
	}

	UFUNCTION(DevFunction)
	void DevKillCoastBoss()
	{
		bShouldDevKill = true;
		TimeOfDevKill = Time::GetGameTimeSeconds();
	}

	void AddRotateReqeuster(FInstigator Instigator, FCoastBossGunRotateData Data)
	{
		GunRotationInstigators.Add(Instigator, Data);
	}

	void RemoveRotateRequester(FInstigator Instigator)
	{
		GunRotationInstigators.Remove(Instigator);
	}

	bool IsGunAligned(float Angle) const
	{
		return Math::IsNearlyEqual(GetGunRelativeRotation().Pitch, Angle, 1.0);
	}

	FRotator GetGunRelativeRotation() const
	{
		return AnimData.GetBoneLocalTransform(n"LeftGunArm").Rotator();
	}

	FTransform GetGunWorldTransform() const
	{
		return BossMeshComp.GetBoneTransform(n"LeftGunArm");
	}

	FName GetMuzzleSocketName(bool bUp, bool bRight) const
	{
		FName SocketName;
		if(bUp && bRight)
		{
			SocketName = TopRightMuzzleName;
		}
		else if(bUp && !bRight)
		{
			SocketName = TopLeftMuzzleName;
		}
		else if(!bUp && bRight)
		{
			SocketName = BottomRightMuzzleName;
		}
		else if(!bUp && !bRight)
		{
			SocketName = BottomLeftMuzzleName;
		}

		return SocketName;
	}

	FVector GetMuzzleBulletLocation(bool bUp, bool bRight) const
	{
		FName SocketName = GetMuzzleSocketName(bUp, bRight);
		return BossMeshComp.GetSocketLocation(SocketName);
	}

	FVector GetMuzzleFlashLocation(bool bUp, bool bRight) const
	{
		FVector BulletLocation = GetMuzzleBulletLocation(bUp, bRight);
		return BulletLocation + GetGunWorldTransform().Rotation.ForwardVector * 30.0;
	}

	bool IsHealthInCurrentPhase()
	{
		if (HealthComp.CurrentHealth < KINDA_SMALL_NUMBER)
			return false;

		int PhaseByEnum = int(Phase); // 0 to 5
		if (Phase >= ECoastBossPhase::Phase1)
			PhaseByEnum -= 1; // dont count lerp phase
		float NumPhases = 6.0;
		float PhaseHealthSegment = 1.0 / NumPhases;
		float PhaseMaxHealth = 1.0 - Math::Clamp(PhaseHealthSegment * PhaseByEnum, 0.0, 1.0);
		return HealthComp.CurrentHealth > PhaseMaxHealth - PhaseHealthSegment;
	}

	bool IsHealthInLastPhase()
	{
		float NumPhases = 6.0;
		float PhaseHealthSegment = 1.0 / NumPhases;
		return HealthComp.CurrentHealth < PhaseHealthSegment;
	}

	UFUNCTION(BlueprintEvent)
	void FakeBeginPlay() {}

	UFUNCTION(BlueprintCallable)
	void LerpIn(float Duration)
	{
		RemoveActorDisable(this);
		AddActorVisualsBlock(this);
		LerpInDuration = Duration;
		GunBossMovementMode = ECoastBossMovementMode::LerpIn;

		if (CoastBossPlane2D == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			CoastBossPlane2D = Refs.Single.CoastBossPlane2D;
		}
		AccCoastBossStartOffset.SnapTo(CoastBossPlane2D.PlaneExtents.Y * 3.0);
		TListedActors<AGameSky> ListedSky;
		ListedSky.Single.SetAlternateLightingEnabledWithBlend(true, 3.0);
	}

	UFUNCTION(BlueprintCallable)
	void StartBoss()
	{
		RemoveActorDisable(this);
		bStarted = true;
		if (GetPhase() == ECoastBossPhase::LerpIn)
			SetNewPhase(ECoastBossPhase::Phase1, false);
		TListedActors<AGameSky> ListedSky;
		if(!ListedSky.Single.bBlendAlternateLightingEnabled)
			ListedSky.Single.SetAlternateLightingEnabled(true);
	}

	UFUNCTION(BlueprintCallable)
	void SetNewPhase(ECoastBossPhase NewPhase, bool bSetHealth = false)
	{
		DronesKilledDuringPhase = 0;
		AttackActionQueue.Empty();
		
		if (CoastBossPlane2D == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			CoastBossPlane2D = Refs.Single.CoastBossPlane2D;
		}

		Phase = NewPhase;
		
		if (CoastBossDevToggles::UseManyDrones.IsEnabled())
		{
			switch (NewPhase)
			{
				case ECoastBossPhase::LerpIn: { SetNewFormation(ECoastBossFormation::State24_Star, true); break;}
				case ECoastBossPhase::Phase1: { SetNewFormation(ECoastBossFormation::State24_Star, true); break;}
				case ECoastBossPhase::Phase2: { SetNewFormation(ECoastBossFormation::State20_Cross, true); break;}
				case ECoastBossPhase::Phase3: { SetNewFormation(ECoastBossFormation::State16_Sun, true); break;}
				case ECoastBossPhase::Phase4: { SetNewFormation(ECoastBossFormation::State12_Sinus, true); break;}
				case ECoastBossPhase::Phase5: { SetNewFormation(ECoastBossFormation::State8_Banana, true); break;}
				case ECoastBossPhase::Phase6: { SetNewFormation(ECoastBossFormation::State4_PingPong, true); break;}
			}
		}
		else
		{
			switch (NewPhase)
			{
				case ECoastBossPhase::LerpIn: { GunBossMovementMode = ECoastBossMovementMode::LerpIn; break;}
				case ECoastBossPhase::Phase1: { GunBossMovementMode = ECoastBossMovementMode::WaveDown; break;}
				case ECoastBossPhase::Phase2: { GunBossMovementMode = ECoastBossMovementMode::IdleBobbing; break;}
				case ECoastBossPhase::Phase3: { GunBossMovementMode = ECoastBossMovementMode::IdleBobbing; break;}
				case ECoastBossPhase::Phase4: { GunBossMovementMode = ECoastBossMovementMode::IdleBobbing; break;}
				case ECoastBossPhase::Phase5: { GunBossMovementMode = ECoastBossMovementMode::IdleBobbing; break;}
				case ECoastBossPhase::Phase6: { GunBossMovementMode = ECoastBossMovementMode::PingPong; break;}
			}
		}

		if(bSetHealth)
		{
			if (CoastBossDevToggles::UseManyDrones.IsEnabled() && DroneActors.Num() > 0)
			{
				// float NumMaxDrones = float(DroneActors.Num());
				float NumDrones = float(Formations[CurrentFormation].Drones.Num());
				float DronesLeft = (NumDrones / 24.0);
				HealthComp.SetCurrentHealth(DronesLeft);
			}
			else
			{
				float PhaseByEnum = float(NewPhase);
				PhaseByEnum -=  1.0; // one for lerp in
				float NumPhases = 6.0;
				float Progress = 1.0 - Math::Clamp(PhaseByEnum / NumPhases, 0.0, 1.0);
				HealthComp.SetCurrentHealth(Progress);
			}
		}

		if (!bHackyMadeHealthBarAppear)
		{
			HealthComp.TakeDamage(KINDA_SMALL_NUMBER, EDamageType::Default, this);
			SyncedBossBP.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
			bHackyMadeHealthBarAppear = true;
		}
		// PrintToScreen("HP: " + DronesLeft, 10.0);

		FCoastBossEventHandlerPhaseData EventHandlerData;
		EventHandlerData.NewPhase = NewPhase;
		UCoastBossEventHandler::Trigger_ChangedPhase(this, EventHandlerData);
		BP_ChangedPhase(NewPhase);
		OnChangedPhase.Broadcast(NewPhase);
	}

	void SetNewFormation(ECoastBossFormation NewFormation, bool bNewPhase)
	{
		// is crumbed already from the action capability
		CurrentFormation = NewFormation;
		
		AliveDrones = 0;
		for (int iDrone = 0; iDrone < DroneActors.Num(); ++iDrone)
		{
			if (iDrone < Formations[NewFormation].Drones.Num())
			{
				AliveDrones++;
				UCoastBossDroneComponent MeshComp = Formations[NewFormation].Drones[iDrone];
				int ZeroIndexedID = MeshComp.DroneID -1;
				ACoastBossDroneActor Drone = DroneActors[ZeroIndexedID];
				Drone.bDead = false;
				Drone.Health = 1.0;
				Drone.DroneMesh.Become(MeshComp);
				if (bNewPhase)
					Drone.SetActorHiddenInGame(false);
				Drone.TargetManualRelativeLocation = FVector2D(-MeshComp.RelativeLocation.X, MeshComp.RelativeLocation.Z);
			}
			else if (bNewPhase && !DroneActors[iDrone].DroneMesh.bDisabledInPhase)
			{
				DroneActors[iDrone].bDead = true;
				DroneActors[iDrone].DroneMesh.bDisabledInPhase = true;
				DroneActors[iDrone].SetActorHiddenInGame(true); // todo(Ylva) nice visual crashy thing
			}
		}

		FCoastBossEventHandlerFormationData EventHandlerData;
		EventHandlerData.NewFormation = NewFormation;
		UCoastBossEventHandler::Trigger_ChangedFormation(this, EventHandlerData);
	}

	void DamageBoss(float DamageAmount)
	{
		HealthComp.TakeDamage(DamageAmount, EDamageType::Default, this);
		float HealthByDrones = float(AliveDrones) / 24.0;
		float DroneHealth = 1.0 / 24.0;
		if (HealthByDrones > HealthComp.CurrentHealth + DroneHealth - KINDA_SMALL_NUMBER)
			bRemoveDrone = true;
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		UCoastBossEventHandler::Trigger_OnTakeDamage(this);
		DamageFlash::DamageFlashActor(this, 0.1);
	}

	void KillDrone(ACoastBossDroneActor Drone)
	{
		AliveDrones--;
		bRemoveDrone = false;
		if (HasControl())
			CrumbKillDrone(Drone);
	}

	FCoastBossGunRotateData GetCurrentRotateData()
	{
		FInstigator PrioKey = this;
		ECoastBossGunRotatePrio HighestPrio = ECoastBossGunRotatePrio::Lowest;
		bool bAssignedFirst = false;
		for (auto KeyVal : GunRotationInstigators)
		{
			if (HighestPrio < KeyVal.Value.Prio || !bAssignedFirst)
			{
				PrioKey = KeyVal.Key;
				bAssignedFirst = true;
			}
		}
		return GunRotationInstigators[PrioKey];
	}

	UFUNCTION(CrumbFunction)
	private void CrumbKillDrone(ACoastBossDroneActor Drone)
	{
		DronesKilledDuringPhase++;
		Drone.bDead = true;
		Drone.SetActorHiddenInGame(true); // todo visual feedback first
		// HealthComp.TakeDamage(1.0 / 24.0, EDamageType::Default, this);
	}

	void PlayerEnteredPortal()
	{
		if (!bSentEvent)
		{
			BP_PlayersEnteredPortal();
			bSentEvent = true;
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_ChangedPhase(ECoastBossPhase NewPhase) {}

	void BossDied(AHazePlayerCharacter In_RightMostPlayer)
	{
		if(bQueuedDeath)
			return;

		bQueuedDeath = true;
		RightMostPlayer = In_RightMostPlayer;
		if(Network::IsGameNetworked())
		{
			if(!HasControl())
				return;

			Timer::SetTimer(this, n"LocalBossDied", Network::GetPingOneWaySeconds());
			NetRemoteBossDied(In_RightMostPlayer);
		}
		else
		{
			LocalBossDied();
		}
	}

	UFUNCTION(NetFunction)
	private void NetRemoteBossDied(AHazePlayerCharacter In_RightMostPlayer)
	{
		if(HasControl())
			return;

		RightMostPlayer = In_RightMostPlayer;
		LocalBossDied();
	}

	UFUNCTION()
	private void LocalBossDied()
	{
		TListedActors<ACoastBossActorReferences> ListedReferences;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			bool bWasPlayerDead = Player.IsPlayerDead();
			PlayerHealth::RespawnPlayerSkipTimer(Player);

			if(bWasPlayerDead)
				Player.TeleportToRespawnPoint(ListedReferences.Single.PlaneRespawnPoint, this);
		}

		UCoastBossEventHandler::Trigger_Died(this);
		// BossMeshComp.SetVisibility(false);
		// MineLauncher.SetVisibility(false);
		bDead = true;
		BP_BossDied();

		for(AHazePlayerCharacter Player : Game::Players)
		{
			UCoastBossAeronauticComponent::GetOrCreate(Player).RightMostPlayer = RightMostPlayer;
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_BossDied() {}

	UFUNCTION(BlueprintEvent)
	void BP_PlayersEnteredPortal() {} 

	UFUNCTION(BlueprintCallable)
	ECoastBossPhase GetPhase()
	{
		return Phase;
	}

	UFUNCTION(BlueprintEvent)
	void BP_PrototypeDroneHit(UCoastBossDroneComponent Drone) {}

	bool HasWeakpointsLeft() const
	{
		return DronesKilledDuringPhase < PhaseNumWeakpoints;
	}

	ECoastBossMovementMode GetMovementMode() const
	{
		if (CoastBossDevToggles::UseManyDrones.IsEnabled())
			return Formations[CurrentFormation].MovementMode;
		return GunBossMovementMode;
	}

	void GetRotateSpeed(float& OutPitch, float& OutRoll) const
	{
		switch (CurrentFormation)
		{
			case ECoastBossFormation::State24_Star:
			{
				OutPitch = 45.0;
				break;
			}
			case ECoastBossFormation::State20_Cross:
			{
				OutPitch = -45.0;
				break;
			}
			case ECoastBossFormation::State16_Sun: 
			{
				OutPitch = 20.0;
				break;
			}
			case ECoastBossFormation::State16_Raincloud: { break; }
			case ECoastBossFormation::State12_Drillbazz:
			{
				OutRoll = 720.0;
				break;
			}
			case ECoastBossFormation::State12_Sinus: { break; }
			case ECoastBossFormation::State8_Banana: { break; }
			case ECoastBossFormation::State4_PingPong: { break; }
		}
	}

	void SendHitBall(int BallID)
	{
		for (int iBall = 0; iBall < ActiveBalls.Num(); iBall++)
		{
			if (ActiveBalls[iBall].ID == BallID)
			{
				ActiveBalls[iBall].BallData.bHitSomething = true;
				if (ActiveBalls[iBall].ImpactVFX != nullptr)
					Niagara::SpawnOneShotNiagaraSystemAttachedAtLocation(ActiveBalls[iBall].ImpactVFX, CoastBossPlane2D.Root, ActiveBalls[iBall].ActorLocation);
				return;
			}
		}

		for (int iBall = 0; iBall < ActiveAutoBalls.Num(); iBall++)
		{
			if (ActiveAutoBalls[iBall].ID == BallID)
			{
				ActiveAutoBalls[iBall].BallData.bHitSomething = true;
				if (ActiveAutoBalls[iBall].ImpactVFX != nullptr)
					Niagara::SpawnOneShotNiagaraSystemAttachedAtLocation(ActiveAutoBalls[iBall].ImpactVFX, CoastBossPlane2D.Root, ActiveAutoBalls[iBall].ActorLocation);
				return;
			}
		}
	}

	void SendMineExplode(int MineID)
	{
		NetMineExplode(MineID);
	}

	UFUNCTION(NetFunction)
	private void NetMineExplode(int MineID)
	{
		for (int iMine = 0; iMine < ActiveMines.Num(); iMine++)
		{
			if (ActiveMines[iMine].ID == MineID)
			{
				ACoastBossBulletMine Mine = ActiveMines[iMine];
				Mine.MeshComp.SetVisibility(false);
				Mine.AreaFeedbackMeshComp.SetVisibility(true);
				Mine.MineData.bDetonated = true;
				UCoastBossBulletMineEventHandler::Trigger_Detonate(Mine);
				if (Mine.DetonateVFX != nullptr)
					Niagara::SpawnOneShotNiagaraSystemAttachedAtLocation(Mine.DetonateVFX, CoastBossPlane2D.Root, Mine.ActorLocation);

				if (Game::Mio.HasControl())
					MineTryDamagePlayer(Mine, Game::Mio);
				if (Game::Zoe.HasControl())
					MineTryDamagePlayer(Mine, Game::Zoe);
			}
		}
	}

	private void MineTryDamagePlayer(ACoastBossBulletMine Mine, AHazePlayerCharacter Player)
	{
		bool bPlayerInBlast = Mine.ActorLocation.Distance(Player.ActorLocation) < CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_MineExplosionRadius;
		if (bPlayerInBlast)
		{
			UCoastBossAeronauticComponent AeroComp = UCoastBossAeronauticComponent::Get(Player);
			AeroComp.TryDamagePlayer(3.0, ECoastBossAeuronauticPlayerReceiveDamageType::MineExplosion);
		}
	}

	float GetPingPongAlpha() const
	{
		return 1.0 - Math::Clamp(HealthComp.CurrentHealth * 6.0, 0.0, 1.0);
	}

	// DEV DEV BELOW ----------------------------------------------------------------

	UFUNCTION(DevFunction)
	private void Dev_SetPhase1()
	{
		SetNewPhase(ECoastBossPhase::Phase1, true);
	}

	UFUNCTION(DevFunction)
	private void Dev_SetPhase2()
	{
		SetNewPhase(ECoastBossPhase::Phase2, true);
	}

	UFUNCTION(DevFunction)
	private void Dev_SetPhase3()
	{
		SetNewPhase(ECoastBossPhase::Phase3, true);
	}

	UFUNCTION(DevFunction)
	private void Dev_SetPhase4()
	{
		SetNewPhase(ECoastBossPhase::Phase4, true);
	}

	UFUNCTION(DevFunction)
	private void Dev_SetPhase5()
	{
		SetNewPhase(ECoastBossPhase::Phase5, true);
	}

	UFUNCTION(DevFunction)
	private void Dev_SetPhase6()
	{
		SetNewPhase(ECoastBossPhase::Phase6, true);
	}

	bool ShouldChangeToDevForcedPhase()
	{
		if (Phase < ECoastBossPhase::Phase2 && CoastBossDevToggles::Phase20.IsEnabled())
			return true;
		if (Phase < ECoastBossPhase::Phase3 && CoastBossDevToggles::Phase16.IsEnabled())
			return true;
		if (Phase < ECoastBossPhase::Phase4 && CoastBossDevToggles::Phase12.IsEnabled())
			return true;
		if (Phase < ECoastBossPhase::Phase5 && CoastBossDevToggles::Phase8.IsEnabled())
			return true;
		if (Phase < ECoastBossPhase::Phase6 && CoastBossDevToggles::Phase4.IsEnabled())
			return true;
		return false;
	}

	UFUNCTION()
	private void OnForcePhaseChanged(FName NewState)
	{
		if (CoastBossDevToggles::Phase24.IsEnabled())
			SetNewPhase(ECoastBossPhase::Phase1, true);
		if (CoastBossDevToggles::Phase20.IsEnabled())
			SetNewPhase(ECoastBossPhase::Phase2, true);
		if (CoastBossDevToggles::Phase16.IsEnabled())
			SetNewPhase(ECoastBossPhase::Phase3, true);
		if (CoastBossDevToggles::Phase12.IsEnabled())
			SetNewPhase(ECoastBossPhase::Phase4, true);
		if (CoastBossDevToggles::Phase8.IsEnabled())
			SetNewPhase(ECoastBossPhase::Phase5, true);
		if (CoastBossDevToggles::Phase4.IsEnabled())
			SetNewPhase(ECoastBossPhase::Phase6, true);
	}

	bool HasDevForcedPhase()
	{
		if (CoastBossDevToggles::Phase24.IsEnabled())
			return true;
		if (CoastBossDevToggles::Phase20.IsEnabled())
			return true;
		if (CoastBossDevToggles::Phase16.IsEnabled())
			return true;
		if (CoastBossDevToggles::Phase12.IsEnabled())
			return true;
		if (CoastBossDevToggles::Phase8.IsEnabled())
			return true;
		if (CoastBossDevToggles::Phase4.IsEnabled())
			return true;
		return false;
	}
};