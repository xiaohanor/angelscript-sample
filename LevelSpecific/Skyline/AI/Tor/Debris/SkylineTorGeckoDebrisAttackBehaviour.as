class USkylineTorGeckoDebrisAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(n"Attack");

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HammerComp;
	USkylineTorDebrisComponent DebrisComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AHazeActor Target;
	bool bLaunched;
	ESkylineTorDebrisAttackMode Mode;
	TArray<FSkylineTorDebrisAttackDebrisData> DebrisData;

	float TelegraphDuration;
	float AttackDuration;
	float RecoveryDuration;
	int Amount;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		DebrisComp = USkylineTorDebrisComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		// if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.HammerImpactMinAttackRange))
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;
		// if(!GentCostQueueComp.IsNext(this) && (Settings.HammerImpactGentlemanCost != EGentlemanCost::None))
		// 	return false;
		// if(!GentCostComp.IsTokenAvailable(Settings.HammerImpactGentlemanCost))
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		// if(ActiveDuration > TelegraphDuration + AttackDuration + RecoveryDuration)
		// 	return true;
		if(ActiveDuration > 5)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagSkylineTor::DebrisAttack, EBasicBehaviourPriority::Medium, this);
		
		Amount = 1;
		if(Mode == ESkylineTorDebrisAttackMode::Multi)
			Amount = 3;

		DebrisData.Empty();
		for(int i = 0; i < Amount; i++)
		{
			FSkylineTorDebrisAttackDebrisData Data;

			FVector2D Offset = FVector2D::ZeroVector;
			if(Amount > 1)
			{
				if(i == 0)
					Offset = FVector2D(0, 1.5) * 100;
				if(i == 1)
					Offset = FVector2D(-1, 0) * 100;
				if(i == 2)
					Offset = FVector2D(1, 0) * 100;
			}

			ASkylineTorDebris Debris = SpawnActor(DebrisComp.DebrisClass, Level = Owner.Level);
			Debris.ProjectileComp.AdditionalIgnoreActors.Add(Owner);
			Debris.ActorLocation = (Owner.ActorLocation + Owner.ActorForwardVector * 5000) + (Owner.ActorRightVector * Data.Offset.X) + (Owner.ActorUpVector * Data.Offset.Y);
			Debris.WhipResponse.OnGrabbed.AddUFunction(this, n"Grabbed");

			Data.Offset = Offset;
			Data.Debris = Debris;
			Data.AccDebrisLocation.SnapTo(Debris.ActorLocation);
			DebrisData.Add(Data);
		}
		bLaunched = false;
	}

	UFUNCTION()
	private void Grabbed(UGravityWhipUserComponent UserComponent,
	                     UGravityWhipTargetComponent TargetComponent,
	                     TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		FSkylineTorDebrisAttackDebrisData Remove;
		for(FSkylineTorDebrisAttackDebrisData& Data : DebrisData)
		{
			if(Data.Debris != TargetComponent.Owner)
				continue;
			Remove = Data;
			break;
		}
		
		DebrisData.Remove(Remove);
		if(DebrisData.Num() > 0)
			return;

		bLaunched = true;
		DeactivateBehaviour();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		for(FSkylineTorDebrisAttackDebrisData Data : DebrisData)
			Data.Debris.WhipResponse.OnGrabbed.UnbindObject(this);
		if(!bLaunched)
			Launch();
		
		if(Mode == ESkylineTorDebrisAttackMode::Single)
			Mode = ESkylineTorDebrisAttackMode::Multi;
		else
			Mode = ESkylineTorDebrisAttackMode::Single;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TargetComp.Target);

		if(ActiveDuration < 1)
			return;

		if(bLaunched)
			return;
		
		for(FSkylineTorDebrisAttackDebrisData& Data : DebrisData)
		{
			Data.AccDebrisLocation.SpringTo(DebrisComp.WorldLocation + (Owner.ActorRightVector * Data.Offset.X) + (Owner.ActorUpVector * Data.Offset.Y), 75, 0.7, DeltaTime);
			Data.Debris.ActorLocation = Data.AccDebrisLocation.Value;
		}

		if(ActiveDuration < 4)
			return;

		Launch();
	}

	private void Launch()
	{
		for(FSkylineTorDebrisAttackDebrisData& Data : DebrisData)
		{
			FVector Dir = ((TargetComp.Target.ActorCenterLocation + (Owner.ActorRightVector * Data.Offset.X) + (Owner.ActorUpVector * Data.Offset.Y)) - Data.Debris.ActorLocation).GetSafeNormal();
			Data.Debris.ProjectileComp.Launch(Dir * 1500);
			Data.Debris.bStopHoming = true;
		}
		bLaunched = true;
	}
}