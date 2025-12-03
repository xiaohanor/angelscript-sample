class UPrisonBossMagneticSlamAttackCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	float CurrentAttackDuration = 0.0;

	int TimesMagnetBursted = 0;
	bool bMaxBurstsReached = false;

	bool bExiting = false;
	float CurrentExitDuration = 0.0;

	FVector ExitStartLocation;
	FVector ExitTargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CurrentExitDuration >= PrisonBoss::MagneticSlamExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bExiting = false;
		CurrentExitDuration = 0.0;

		CurrentAttackDuration = 0.0;
		TimesMagnetBursted = 0;
		bMaxBurstsReached = false;

		Boss.BP_MagneticSlam();

		AHazePlayerCharacter Player = Game::Zoe;
		if (Boss.GetDistanceTo(Player) < PrisonBoss::MagneticSlamDamageRange)
		{
			Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(FVector::UpVector), Boss.ElectricityImpactDamageEffect, Boss.ElectricityImpactDeathEffect);

			FVector DirToPlayer = (Player.ActorLocation - Boss.ActorLocation).GetSafeNormal();
			Game::Zoe.ApplyKnockdown(DirToPlayer * 200.0, 1.0);
		}

		Boss.MagnetOn();

		Boss.MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"BossMagnetBursted");

		Boss.TriggerFeedback(EPrisonBossFeedbackType::Light);

		Game::Zoe.ApplyCameraSettings(AttackDataComp.MagneticSlamCamSettings, 3.0, this, EHazeCameraPriority::High);

		UPrisonBossEffectEventHandler::Trigger_MagneticSlamImpact(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CurrentAttackType = EPrisonBossAttackType::None;

		if (!bExiting)
			StartExiting(false);

		Boss.ActivateVolley();

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::MagneticSlam);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bExiting)
		{
			CurrentExitDuration += DeltaTime;
			float ExitAlpha = Math::Clamp(CurrentExitDuration/PrisonBoss::MagneticSlamExitDuration, 0.0, 1.0);
			float TranslationAlpha = AttackDataComp.GroundTrailExitCurve.GetFloatValue(CurrentExitDuration/PrisonBoss::MagneticSlamExitDuration);
			FVector Loc = Math::Lerp(ExitStartLocation, ExitTargetLocation, TranslationAlpha);

			if (!bMaxBurstsReached)
			{
				float Height = Math::Lerp(ExitStartLocation.Z, ExitTargetLocation.Z, AttackDataComp.GroundTrailExitVerticalCurve.GetFloatValue(ExitAlpha));
				Loc.Z = Height;
			}

			Boss.SetActorLocation(Loc);

			// Debug::DrawDebugSphere(Boss.ActorLocation);
		}
		else
		{
			CurrentAttackDuration += DeltaTime;
			if (CurrentAttackDuration >= PrisonBoss::MagneticSlamGroundedDuration)
			{
				if (HasControl())
					CrumbStartExiting(false);
			}
		}
	}

	UFUNCTION()
	private void BossMagnetBursted(FMagneticFieldData Data)
	{
		FVector DirFromPlayer = (Game::Zoe.ActorLocation - Boss.MagnetCollider.WorldLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		float Dot = DirFromPlayer.DotProduct(Boss.ActorRightVector);
		EHazeCardinalDirection Direction = CardinalDirectionForActor(Boss, -DirFromPlayer);

		CurrentAttackDuration -= PrisonBoss::MagneticSlamGroundedDurationIncreasePerMagnetBurst;

		TimesMagnetBursted++;
		if (TimesMagnetBursted >= PrisonBoss::MagneticSlamBurstsRequired)
		{
			if (HasControl() && !bExiting)
				CrumbTriggerSuccess(Direction);
		}
		else
		{	
			if (HasControl())
				CrumbTriggerHit(Direction);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerHit(EHazeCardinalDirection Direction)
	{
		Boss.OnMagnetBlasted.Broadcast();
		Boss.TriggerFeedback(EPrisonBossFeedbackType::Medium);

		FName ParamName;
		switch (Direction)
		{
			case EHazeCardinalDirection::Forward : 
			{
				ParamName = n"HitReactionFwd";
				break;
			}
			case EHazeCardinalDirection::Backward :
			{
				ParamName = n"HitReactionBack";
				break;
			}
			case EHazeCardinalDirection::Left :
			{
				ParamName = n"HitReactionLeft";
				break;
			}
			case EHazeCardinalDirection::Right :
			{
				ParamName = n"HitReactionRight";
				break;
			}
		}

		Boss.SetAnimBoolParam(ParamName, true);

		UPrisonBossEffectEventHandler::Trigger_MagneticSlamBlasted(Boss);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerSuccess(EHazeCardinalDirection Direction)
	{
		Boss.OnMagnetBlasted.Broadcast();
		Boss.TriggerFeedback(EPrisonBossFeedbackType::Medium);

		FName ParamName;
		switch (Direction)
		{
			case EHazeCardinalDirection::Forward : 
			{
				ParamName = n"ExitFwd";
				break;
			}
			case EHazeCardinalDirection::Backward :
			{
				ParamName = n"ExitBack";
				break;
			}
			case EHazeCardinalDirection::Left :
			{
				ParamName = n"ExitLeft";
				break;
			}
			case EHazeCardinalDirection::Right :
			{
				ParamName = n"ExitRight";
				break;
			}
		}

		Boss.SetAnimBoolParam(ParamName, true);
		StartExiting(true);

		UPrisonBossEffectEventHandler::Trigger_MagneticSlamFinalBlast(Boss);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartExiting(bool bSuccess)
	{
		StartExiting(bSuccess);
	}

	void StartExiting(bool bSuccess)
	{
		if (bSuccess)
		{
			bMaxBurstsReached = true;
		}
		else
		{
			Boss.AnimationData.bIsExitingMagneticSlamNoBlast = true;
		}

		ExitStartLocation = Boss.ActorLocation;
		ExitTargetLocation = Boss.MiddlePoint.ActorLocation;

		bExiting = true;
		Boss.MagnetOff();
		Boss.MagneticFieldResponseComp.OnBurst.UnbindObject(this);
		Boss.OnMagnetReset.Broadcast();
		Game::Zoe.ClearCameraSettingsByInstigator(this);

		if (!bMaxBurstsReached)
		{
			if (Boss.GetDistanceTo(Game::Zoe) <= PrisonBoss::MagneticSlamExitDamageBlastRange)
				Game::Zoe.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(FVector::UpVector), Boss.ElectricityImpactDamageEffect, Boss.ElectricityImpactDeathEffect);

			UPrisonBossEffectEventHandler::Trigger_MagneticSlamExit(Boss);

			Boss.TriggerFeedback(EPrisonBossFeedbackType::Medium, 1.0, EHazeSelectPlayer::Zoe);
		}
	}
}