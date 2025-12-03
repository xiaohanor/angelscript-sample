class USummitClimbingCritterLatchOnBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UBasicAIHealthComponent HealthComp;
	USummitClimbingCritterSettings Settings;
	FName Socket;
	AHazePlayerCharacter PlayerTarget;
	UCritterLatchOnComponent LatchComp;
	float KillTime;
	float DamageWarningTime;
	FHazeAcceleratedVector AccLatchOnLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitClimbingCritterSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		// We really want to be on tail dragon rider control side for this
		Owner.SetActorControlSide(Game::Zoe);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.LatchOnAttackRange))
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
		auto LatchOnComp = UCritterLatchOnComponent::Get(TargetComp.Target);	
		if (LatchOnComp == nullptr)
			return false;
		FName LatchOnSocket = LatchOnComp.GetBestFreeSocket(Owner.ActorCenterLocation);
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
		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		LatchComp = UCritterLatchOnComponent::GetOrCreate(PlayerTarget);
		Socket = Params.LatchOnSocket;
		if (Socket.IsNone())
		{
			Cooldown.Set(2.0);
		}
		else
		{
			LatchComp.LatchOn(Owner, Socket);
			AnimComp.RequestFeature(FeatureTagClimbingCritter::Grab, SummitClimbingCritterSubTags::GrabEnter, EBasicBehaviourPriority::Medium, this);
		}
		KillTime = BIG_NUMBER;
		DamageWarningTime = BIG_NUMBER;
		AnimHackTime = BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		LatchComp.Release(Owner);
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// TODO: All of this should be replaced by animation probably
		if (ActiveDuration == 0)
		{
			UHazeCharacterSkeletalMeshComponent DragonMesh =  UPlayerTailTeenDragonComponent::Get(PlayerTarget).DragonMesh;
			FVector SocketLoc = DragonMesh.GetSocketLocation(Socket);
			DestinationComp.MoveTowardsIgnorePathfinding(SocketLoc, Settings.LatchOnAttackSpeed);

			// Time to latch on?
			if (SocketLoc.IsWithinDist(Owner.ActorLocation, Settings.LatchOnAttackSpeed))
			{
				Owner.AttachToComponent(DragonMesh, Socket, EAttachmentRule::KeepWorld);
				Owner.BlockCapabilities(CapabilityTags::Movement, this);
				UMovementGravitySettings::SetGravityScale(Owner, 0.0, this, EHazeSettingsPriority::Gameplay);
				KillTime = Time::GameTimeSeconds + Settings.LatchOnKillDuration;
				DamageWarningTime = Time::GameTimeSeconds + Settings.LatchOnDamageWarningInterval;
				FVector SocketLocalVelocity = DragonMesh.GetSocketTransform(Socket).InverseTransformVector(Owner.ActorVelocity);
				AccLatchOnLocation.SnapTo(Owner.RootComponent.RelativeLocation, SocketLocalVelocity);
				LatchComp.LatchOnComplete(Owner);
			}
			else if (ActiveDuration > Settings.LatchOnMissDuration)
			{
				// We've missed
				Cooldown.Set(2.0);
			}
			return;
		}

		// We've grabbed on to target
		AccLatchOnLocation.SpringTo(FVector::ZeroVector, 20.0, 0.4, DeltaTime);
		FHitResult Dummy;
		Owner.SetActorRelativeLocation(AccLatchOnLocation.Value, false, Dummy, false);

		// Kill player when grabbed for long enough
		if (Time::GameTimeSeconds > KillTime)
		{
			PlayerTarget.DamagePlayerHealth(1.0);
			KillTime = BIG_NUMBER;
		}

		if (Time::GameTimeSeconds > DamageWarningTime)
		{
			USummitClimbingCritterEventHandler::Trigger_OnPlayerDamage(Owner, FSummitClimbingCritterDamagePlayerParams(PlayerTarget));
			DamageWarningTime += Settings.LatchOnDamageWarningInterval;
		}
	}

	float AnimHackTime = BIG_NUMBER; // Remove this when you have proper attack anim mh
}

