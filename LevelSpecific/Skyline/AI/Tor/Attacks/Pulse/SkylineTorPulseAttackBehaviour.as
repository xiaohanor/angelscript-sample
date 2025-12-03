
class USkylineTorPulseAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(n"HammerlessAttack");
	default CapabilityTags.Add(SkylineTorAttackTags::PulseAttack);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HammerComp;
	USkylineTorHammerStealComponent HammerStealComp;
	USkylineTorPulseComponent PulseComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;
	AHazeCharacter Character;
	ASkylineTorCenterPoint CenterPoint;

	private AHazePlayerCharacter Target;
	private ASkylineTorPulse Pulse;

	float TelegraphDuration = 0.5;
	float AttackDuration;
	float RecoveryDuration;

	int Amount;

	int WaveCount;
	int WaveMax = 3;
	int LaunchedCount;
	int LaunchedMax = 4;

	float WaveTime;
	float WaveInterval = 3;
	float LaunchTime;
	float LaunchInterval = 0.25;
	float PrimeTime;
	float PrimeDuration = 0.6;
	float EndTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		PulseComp = USkylineTorPulseComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
		CenterPoint = TListedActors<ASkylineTorCenterPoint>().Single;

		HammerComp.OnAttached.AddUFunction(this, n"Attached");
	}


	UFUNCTION()
	private void Attached()
	{
		if(!IsActive())
			return;
		LaunchedCount = LaunchedMax;
		WaveCount = WaveMax;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (HammerComp.bAttached)
			return false;
		if (HammerComp.Hammer.HammerComp.bRecall)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (Target.IsPlayerDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AnimComp.RequestFeature(FeatureTagSkylineTor::PulseAttack, EBasicBehaviourPriority::Medium, this);
		WaveTime = 0;
		WaveCount = 0;
		LaunchTime = 0;		
		PrimeTime = 0;
		EndTime = 0;
		LaunchedCount = 0;
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		HammerStealComp = USkylineTorHammerStealComponent::GetOrCreate(HammerComp.Hammer);

		PulseComp.bSpawningPulses = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();	
		if(Pulse != nullptr)
			Pulse.ProjectileComp.Expire();

		PulseComp.bSpawningPulses = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter MainTarget;
		if(HammerStealComp.bEnableShieldBreak)
			MainTarget = Game::Zoe;
		else
			MainTarget = Game::Mio;

		if(Target != MainTarget && TargetComp.IsValidTarget(MainTarget))
		{
			TargetComp.SetTarget(MainTarget);
			Cooldown.Set(0.5);
			return;
		}

		if(Target == MainTarget && !TargetComp.IsValidTarget(MainTarget))
		{
			TargetComp.SetTarget(MainTarget.OtherPlayer);
			Cooldown.Set(0.5);
			return;
		}

		FVector TargetLocation = CenterPoint.ActorLocation + (CenterPoint.ActorLocation - Target.ActorLocation).GetSafeNormal2D() * 500;
		if(Owner.ActorLocation.Dist2D(TargetLocation) > 250)
			DestinationComp.MoveTowardsIgnorePathfinding(TargetLocation, 750);
		DestinationComp.RotateTowards(Target);
		AnimComp.RequestSubFeature(NAME_None, this);

		if(EndTime > 0)
		{
			if(Time::GetGameTimeSince(EndTime) > 1)
				Cooldown.Set(2);
			return;
		}

		if(WaveTime > 0)
		{
			if(Time::GetGameTimeSince(WaveTime) > WaveInterval)
			{
				WaveTime = 0;
				LaunchTime = 0;
				LaunchedCount = 0;
				PrimeTime = 0;

				USkylineTorEventHandler::Trigger_OnPulseAttackStartNewWave(Owner);
			}
			return;
		}

		if(ActiveDuration < TelegraphDuration)
			return;

		if(PrimeTime == 0)
		{
			if(LaunchTime == 0 || Time::GetGameTimeSince(LaunchTime) > LaunchInterval)
				Prime();
		}
		else if(Time::GetGameTimeSince(PrimeTime) > PrimeDuration)
			Launch();

		if(Pulse != nullptr)
		{
			Pulse.ActorRotation = (Target.ActorCenterLocation - Pulse.ActorLocation).Rotation();
		}
	}

	private void Prime()
	{
		Pulse = SpawnActor(PulseComp.PulseClass, Level = Owner.Level);
		Pulse.TorBoss = Cast<ASkylineTor>(Owner);
		Pulse.ProjectileComp.AdditionalIgnoreActors.Add(Owner);
		Pulse.AttachToComponent(PulseComp);
		Pulse.ActorLocation = PulseComp.WorldLocation + PulseComp.ForwardVector * 100;
		Pulse.ActorRotation = Owner.ActorForwardVector.Rotation();
		Pulse.ProjectileComp.Prime();
		PrimeTime = Time::GameTimeSeconds;
		USkylineTorEventHandler::Trigger_OnPulseAttackPrime(Owner);
	}

	private void Launch()
	{
		FVector TargetLocation = Target.ActorCenterLocation + Target.ActorVelocity.GetSafeNormal() * 400;
		FVector Dir = (TargetLocation - Pulse.ActorLocation).GetSafeNormal();
		Pulse.DetachFromActor();
		Pulse.ProjectileComp.Launch(Dir * 400);
		Pulse = nullptr;

		LaunchTime = Time::GameTimeSeconds;
		PrimeTime = 0;
		AnimComp.RequestSubFeature(SubTagSkylineTorPulseAttack::Fire, this);
		USkylineTorEventHandler::Trigger_OnPulseAttackFire(Owner);

		LaunchedCount++;

		if(LaunchedCount >= LaunchedMax)
		{
			WaveCount++;
			WaveTime = Time::GameTimeSeconds; 
		}

		if(WaveCount >= WaveMax || HammerComp.Hammer.HammerComp.bRecall)
			EndTime = Time::GameTimeSeconds;
	}
}