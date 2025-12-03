class USkylineBallBossActionsComponent : UActorComponent
{
	FHazeStructQueue ActionQueue;
	FHazeStructQueue PositionActionQueue;
	bool bDebugPrintActions = false;

	float PatternStart = 0.0;

	private float ActionQueueLostTime = 0.0;
	private float ActionQueueLostTimeThisFrame = 0.0;
	private uint32 ActionQueueLostTimeFrameNumber = 0;

	float ConsumeLostTime()
	{
		float Time = ActionQueueLostTime;
		if (ActionQueueLostTimeFrameNumber != GFrameNumber)
			Time += ActionQueueLostTimeThisFrame;

		// Print(f"Consume Lost Time {Time}");

		ActionQueueLostTimeThisFrame = 0.0;
		ActionQueueLostTime = 0.0;
		ActionQueueLostTimeFrameNumber = 0;

		return Time;
	}

	void ContinueLostTime()
	{
		if (ActionQueueLostTimeFrameNumber != GFrameNumber)
			ActionQueueLostTime += ActionQueueLostTimeThisFrame;

		ActionQueueLostTimeThisFrame = 0.0;
		ActionQueueLostTimeFrameNumber = 0;
	}

	void AddLostTime(float LostTime, bool bIncludeThisFrame)
	{
		ActionQueueLostTime += LostTime;
		if (bIncludeThisFrame)
		{
			ActionQueueLostTimeThisFrame = Time::GlobalWorldDeltaSeconds;
			ActionQueueLostTimeFrameNumber = GFrameNumber;
		}
		else
		{
			ActionQueueLostTime = 0.0;
			ActionQueueLostTimeFrameNumber = 0;
		}

		// Print(f"Add Lost Time {LostTime} with {Time::GlobalWorldDeltaSeconds} (Total {ActionQueueLostTime})");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("ActionQueueLostTime", ActionQueueLostTime)
			.Value("ActionQueueLostTimeThisFrame", ActionQueueLostTimeThisFrame)
			.Value("ActionQueueLostTimeFrameNumber", ActionQueueLostTimeFrameNumber)
		;
	}
}

asset SkylineBallBossActionSelectionSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineBallBossActionSelectionCapability);
	Capabilities.Add(USkylineBallBossActionActivateCapability);
	Capabilities.Add(USkylineBallBossActionIdleCapability);
	Capabilities.Add(USkylineBallBossActionCarAppearCapability);
	Capabilities.Add(USkylineBallBossActionMotorcyclesAppearCapability);
	Capabilities.Add(USkylineBallBossActionLaserCapability);
	Capabilities.Add(USkylineBallBossActionPositionCapability);
};

