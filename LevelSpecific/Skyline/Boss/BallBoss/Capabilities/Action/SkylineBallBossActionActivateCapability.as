struct FSkylineBallBossActionActivateData
{
	ESkylineBallBossAttacker Attacker;
}

class USkylineBallBossActionActivateCapability : UHazeCapability
{
	FSkylineBallBossActionActivateData Params;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	default CapabilityTags.Add(SkylineBallBossTags::BallBossBlockedInCutsceneTag);
	ASkylineBallBoss BallBoss;
	USkylineBallBossActionsComponent BossComp;

	float TickDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
	}

	USkylineBallBossSettings GetSettings() const property
	{
		return Cast<USkylineBallBossSettings>(
			BallBoss.GetSettings(USkylineBallBossSettings)
		);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossActionActivateData& ActivationParams) const
	{
		if (BossComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossActionActivateData ActivationParams)
	{
		Params = ActivationParams;
		TickDuration = 0.0;
		BossComp.ContinueLostTime();
		// Print(f"Activate {Params.Attacker :n} at {Time::GetGameTimeSince(BossComp.PatternStart)}");
		if (BossComp.bDebugPrintActions)
			Print("SkylineBall boss activate");
		if (BallBoss.Attackers.Contains(Params.Attacker))
			ActivateAttack(BallBoss.Attackers[Params.Attacker]);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TickDuration += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.ActionQueue.Finish(this);
		BossComp.AddLostTime(TickDuration, true);
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
			auto CastedAttackingActor = Cast<ASkylineBallBossThrowableMotorcycleManager>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
				TriggerEventHandler(ESkylineBallBossAttackEventHandlerType::MotorcyclesThrowable);
				AddMotorcycleSunMovement();
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossCarSmash>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
				TriggerEventHandler(ESkylineBallBossAttackEventHandlerType::CarSmash);
				AddSmashCarMovement();
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossMotorcycle>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
				TriggerEventHandler(ESkylineBallBossAttackEventHandlerType::Motorcycles);
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossRollingBus>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
				TriggerEventHandler(ESkylineBallBossAttackEventHandlerType::RollingBus);
				AddBusMovement();
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossDetonatorSpawner>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
				TriggerEventHandler(ESkylineBallBossAttackEventHandlerType::CarMeteor);
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossSlidingCar>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
				TriggerEventHandler(ESkylineBallBossAttackEventHandlerType::CarSlide);
				FVector Relative = CastedAttackingActor.ActorLocation - BallBoss.ActorLocation;
				if (BallBoss.ActorRightVector.DotProduct(Relative) > 0.0)
					AddRightCarMovement();
				else
					AddLeftCarMovement();
			}
		}
		{
			auto CastedAttackingActor = Cast<ASkylineBallBossLobbingCar>(AttackingActor);
			if (CastedAttackingActor != nullptr)
			{
				bFound = true;
				CastedAttackingActor.Activate();
				TriggerEventHandler(ESkylineBallBossAttackEventHandlerType::CarLob);
				FVector Relative = CastedAttackingActor.ActorLocation - BallBoss.ActorLocation;
				if (BallBoss.ActorRightVector.DotProduct(Relative) > 0.0)
					AddRightCarMovement();
				else
					AddLeftCarMovement();
			}
		}
		check(bFound, "Attacking Actor isn't supported in USkylineBallBossAttackEventCapability");
	}

	void TriggerEventHandler(ESkylineBallBossAttackEventHandlerType Type)
	{
		FSkylineBallBossAttackEventHandlerParams EventParams;
		EventParams.AttackType = Type;
		USkylineBallBossEventHandler::Trigger_Attack(BallBoss, EventParams);
	}

	private void AddRightCarMovement()
	{
		BallBoss.ActionsComp.PositionActionQueue.Reset();
		PositionDashTo(ESkylineBallBossLocationNode::ThrowCarRight1, 2.0);
		PositionDashTo(ESkylineBallBossLocationNode::Center, 4.0);
	}

	private void AddLeftCarMovement()
	{
		BallBoss.ActionsComp.PositionActionQueue.Reset();
		PositionDashTo(ESkylineBallBossLocationNode::ThrowCarLeft1, 2.0);
		PositionDashTo(ESkylineBallBossLocationNode::Center, 4.0);
	}

	private void AddBusMovement()
	{
		BallBoss.ActionsComp.PositionActionQueue.Reset();
		PositionDashTo(ESkylineBallBossLocationNode::ThrowBus2, 4.0);
	}

	private void AddSmashCarMovement()
	{
		BallBoss.ActionsComp.PositionActionQueue.Reset();
		PositionDashTo(ESkylineBallBossLocationNode::SmashCars, 2.0);
	}
	
	private void AddMotorcycleSunMovement()
	{
		PositionDashTo(ESkylineBallBossLocationNode::MotorcycleSun, 2.0);
	}

	UFUNCTION()
	private void PositionDashTo(ESkylineBallBossLocationNode Target, float Duration)
	{
		FSkylineBallBossPositionActionDashData Data;
		Data.DashTarget = Target;
		Data.Duration = Duration;
		BallBoss.ActionsComp.PositionActionQueue.Queue(Data);
	}

	UFUNCTION()
	private void PositionIdle(float Duration)
	{
		FSkylineBallBossPositionActionIdleData IdleData;
		IdleData.Duration = Duration;
		BossComp.PositionActionQueue.Queue(IdleData);
	}

}
