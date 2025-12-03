class USkylineTorEjectAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(SkylineTorAttackTags::EjectAttack);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HammerComp;
	USkylineTorEjectComponent EjectComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	USkylineTorEjectPlayerComponent PlayerEjectComp;
	private ASkylineTorCenterPoint CenterPoint;
	private AHazeCharacter Character;
	float TelegraphDuration = 1;
	float ActionDuration = 1.5;
	float RecoveryDuration = 1.5;

	float ArenaRadius;
	float GrabTime;
	float EjectTime;
	bool bAtLocation;

	TArray<ASkylineTorEjectPoint> EjectPoints;
	ASkylineTorEjectPoint EjectPoint;

	UFUNCTION(BlueprintOverride)
	void Setup() 
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		EjectComp = USkylineTorEjectComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
		EjectPoints = TListedActors<ASkylineTorEjectPoint>().GetArray();
		CenterPoint = TListedActors<ASkylineTorCenterPoint>().Single;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!HammerComp.Hammer.StealComp.bShieldBroken)
			return false;
		if (Game::Mio.ActorLocation.Dist2D(CenterPoint.ActorLocation) > CenterPoint.ArenaRadius + 100)
			return false;
		if (PlayerEjectComp != nullptr && PlayerEjectComp.bEjected)
			return false;
		if (!HammerComp.bDetached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(EjectComp.PlayerTarget.IsPlayerDead())
			return true;
		if(EjectTime > 0 && Time::GetGameTimeSince(EjectTime) > RecoveryDuration)
			return true;
		if(!HammerComp.Hammer.StealComp.bShieldBroken)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TargetComp.SetTargetLocal(Game::Mio);
		EjectComp.PlayerTarget = Game::Mio;

		AnimComp.RequestFeature(FeatureTagSkylineTor::EjectAttack, SubTagSkylineTorEjectAttack::Pull, EBasicBehaviourPriority::Medium, this);
	
		PlayerEjectComp = USkylineTorEjectPlayerComponent::GetOrCreate(EjectComp.PlayerTarget);
		PlayerEjectComp.CenterActor = CenterPoint;
		PlayerEjectComp.PlayerGrabbedAnim = EjectComp.PlayerGrabbedAnim;
		bAtLocation = false;
		GrabTime = 0;
		EjectTime = 0;

		float ClosestPoint = BIG_NUMBER;
		for(ASkylineTorEjectPoint Point : EjectPoints)
		{
			float PointDistance = Point.GetDistanceTo(Owner);
			if(Point.GetDistanceTo(Owner) > ClosestPoint)
				continue;
			
			EjectPoint = Point;
			ClosestPoint = PointDistance;
		}

		USkylineTorEventHandler::Trigger_OnEjectAttackStart(Owner, FSkylineTorEventHandlerOnEjectAttackData(HammerComp.Hammer, EjectComp.PlayerTarget));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnEjectAttackStop(Owner, FSkylineTorEventHandlerOnEjectAttackData(HammerComp.Hammer, EjectComp.PlayerTarget));

		if(PlayerEjectComp != nullptr) // If we deactivate before setting PlayerEjectComp in OnActivated, this will be nullptr
			PlayerEjectComp.Release();

		if(EjectComp.PlayerTarget != nullptr)
		{
			EjectComp.PlayerTarget.StopButtonMash(this);
			TargetComp.SetTarget(EjectComp.PlayerTarget.OtherPlayer);
		}
		Cooldown.Set(3);
		EjectComp.AllowEjectAttack = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Cooldown.IsSet())
			return;

		if(EjectTime > SMALL_NUMBER)
			return;

		if (EjectComp.PlayerTarget == nullptr)
			return;

		if(!PlayerEjectComp.bEjected)
			USkylineTorEventHandler::Trigger_OnEjectAttackUpdate(Owner, FSkylineTorEventHandlerOnEjectAttackData(HammerComp.Hammer, EjectComp.PlayerTarget));
			
		FVector Dir = (EjectPoint.ActorLocation - CenterPoint.ActorLocation).GetSafeNormal2D();
		if(PlayerEjectComp.bGrabbed)
			DestinationComp.RotateTowards(EjectPoint);
		else
			DestinationComp.RotateTowards(TargetComp.Target);

		if(!bAtLocation)
		{
			FVector TargetLocation = CenterPoint.ActorLocation + Dir * 500;
			float Speed = 1000 * Math::Clamp(Owner.ActorLocation.Dist2D(TargetLocation) / 500, 0.1, 1);
			DestinationComp.MoveTowardsIgnorePathfinding(TargetLocation, Speed);
			if(TargetLocation.Dist2D(Owner.ActorLocation) < 50)
				bAtLocation = true;
		}

		if(ActiveDuration > TelegraphDuration && !PlayerEjectComp.bGrabbed)
		{
			PlayerEjectComp.Grab(Owner);
			GrabTime = Time::GameTimeSeconds;
			
			FButtonMashSettings ButtonMashSettings;
			ButtonMashSettings.Duration = 1;
			ButtonMashSettings.Difficulty = EButtonMashDifficulty::Easy;
			ButtonMashSettings.bAllowPlayerCancel = false;
			ButtonMashSettings.Mode = EButtonMashMode::ButtonMash;
			ButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;

			FOnButtonMashCompleted CompletedMash;
			CompletedMash.BindUFunction(this, n"MashCompleted");
			EjectComp.PlayerTarget.StartButtonMash(ButtonMashSettings, this, CompletedMash, CompletedMash);
		}

		if(PlayerEjectComp.bGrabbed)
		{
			EjectComp.PlayerTarget.DealBatchedDamageOverTime(0.25 * DeltaTime, FPlayerDeathDamageParams(), EjectComp.DamageEffect, EjectComp.DeathEffect);
			USkylineTorEventHandler::Trigger_OnEjectAttackDamage(Owner, FSkylineTorEventHandlerOnEjectAttackData(HammerComp.Hammer, EjectComp.PlayerTarget));
		}
	}

	UFUNCTION()
	private void MashCompleted()
	{
		PlayerEjectComp.Eject();
		USkylineTorEventHandler::Trigger_OnEjectAttackEject(Owner, FSkylineTorEventHandlerOnEjectAttackData(HammerComp.Hammer, EjectComp.PlayerTarget));
		EjectTime = Time::GameTimeSeconds;
		EjectComp.PlayerTarget.StopButtonMash(this);
		AnimComp.RequestSubFeature(SubTagSkylineTorEjectAttack::Eject, this);
	}
}