class UCoastBossAttackWithGunsQueueCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;
	
	ACoastBoss CoastBoss;
	ACoastBossActorReferences References;
	int Phase2_MillShots = 0;

	int RainShots = 0;

	bool bShootFromTopMuzzle = true;
	bool bShootFromLeftMuzzle = true;
	bool bWasRainRecover = false;
	bool bPhase3PendlulumBack = false;

	bool bHasRotateRequested = false;
	ECoastBossPhase RotateRequesterPhase;

	bool bStartIdled = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CoastBoss = Cast<ACoastBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (CoastBoss.State != ECoastBossState::Shooting)
			return false;
		if (!CoastBoss.AttackActionQueue.IsEmpty())
			return false;
		if (CoastBoss.bDead)
			return false;
		if (CoastBossDevToggles::UseManyDrones.IsEnabled())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CoastBoss.AttackActionQueue.IsEmpty())
			return true;
		return false;
	}

	bool TryCacheThings()
	{
		if (References == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			if (Refs.Num() > 0)
				References = Refs.Single;
		}
		return References != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		if (!bStartIdled || !CoastBoss.bStarted)
		{
			if (CoastBoss.GetPhase() != ECoastBossPhase::LerpIn)
			{
				ChangeMovementMode(ECoastBossMovementMode::IdleBobbing);
				if (!bStartIdled)
					CoastBoss.AttackActionQueue.Idle(0.1);
				else
					CoastBoss.AttackActionQueue.Idle(0.5);
				bStartIdled = true;
				return;
			}
		}

		switch (CoastBoss.GetPhase())
		{
			case ECoastBossPhase::LerpIn:
			{
				break;
			}
			case ECoastBossPhase::Phase1:
			{
				Phase1Sequence();
				break;
			}
			case ECoastBossPhase::Phase2:
			{
				Phase2Sequence();
				break;
			}
			case ECoastBossPhase::Phase3:
			{
				Phase3Sequence();
				break;
			}
			case ECoastBossPhase::Phase4:
			{
				Phase4Sequence();
				break;
			}
			case ECoastBossPhase::Phase5:
			{
				Phase5Sequence();
				break;
			}
			case ECoastBossPhase::Phase6:
			{
				Phase6Sequence();
				break;
			}
		}

		if (bHasRotateRequested && RotateRequesterPhase != CoastBoss.GetPhase())
			RemoveRotationRequest();
	}

	private void Phase1Sequence()
	{
		CoastBoss.AttackActionQueue.Event(this, n"AddPhase1UpRotationRequest");
		ChangeMovementMode(ECoastBossMovementMode::WaveUp);
		//CoastBoss.AttackActionQueue.Idle(Math::RandRange(0.0, 1.0));

		float DurationBetweenBallsUp = CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_Interval / float(CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_NumBullets);
		for (int iBullet = 0; iBullet < CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_NumBullets; ++iBullet)
		{
			ShootAutoBall(CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_BulletSpeed);
			if (DurationBetweenBallsUp > KINDA_SMALL_NUMBER)
				CoastBoss.AttackActionQueue.Idle(DurationBetweenBallsUp);
		}
		// CoastBoss.ActionQueue.Idle(CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_Interval);

		CoastBoss.AttackActionQueue.Event(this, n"RemoveRotationRequest");
		CoastBoss.AttackActionQueue.Event(this, n"AddPhase1DownRotationRequest");
		ChangeMovementMode(ECoastBossMovementMode::WaveDown);
		//CoastBoss.AttackActionQueue.Idle(Math::RandRange(0.0, 1.0));

		float DurationBetweenBallsDown = CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_Duration / float(CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_NumBullets);
		for (int iBullet = 0; iBullet < CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_NumBullets; ++iBullet)
		{
			ShootAutoBall(CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_BulletSpeed);
			if (DurationBetweenBallsDown > KINDA_SMALL_NUMBER)
				CoastBoss.AttackActionQueue.Idle(DurationBetweenBallsDown);
		}
		CoastBoss.AttackActionQueue.Event(this, n"RemoveRotationRequest");
	}

	private void Phase2Sequence()
	{
		ChangeMovementMode(ECoastBossMovementMode::CrossDownUp);
		CoastBoss.AttackActionQueue.Idle(CoastBossConstants::BigDroneBoss::Phase2_CrossMoveDownUp_Duration);
		ShootFrontMill();
		ChangeMovementMode(ECoastBossMovementMode::CrossUpDown);
		CoastBoss.AttackActionQueue.Idle(CoastBossConstants::BigDroneBoss::Phase2_CrossMoveUpDown_Duration);
		ShootFrontMill();
	}

	private void Phase3Sequence()
	{
		if (CoastBoss.GunBossMovementMode == ECoastBossMovementMode::IdleBobbing)
		{
			SpawnMines();
			CoastBoss.AttackActionQueue.Idle(2.0);
			
			SunBurst();

			CoastBoss.AttackActionQueue.Idle(1.0);
			ChangeMovementMode(ECoastBossMovementMode::CloudRainSinus);
			CoastBoss.AttackActionQueue.Idle(1.0);
		}
		if (CoastBoss.GunBossMovementMode == ECoastBossMovementMode::CloudRainSinus)
		{
			if (CoastBoss.bExitCloud)
			{
				RainShots = 0;
				ChangeMovementMode(ECoastBossMovementMode::IdleBobbing);
				CoastBoss.bExitCloud = false;
					return;
			}
			if (!bWasRainRecover && CoastBoss.bRainRecover)
			{
				CoastBoss.AttackActionQueue.Event(this, n"RemoveRotationRequest");
				SpawnMines();
				CoastBoss.AttackActionQueue.Idle(0.2);
				SunBurst();
			}
			bWasRainRecover = CoastBoss.bRainRecover;

			if (!CoastBoss.bRainRecover)
			{
				const float PendulumDuration = CoastBossConstants::BigDroneBoss::Phase3_RainAttack_PendulumDuration;
				int NumBullets = Math::RandRange(1, 3);
				float PendulumShootInterval = PendulumDuration / float(NumBullets);
				if (bPhase3PendlulumBack)
				{
					CoastBoss.AttackActionQueue.Event(this, n"AddPhase3RainBackRotationRequest");
					for (int iBullet = 0; iBullet < NumBullets; ++iBullet)
					{
						float BulletSpeed = Math::RandRange(CoastBossConstants::BigDroneBoss::Phase3_RainAttack_BulletSpeedMin, CoastBossConstants::BigDroneBoss::Phase3_RainAttack_BulletSpeedMax);
						ShootAutoBall(BulletSpeed, false);
						CoastBoss.AttackActionQueue.Idle(PendulumShootInterval);
					}
				}
				else
				{
					CoastBoss.AttackActionQueue.Event(this, n"AddPhase3RainForwardRotationRequest");
					for (int iBullet = 0; iBullet < NumBullets; ++iBullet)
					{
						float BulletSpeed = Math::RandRange(CoastBossConstants::BigDroneBoss::Phase3_RainAttack_BulletSpeedMin, CoastBossConstants::BigDroneBoss::Phase3_RainAttack_BulletSpeedMax);
						ShootAutoBall(BulletSpeed, false);
						CoastBoss.AttackActionQueue.Idle(PendulumShootInterval);
					}
				}
				bPhase3PendlulumBack = !bPhase3PendlulumBack;
			}
			else
				CoastBoss.AttackActionQueue.Idle(0.2);
		}
	}

	private void SpawnMines()
	{
		SetMineLauncherExtended(true);
		CoastBoss.AttackActionQueue.Idle(1.0);
		DropMine();
		CoastBoss.AttackActionQueue.Idle(0.8);
		DropMine();
		CoastBoss.AttackActionQueue.Idle(1.0);
		SetMineLauncherExtended(false);
	}

	private void SunBurst()
	{
		float BulletSpeed = CoastBossConstants::BigDroneBoss::Phase3_SunBurstAttack_BulletSpeed;
		float Span = 20.0;

		for (int iSunBurst = 0; iSunBurst < 1; iSunBurst++)
		{
			float CenterAngle = Math::RandRange(-Span, Span);
			ShootVolley(4, CenterAngle, 60.0, BulletSpeed);
			CoastBoss.AttackActionQueue.Idle(0.23);
			// ShootVolley(2, CenterAngle, 30.0, BulletSpeed);
			// CoastBoss.ActionQueue.Idle(0.1);
			ShootVolley(4, CenterAngle, 60.0, BulletSpeed * 0.8);
			// ShootSingleBall(CenterAngle, BulletSpeed);
			CoastBoss.AttackActionQueue.Idle(0.1);
			ShootVolley(2, CenterAngle, 30.0, BulletSpeed);
			CoastBoss.AttackActionQueue.Idle(0.1);
				ShootVolley(3, CenterAngle, 30.0, BulletSpeed * 0.6);
			CoastBoss.AttackActionQueue.Idle(1.0);
		}
	}

	private void Phase4Sequence()
	{
		if (CoastBoss.GunBossMovementMode == ECoastBossMovementMode::Drillbazz)
		{
			CoastBoss.AttackActionQueue.Idle(CoastBossConstants::BigDroneBoss::Phase4_ChargetAttack_AnticipationDuration);
			CoastBoss.AttackActionQueue.Idle(CoastBossConstants::BigDroneBoss::Phase4_ChargetAttack_ChargeDuration);
			ChangeMovementMode(ECoastBossMovementMode::IdleBobbing);
		}
		else
		{
			float ShootyDuration = CoastBossConstants::ManyDronesBoss::Phase12Drones_VolleyDuration;
			float BulletWaves = 3.0;
			float Fraction = ShootyDuration / BulletWaves;

			float Span = 15.0;
			for (float iWave = 0.0; iWave < ShootyDuration - 0.01; iWave += Fraction)
			{
				ShootSingleBall(Math::RandRange(-Span, Span), 1200.0);
				ShootSingleBall(Math::RandRange(-Span, Span), 1200.0);
				ShootSingleBall(Math::RandRange(-Span, Span), 1200.0);
				ShootSingleBall(Math::RandRange(-Span, Span), 1200.0);
				ShootSingleBall(Math::RandRange(-Span, Span), 1200.0);
				ShootSingleBall(Math::RandRange(-Span, Span), 1200.0);
			}
			CoastBoss.AttackActionQueue.Idle(CoastBossConstants::BigDroneBoss::Phase4_BurstAttack_Duration);
			ChangeMovementMode(ECoastBossMovementMode::Drillbazz);
		}
	}

	private void Phase5Sequence()
	{
		if (CoastBoss.GunBossMovementMode != ECoastBossMovementMode::IdleBobbing)
			ChangeMovementMode(ECoastBossMovementMode::IdleBobbing);

		float Span = CoastBossConstants::BigDroneBoss::Phase5_VolleyAttack_AngleSpan;
		float Interval = CoastBossConstants::BigDroneBoss::Phase5_VolleyAttack_Interval;
		float BulletSpeed = CoastBossConstants::BigDroneBoss::Phase5_VolleyAttack_BulletSpeed;
		
		float AngleStep = 30.0;
		float Sign = Math::RandBool() ? 1.0 : -1.0;
		float StartAngle = AngleStep * Sign;
		for (int iVolley = 0; iVolley < 3; ++iVolley)
		{
			ShootVolley(CoastBossConstants::BigDroneBoss::Phase5_VolleyAttack_NumBullets, StartAngle, Span, BulletSpeed);
			CoastBoss.AttackActionQueue.Idle(Interval);
			StartAngle += AngleStep * Sign * -1.0;
		}
		CoastBoss.AttackActionQueue.Idle(CoastBossConstants::BigDroneBoss::Phase5_VolleyAttack_Cooldown);
	}

	private void Phase6Sequence()
	{
		const float Interval = Math::Lerp(CoastBossConstants::BigDroneBoss::Phase6_PingPongVolley_BulletIntervalMin, CoastBossConstants::BigDroneBoss::Phase6_PingPongVolley_BulletIntervalMax, CoastBoss.GetPingPongAlpha());
		CoastBoss.AttackActionQueue.Idle(Interval);
		ShootAutoBall(CoastBossConstants::BigDroneBoss::Phase6_PingPongVolley_BulletSpeed);
	}

	void ShootSingleBall(float Angle, float Speed, bool bForceLeft = true)
	{
		FCoastBossGunShootBallActionParams ShootParams;
		ShootParams.CenterAngle = Angle;
		FCoastBossGunBulletData BulletData;

		if(bForceLeft)
			bShootFromLeftMuzzle = true;
		else
			bShootFromLeftMuzzle = !bShootFromLeftMuzzle;

		BulletData.bUseLeftGun = bShootFromLeftMuzzle;
		BulletData.bUseTopGun = bShootFromTopMuzzle;
		bShootFromTopMuzzle = !bShootFromTopMuzzle;
		BulletData.ShootAngle = Angle;
		BulletData.BulletSpeed = Speed;
		ShootParams.BulletDatas.Add(BulletData);
		CoastBoss.AttackActionQueue.Capability(UCoastBossGunShootBallCapability, ShootParams);
	}

	void ShootAutoBall(float Speed, bool bForceLeft = true)
	{
		FCoastBossGunShootAutoBallActionParams ShootParams;
		FCoastBossGunBulletData BulletData;

		if(bForceLeft)
			bShootFromLeftMuzzle = true;
		else
			bShootFromLeftMuzzle = !bShootFromLeftMuzzle;

		BulletData.bUseLeftGun = bShootFromLeftMuzzle;
		BulletData.bUseTopGun = bShootFromTopMuzzle;
		bShootFromTopMuzzle = !bShootFromTopMuzzle;
		BulletData.BulletSpeed = Speed;
		ShootParams.BulletDatas.Add(BulletData);
		CoastBoss.AttackActionQueue.Capability(UCoastBossGunShootAutoBallCapability, ShootParams);
	}

	void ShootVolley(int Number, float CenterAngle, float Spread, float Speed, bool bForceLeft = true)
	{
		FCoastBossGunShootBallActionParams ShootParams;
		ShootParams.CenterAngle = CenterAngle;

		float AngleStep = Spread / float(Number -1);
		float CurrentAngle = CenterAngle - Spread * 0.5;
		const float GunPlacementAngleCompensation = 1.5;
		for (int iBall = 0; iBall < Number; ++iBall)
		{
			FCoastBossGunBulletData BulletData;

			if(bForceLeft)
				bShootFromLeftMuzzle = true;
			else
				bShootFromLeftMuzzle = !bShootFromLeftMuzzle;

			BulletData.bUseLeftGun = bShootFromLeftMuzzle;
			BulletData.bUseTopGun = CurrentAngle - CenterAngle >= 0.0 ? true : false;
			BulletData.ShootAngle = BulletData.bUseTopGun ? CurrentAngle - GunPlacementAngleCompensation : CurrentAngle + GunPlacementAngleCompensation;
			BulletData.BulletSpeed = Speed;
			CurrentAngle += AngleStep;
			ShootParams.BulletDatas.Add(BulletData);
		}
		CoastBoss.AttackActionQueue.Capability(UCoastBossGunShootBallCapability, ShootParams);
	}

	void ShootFrontMill()
	{
		FCoastBossGunShootMillActionParams ShootParams;
		float Span = CoastBossConstants::BigDroneBoss::Phase2_CrossAttack_ShootAngleSpan * 0.5;
		ShootParams.BulletData.ShootAngle = Math::RandRange(-Span, Span);
		ShootParams.BulletData.BulletSpeed = CoastBossConstants::BigDroneBoss::Phase2_CrossAttack_Speed;
		ShootParams.BulletData.bUseTopGun = bShootFromTopMuzzle;
		bShootFromTopMuzzle = !bShootFromTopMuzzle;
		CoastBoss.AttackActionQueue.Capability(UCoastBossGunShootMillCapability, ShootParams);
	}

	void DropMine()
	{
		CoastBoss.AttackActionQueue.Capability(UCoastBossGunShootMineCapability);
	}

	void SetMineLauncherExtended(bool bExtended)
	{
		FCoastBossGunToggleMineLauncherExtendedParams Params;
		Params.bExtended = bExtended;
		CoastBoss.AttackActionQueue.Capability(UCoastBossGunToggleMineLauncherExtendedCapability, Params);
	}
	
	void ChangeMovementMode(ECoastBossMovementMode NewMovementMode)
	{
		FCoastBossGunChangeMovementActionParams Data;
		Data.NewMode = NewMovementMode;
		CoastBoss.AttackActionQueue.Capability(UCoastBossGunChangeMovementCapability, Data); 
	}

	const float Phase1Angle = 30.0;

	UFUNCTION()
	void AddPhase1UpRotationRequest()
	{
		CrumbAddRotationRequest(Phase1Angle, CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_Interval);
	}

	UFUNCTION()
	void AddPhase1DownRotationRequest()
	{
		CrumbAddRotationRequest(-Phase1Angle, CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_Duration);
	}

	UFUNCTION()
	void AddPhase3RainBackRotationRequest()
	{
		CrumbAddRotationRequest(-100.0, CoastBossConstants::BigDroneBoss::Phase3_RainAttack_PendulumDuration);
	}

	UFUNCTION()
	void AddPhase3RainForwardRotationRequest()
	{
		CrumbAddRotationRequest(-80.0, CoastBossConstants::BigDroneBoss::Phase3_RainAttack_PendulumDuration);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAddRotationRequest(float Angle, float OverrideDuration = 0.0)
	{
		if (bHasRotateRequested)
			RemoveRotationRequest();
		bHasRotateRequested = true;
		FCoastBossGunRotateData Data;
		Data.Prio = ECoastBossGunRotatePrio::Low;
		Data.TargetShootAngle = Angle;
		Data.OverrideDuration = OverrideDuration;
		CoastBoss.AddRotateReqeuster(this, Data);
		RotateRequesterPhase = CoastBoss.GetPhase();
	}

	UFUNCTION()
	void RemoveRotationRequest()
	{
		CrumbRemoveRotationRequest();
	}

	UFUNCTION(CrumbFunction)
	void CrumbRemoveRotationRequest()
	{
		CoastBoss.RemoveRotateRequester(this);
		bHasRotateRequested = false;
	}

};