class USkylineBallBossActionSelectionCapability : UHazeCapability
{
	FSkylineBallBossActionActivateData Params;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	default CapabilityTags.Add(SkylineBallBossTags::BallBossBlockedInCutsceneTag);
	ASkylineBallBoss BallBoss;
	USkylineBallBossActionsComponent BossComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
		SkylineBallBossDevToggles::AttackPattern.MakeVisible();
		SkylineBallBossDevToggles::AttackPattern.BindOnChanged(this, n"ToggleOptionChanged");
	}

	UFUNCTION()
	private void ToggleOptionChanged(FName NewState)
	{
		BossComp.ActionQueue.Reset();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BossComp.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossComp.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// When we call SkylineBallBoss ChangePhase, we reset the queue and add a "dramatic pause" (konstpaus)
		if (BallBoss.ChangedPhaseDramaticPauseTimestamp > KINDA_SMALL_NUMBER)
			return;

#if !RELEASE
		if (BallBoss.DisableAttacksRequesters.Num() > 0)
		{
			if (SkylineBallBossDevToggles::AttackSlidingCars.IsEnabled())
				AttackSlidingCars1();
			if (SkylineBallBossDevToggles::AttackLobbingCars.IsEnabled())
				AttackLobbingCar1();
			if (SkylineBallBossDevToggles::AttackSmashingCars.IsEnabled())
				AttackSmashingCars1();
			if (SkylineBallBossDevToggles::AttackMeteorCars.IsEnabled())
				AttackDetonators();
			if (SkylineBallBossDevToggles::AttackThrowMotorcycle.IsEnabled())
				AttackThrowMotorcycles();
			if (SkylineBallBossDevToggles::AttackMotorcycle.IsEnabled())
				AttackMotorcycles();
			if (SkylineBallBossDevToggles::AttackLaser1.IsEnabled())
				LaserPattern1();
			if (SkylineBallBossDevToggles::AttackLaser2.IsEnabled())
				LaserPattern2();

			Idle(10.0);
			return;
		}
#endif

		switch (BallBoss.GetPhase())
		{
			case ESkylineBallBossPhase::Chase: break;
			case ESkylineBallBossPhase::PostChaseElevator: break;
			case ESkylineBallBossPhase::Top: Top(); break;
			case ESkylineBallBossPhase::TopGrappleFailed1: Grapple1Failed(); break;
			case ESkylineBallBossPhase::TopMioOn1: MioOn1(); break;
			case ESkylineBallBossPhase::TopAlignMioToStage: break;
			case ESkylineBallBossPhase::TopShieldShockwave: break;
			case ESkylineBallBossPhase::TopMioOff2: TopMioOff2(); break;
			case ESkylineBallBossPhase::TopGrappleFailed2: Grapple2Failed(); break;
			case ESkylineBallBossPhase::TopMioOn2: TopMioOn2(); break;
			case ESkylineBallBossPhase::TopMioOnEyeBroken: break;
			case ESkylineBallBossPhase::TopMioIn: TopMioIn(); break;
			case ESkylineBallBossPhase::TopMioInKillWeakpoint: TopMioInKillWeakpoint(); break;
			case ESkylineBallBossPhase::TopDeath: break;
			default: break;
		}
	}

	// ---------------------
	// Attack phases

	void Top()
	{
		BossComp.PatternStart = Time::GameTimeSeconds;
		Idle(2.0);
		AttackSlidingCars1();
		Idle(4.0);
		AttackSmashingCars1();
		Idle(4.5);
		DashToPosition(ESkylineBallBossLocationNode::Motorcycles, 2.0);
		Idle(1.0);
		AttackMotorcycles();
		Idle(1.5);
		LaserPattern1();
	}

	void Grapple1Failed()
	{
		AttackSlidingCars1();
		Idle(3.0);
		LaserPattern1();
	}

	void MioOn1()
	{
		AttackSlidingCars3();
		AttackDetonators();
		Idle(7.0);
		AttackMotorcycles();
		AttackDetonators();
		Idle(7.0);
	}

	void TopMioOff2()
	{
		DashToPosition(ESkylineBallBossLocationNode::ThrowBus1, 2.0);
		Idle(1.0);
		ActivateActor(ESkylineBallBossAttacker::RollingBus);
		Idle(10.0);
		AttackThrowMotorcycles();
		Idle(14.0);
		AttackLobbingCar1();
		Idle(4.0);
		LaserPattern2();
	}

	void Grapple2Failed()
	{
		AttackSlidingCars2();
		Idle(3.0);
		LaserPattern2();
	}

	void TopMioOn2()
	{
		Idle(3.0);
		AttackLobbingCar2();
		AttackDetonators();
		Idle(3.0);
		// DashToPosition(ESkylineBallBossLocationNode::ThrowBus1, 2.0);
		// Idle(1.0);
		ActivateActor(ESkylineBallBossAttacker::RollingBus);
		Idle(6.0);
		AttackDetonators();
		Idle(1.0);
	}

	// void TopMioIn()
	// {
	// 	AttackSlidingCars3();
	// 	Idle(2.0);
	// 	Laser(ESkylineBallBossTopLaserSplineID::Spline3, false);
	// 	AttackMotorcycles2();
	// 	Laser(ESkylineBallBossTopLaserSplineID::Spline2, false);
	// 	AttackLobbingCar2();
	// 	Idle(3.0);
	// 	Laser(ESkylineBallBossTopLaserSplineID::Spline4, false);
	// }

	void TopMioIn()
	{
		CarAppear(ESkylineBallBossAttacker::SlidingCar5);
		CarAppear(ESkylineBallBossAttacker::SlidingCar6);
		
		CarAppear(ESkylineBallBossAttacker::LobbingCar1);
		CarAppear(ESkylineBallBossAttacker::LobbingCar2);

		Idle(0.5);

		Laser(ESkylineBallBossTopLaserSplineID::Spline3, false);

		Idle(0.5);

		ActivateActor(ESkylineBallBossAttacker::SlidingCar5);
		Idle(2.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar6);
		Idle(2.0);

		DashToPosition(ESkylineBallBossLocationNode::Laser1, 1.5);
		Laser(ESkylineBallBossTopLaserSplineID::Spline1, false);

		DashToPosition(ESkylineBallBossLocationNode::Center, 2.0);
		
		AttackMotorcycles2();
		
		DashToPosition(ESkylineBallBossLocationNode::Center, 2.0);

		DashToPosition(ESkylineBallBossLocationNode::Laser2, 1.5);
		Laser(ESkylineBallBossTopLaserSplineID::Spline4, false);

		Idle(0.0);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar1);
		Idle(1.7);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar2);
		Idle(2.5);

		AttackMotorcycles3();
	}

	void TopMioInKillWeakpoint()
	{
		Idle(2.0);
		// nothing? :3
	}

	// ---------------------
	// Attack groups

	void AttackSlidingCars1()
	{
		CarAppear(ESkylineBallBossAttacker::SlidingCar3);
		CarAppear(ESkylineBallBossAttacker::SlidingCar4);
		CarAppear(ESkylineBallBossAttacker::SlidingCar5);
		CarAppear(ESkylineBallBossAttacker::SlidingCar6);
		Idle(3.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar4);
		Idle(2.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar3);
		Idle(2.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar6);
		Idle(2.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar5);
	}

	void AttackSlidingCars2()
	{
		CarAppear(ESkylineBallBossAttacker::SlidingCar3);
		CarAppear(ESkylineBallBossAttacker::SlidingCar4);
		CarAppear(ESkylineBallBossAttacker::SlidingCar5);
		CarAppear(ESkylineBallBossAttacker::SlidingCar6);
		Idle(3.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar4);
		Idle(1.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar3);
		Idle(1.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar6);
		Idle(1.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar5);
	}

	void AttackSlidingCars3()
	{
		CarAppear(ESkylineBallBossAttacker::SlidingCar5);
		CarAppear(ESkylineBallBossAttacker::SlidingCar6);
		Idle(3.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar5);
		Idle(2.0);
		ActivateActor(ESkylineBallBossAttacker::SlidingCar6);
	}

	void AttackSmashingCars1()
	{
		ActivateActor(ESkylineBallBossAttacker::CarSmash2);
		Idle(6.0);
		ActivateActor(ESkylineBallBossAttacker::CarSmash1);
	}

	void AttackSmashingCars2()
	{
		ActivateActor(ESkylineBallBossAttacker::CarSmash2);
		Idle(2.5);
		ActivateActor(ESkylineBallBossAttacker::CarSmash1);
		Idle(2.5);
		ActivateActor(ESkylineBallBossAttacker::CarSmash2);
	}

	void AttackMotorcycles()
	{
		MotorcyclesAppear();
		Idle(2.0);
		ActivateActor(ESkylineBallBossAttacker::Bike4);
		Idle(0.3);
		ActivateActor(ESkylineBallBossAttacker::Bike1);
		Idle(0.3);
		ActivateActor(ESkylineBallBossAttacker::Bike3);
		Idle(0.3);
		ActivateActor(ESkylineBallBossAttacker::Bike2);
		Idle(0.3);
		ActivateActor(ESkylineBallBossAttacker::Bike5);
		Idle(0.3);
		ActivateActor(ESkylineBallBossAttacker::Bike7);
		Idle(0.3);
		ActivateActor(ESkylineBallBossAttacker::Bike6);
	}

	void AttackMotorcycles2()
	{
		MotorcyclesAppear();
		Idle(1.0);
		ActivateActor(ESkylineBallBossAttacker::Bike7);
		Idle(0.15);
		ActivateActor(ESkylineBallBossAttacker::Bike1);
		Idle(0.15);
		ActivateActor(ESkylineBallBossAttacker::Bike2);
		Idle(0.15);
		ActivateActor(ESkylineBallBossAttacker::Bike3);
		Idle(0.15);
		ActivateActor(ESkylineBallBossAttacker::Bike4);
		Idle(0.15);
		ActivateActor(ESkylineBallBossAttacker::Bike5);
		Idle(0.15);
		ActivateActor(ESkylineBallBossAttacker::Bike6);
	}

	void AttackMotorcycles3()
	{
		MotorcyclesAppear();
		Idle(2.0);
		ActivateActor(ESkylineBallBossAttacker::Bike3);//4
		Idle(0.5);
		ActivateActor(ESkylineBallBossAttacker::Bike2);//3
		ActivateActor(ESkylineBallBossAttacker::Bike4);//5
		Idle(0.5);
		ActivateActor(ESkylineBallBossAttacker::Bike1);//2
		ActivateActor(ESkylineBallBossAttacker::Bike5);//6
		Idle(0.5);
		ActivateActor(ESkylineBallBossAttacker::Bike7);//1
		ActivateActor(ESkylineBallBossAttacker::Bike6);//7
	}

	void AttackThrowMotorcycles()
	{
		ActivateActor(ESkylineBallBossAttacker::MotorcycleManager);
		Idle(1.0);
	}

	void AttackDetonators()
	{
		ActivateActor(ESkylineBallBossAttacker::DetonatorSpawner1);
		Idle(1.0);
		ActivateActor(ESkylineBallBossAttacker::DetonatorSpawner3);
		Idle(1.0);
		ActivateActor(ESkylineBallBossAttacker::DetonatorSpawner2);
	}

	void AttackLobbingCar1()
	{
		DashToPosition(ESkylineBallBossLocationNode::Center, 2.0);
		CarAppear(ESkylineBallBossAttacker::LobbingCar1);
		CarAppear(ESkylineBallBossAttacker::LobbingCar2);
		CarAppear(ESkylineBallBossAttacker::LobbingCar3);
		CarAppear(ESkylineBallBossAttacker::LobbingCar4);
		CarAppear(ESkylineBallBossAttacker::LobbingCar5);
		CarAppear(ESkylineBallBossAttacker::LobbingCar6);
		Idle(3.0);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar1);
		Idle(1.7);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar2);
		Idle(1.7);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar3);
		Idle(1.7);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar4);
		Idle(1.7);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar5);
		Idle(1.7);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar6);
	}

	void AttackLobbingCar2()
	{
		DashToPosition(ESkylineBallBossLocationNode::Center, 2.0);
		CarAppear(ESkylineBallBossAttacker::LobbingCar1);
		CarAppear(ESkylineBallBossAttacker::LobbingCar2);
		Idle(2.0);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar1);
		Idle(1.7);
		ActivateActor(ESkylineBallBossAttacker::LobbingCar2);
	}
	
	void LaserPattern1()
	{
		DashToPosition(ESkylineBallBossLocationNode::Laser1, 1.5);
		Laser(ESkylineBallBossTopLaserSplineID::Spline1, false);
		Idle(0.5);
		DashToPosition(ESkylineBallBossLocationNode::Laser2, 1.5);
		Laser(ESkylineBallBossTopLaserSplineID::Spline2, false);
		Idle(0.5);
		DashToPosition(ESkylineBallBossLocationNode::Laser3, 1.5);
		Laser(ESkylineBallBossTopLaserSplineID::Spline3, true);
	}

	void LaserPattern2()
	{
		DashToPosition(ESkylineBallBossLocationNode::Laser2, 1.5);
		Laser(ESkylineBallBossTopLaserSplineID::Spline4, false);
		Idle(0.5);
		DashToPosition(ESkylineBallBossLocationNode::Laser1, 1.5);
		Laser(ESkylineBallBossTopLaserSplineID::Spline5, false);
		Idle(0.5);
		DashToPosition(ESkylineBallBossLocationNode::Laser3, 1.5);
		Laser(ESkylineBallBossTopLaserSplineID::Spline6, true);
	}
	
	// ---------
	// Attack parts
	
	void ActivateActor(ESkylineBallBossAttacker AttackActor)
	{
		FSkylineBallBossActionActivateData ActionData;
		ActionData.Attacker = AttackActor;
		BossComp.ActionQueue.Queue(ActionData);
	}

	void Idle(float Duration)
	{
		FSkylineBallBossActionIdleData IdleData;
		IdleData.Duration = Duration;
		BossComp.ActionQueue.Queue(IdleData);
	}

	void MotorcyclesAppear()
	{
		BossComp.ActionQueue.Queue(FSkylineBallBossActionMotorcyclesAppearData());
	}

	void CarAppear(ESkylineBallBossAttacker Actor)
	{
		FSkylineBallBossActionCarAppearData ActionData;
		ActionData.Actor = Actor;
		BossComp.ActionQueue.Queue(ActionData);
	}

	void Laser(ESkylineBallBossTopLaserSplineID LaserID, bool bShowPanelWhenDone = false)
	{
		FSkylineBallBossActionLaserData Data;
		Data.LaserSpline = LaserID;
		Data.bDash = false;
		Data.bShowPanelWhenDone = bShowPanelWhenDone;
		BossComp.ActionQueue.Queue(Data);
	}

	UFUNCTION()
	void DashToPosition(ESkylineBallBossLocationNode Target, float Duration)
	{
		FSkylineBallBossActionPositionData Data;
		Data.DashTarget = Target;
		Data.Duration = Duration;
		BossComp.ActionQueue.Queue(Data);
	}
}
