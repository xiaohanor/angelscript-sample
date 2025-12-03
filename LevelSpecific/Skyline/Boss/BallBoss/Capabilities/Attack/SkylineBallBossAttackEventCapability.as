enum ESkylineBallBossAttacker
{
	None,
	CarSmash1,
	CarSmash2,
	Bike1,
	Bike2,
	Bike3,
	Bike4,
	Bike5,
	Bike6,
	Bike7,
	RollingBus,
	SlidingCar3,
	SlidingCar4,
	SlidingCar5,
	SlidingCar6,
	DetonatorSpawner1,
	DetonatorSpawner2,
	DetonatorSpawner3,
	MotorcycleManager,
	LobbingCar1,
	LobbingCar2,
	LobbingCar3,
	LobbingCar4,
	LobbingCar5,
	LobbingCar6,
}

class USkylineBallBossAttackEventCapability : USkylineBallBossChildCapability
{
	ESkylineBallBossAttacker Attacker;

	USkylineBallBossAttackEventCapability(ESkylineBallBossAttacker AttackerEnum)
	{
		Attacker = AttackerEnum;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		FString AttackerName = "" + Attacker;
		TemporalLog.Value("Attacker", AttackerName);
	}
#endif

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (BallBoss.Attackers.Contains(Attacker))
			ActivateAttack(BallBoss.Attackers[Attacker]);
	}

	void ActivateAttack(AActor AttackingActor)
	{
		if (!ensure(AttackingActor != nullptr, "Attacking Actor was nullptr! Did it get destroyed?"))
			return;

		// Attack expression!
		if (Time::GameTimeSeconds > BallBoss.AttackSwitchExpressionTimestamp + BallBoss.AttackSwitchExpressionCooldown)
		{
			BallBoss.AttackSwitchExpressionTimestamp = Time::GameTimeSeconds;
			BallBoss.RemoveBlink(BallBoss.AttackBlinkTokenComp);
			ESkylineBallBossBlinkExpression Expression = ESkylineBallBossBlinkExpression::None;
			float BallRandomAngry = Math::RandRange(0.0, 1.0);
			if (BallRandomAngry > 0.9)
				BallBoss.AddBlink(BallBoss.AttackBlinkTokenComp, ESkylineBallBossBlinkExpression::StateAngry, ESkylineBallBossBlinkPriority::Med);
		}

		bool bFound = false;
		// some scoping for ugly auto copy paste variable <3
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossCarSmash>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossMotorcycle>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossRollingBus>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossDetonatorSpawner>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossSlidingCar>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
			}
		}
		check(bFound, "Attacking Actor isn't supported in USkylineBallBossAttackEventCapability");
	}
}