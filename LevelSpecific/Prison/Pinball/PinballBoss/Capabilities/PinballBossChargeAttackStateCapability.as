struct FPinballBossChargeAttackStateDeactivateParams
{
	bool bInterrupted = false;
	bool bFinished = false;
};

class UPinballBossChargeAttackStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Gameplay;

	APinballBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APinballBoss>(Owner);
		Boss.MagnetAutoAimComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.BossState != EPinballBossState::ChargeAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballBossChargeAttackStateDeactivateParams& Params) const
	{
		if(!Boss.bIsCharging)
		{
			Params.bInterrupted = true;
			return true;
		}

		if(Boss.BossState != EPinballBossState::ChargeAttack)
		{
			Params.bInterrupted = Boss.bIsCharging;
			return true;
		}

		if(ActiveDuration > Boss.ChargeAttackDuration)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.SetBossState(EPinballBossState::ChargeAttack);

		Boss.bIsCharging = true;
		Boss.MagnetAutoAimComp.Enable(this);

		UPinballBossEventHandler::Trigger_ChargeAttack(Boss);
		Print(""+Boss.BossState);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballBossChargeAttackStateDeactivateParams Params)
	{
		Boss.MagnetAutoAimComp.Disable(this);

		if(Params.bInterrupted)
		{
			UPinballBossEventHandler::Trigger_ChargeAttackInterrupted(Boss);
		}

		if(Params.bFinished)
		{
			UPinballBossEventHandler::Trigger_ChargeAttackExplosion(Boss);
			Timer::SetTimer(this, n"KillPlayerAfterShortDelay", 0.2);
			//Boss.SetBossState(EPinballBossState::Idle);
		}

		Boss.bVulnerable = false;
		Boss.bIsCharging = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float TargetSplineDistance = Boss.ActiveSpline.Spline.SplineLength*0.5;
		const FVector TargetLocation = Boss.ActiveSpline.Spline.GetWorldLocationAtSplineDistance(TargetSplineDistance);
		const FVector Location = Math::VInterpTo(Boss.ActorLocation, TargetLocation, DeltaTime, 1.25);
		Boss.SetActorLocation(Location);

		const FRotator Rotation = Math::RInterpTo(Boss.ActorRotation, FRotator::MakeFromX(FVector::BackwardVector), DeltaTime, 1);
		Boss.SetActorRotation(Rotation);

		if(!Boss.bBallRotationControlledFromBP)
		{
			const FRotator BallRelativeRotation = Math::RInterpTo(Boss.BallLookAtComp.RelativeRotation, FRotator(0,0,0), DeltaTime, 2);
			Boss.BallLookAtComp.SetRelativeRotation(BallRelativeRotation);
		}
	}

	UFUNCTION()
	private void KillPlayerAfterShortDelay()
	{
		Pinball::GetBallPlayer().KillPlayer(FPlayerDeathDamageParams(),Boss.ChargeAttackDeathEffect);
		PlayerHealth::TriggerGameOver();
	}
};