struct FCritterLatchOnParams
{
	FName LatchOnSocket = NAME_None;
}

class USummitKnightCritterLatchOnBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UBasicAIHealthComponent HealthComp;
	USummitKnightCritterSettings Settings;
	FName Socket;
	AHazePlayerCharacter PlayerTarget;
	UCritterLatchOnComponent PlayerLatchComp;
	USummitCritterComponent CritterComp;
	float KillTime;
	float DamageTime;
	FHazeAcceleratedVector AccLatchOnLocation;
	float DamageInterval = 1.0;
	bool bWasLatchedOn = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightCritterSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		CritterComp = USummitCritterComponent::GetOrCreate(Owner);
		auto AnimInstance = Cast<UAnimInstanceSummitClimbingCritter>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
		DamageInterval = AnimInstance.GrabMh.Sequence.PlayLength;
		PlayerTarget = Game::Zoe;
		PlayerLatchComp = UCritterLatchOnComponent::GetOrCreate(Game::Zoe);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!TargetComp.IsValidTarget(PlayerTarget))
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(PlayerTarget.ActorCenterLocation, Settings.LatchOnAttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCritterLatchOnParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToAttack())
			return false;
		FName LatchOnSocket = PlayerLatchComp.GetBestFreeSocket(Owner.ActorCenterLocation);
		if (LatchOnSocket.IsNone())
			return false;
		OutParams.LatchOnSocket = LatchOnSocket;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		// Until death do us part! 
		if (PlayerTarget.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCritterLatchOnParams Params)
	{
		Super::OnActivated();
		bWasLatchedOn = false;
		Socket = Params.LatchOnSocket;
		if (Socket.IsNone())
		{
			Cooldown.Set(2.0);
		}
		else
		{
			PlayerLatchComp.LatchOn(Owner, Socket);
			CritterComp.LatchOn(PlayerTarget, Socket);
			TArray<FName> GrabVars;
			GrabVars.Add(SummitClimbingCritterSubTags::GrabEnterVar1);
			GrabVars.Add(SummitClimbingCritterSubTags::GrabEnterVar2);
			GrabVars.Add(SummitClimbingCritterSubTags::GrabEnterVar3);
			FName GrabVar = GrabVars[Math::RandRange(0, GrabVars.Num() - 1)];
			AnimComp.RequestFeature(FeatureTagClimbingCritter::Grab, GrabVar, EBasicBehaviourPriority::Medium, this);
		}

		PlayerTarget.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonRoll, this);

		KillTime = BIG_NUMBER;
		DamageTime = BIG_NUMBER;
		USummitKnightCritterEventhandler::Trigger_OnStartAttack(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		PlayerLatchComp.Release(Owner);
		CritterComp.ClearLatchOn();
		if (Owner.AttachParentActor != nullptr)
		{
			Owner.DetachFromActor(EDetachmentRule::KeepWorld);
			Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		}
		Owner.ClearSettingsByInstigator(this);

		if (PlayerTarget.IsPlayerDead())
		{
			// Kamikaze!
			HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Default, Owner);
		}
		PlayerTarget.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonRoll, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!CritterComp.bLatchOnComplete)
		{
			CritterComp.LatchOnMove(Settings.LatchOnAttackSpeed);
		}
		else if (!bWasLatchedOn)
		{
			bWasLatchedOn = true;
			PlayerLatchComp.LatchOnComplete(Owner); 
			if (Settings.LatchOnKillDuration >= 0.0)
				KillTime = ActiveDuration + Settings.LatchOnKillDuration;
			DamageTime = ActiveDuration + DamageInterval * 0.5; // We could place an animnotify fro this, but meh
			USummitKnightCritterEventhandler::Trigger_OnLatchOnToPlayer(Owner);		
		}

		// Kill player when grabbed for long enough
		if (ActiveDuration > KillTime)
		{
			PlayerTarget.DealTypedDamage(Owner, 1.0, EDamageEffectType::ObjectSharp, EDeathEffectType::ObjectSharp, false);
			KillTime = BIG_NUMBER;
			USummitKnightCritterEventhandler::Trigger_OnKillPlayer(Owner);		
		}

		if (ActiveDuration > DamageTime)
		{
			PlayerTarget.DealTypedDamage(Owner, Settings.LatchOnDamagePerSecond * DamageInterval, EDamageEffectType::ObjectSharp, EDeathEffectType::ObjectSharp, false);
			DamageTime += DamageInterval;
			USummitKnightCritterEventhandler::Trigger_OnPlayerDamage(Owner, FSummitKnightCritterDamagePlayerParams(PlayerTarget));			
		}

		float FFFrequency = 5.0;
		float FFIntensity = 0.05;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
		PlayerTarget.SetFrameForceFeedback(FF);
	}
}

