class USkylineTorDebrisRainAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(n"Attack");

	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HammerComp;
	USkylineTorDebrisComponent DebrisComp;
	USkylineTorCooldownComponent CooldownComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;
	AActor CenterActor;

	private AHazeActor Target;
	private TArray<ASkylineTorRainDebris> AllDebris;

	FBasicAIAnimationActionDurations Durations;

	int Amount;
	float DelayAttackTime;
	bool bSpawned;
	bool bLaunched;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		DebrisComp = USkylineTorDebrisComponent::GetOrCreate(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
		CenterActor = TListedActors<ASkylineTorReferenceManager>().Single.ArenaCenter;
		DelayAttackTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())
			return;
		if(DelayAttackTime > 0)
			return;
		if(TListedActors<ASkylineTorRainDebris>().GetArray().Num() > 3)
			return;
		DelayAttackTime = Time::GameTimeSeconds;
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if(DelayAttackTime == 0)
			return false;
		if(Time::GetGameTimeSince(DelayAttackTime) < 3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimInstance.FinalizeDurations(FeatureTagSkylineTor::RainDebrisAttack, NAME_None, Durations);
		AnimComp.RequestAction(FeatureTagSkylineTor::RainDebrisAttack, EBasicBehaviourPriority::Medium, this, Durations);
		bSpawned = false;
		bLaunched = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();	
		LaunchDebris();
		AllDebris.Empty();
		DelayAttackTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < Durations.Telegraph)
			return;

		if(!bSpawned)
		{
			bSpawned = true;
			SpawnDebris();
		}

		if(Durations.IsInActionRange(ActiveDuration))
		{
			LaunchDebris();
		}
	}

	private void LaunchDebris()
	{
		if (bLaunched)
			return;
		bLaunched = true;
		for(ASkylineTorRainDebris Debris : AllDebris)
			Debris.ProjectileComp.Launch(FVector::DownVector * 2500);
		USkylineTorEventHandler::Trigger_OnRainDebrisTelegraphStop(Owner, FSkylineTorEventHandlerGeneralData(HammerComp.Hammer));
	}

	private void SpawnDebris()
	{
		float Height = 2000;
		float DistanceFromCenter = 1000;
		float DistanceRandomization = 250;

		Amount = 6 - TListedActors<ASkylineTorRainDebris>().GetArray().Num();

		TArray<FVector> SpawnLocations;
		for(int i = 0; i < Amount; i++)
		{
			FVector Location;
			if(i == 0)
			{
				Location = Game::Mio.ActorLocation;
				Location.Z = CenterActor.ActorLocation.Z;
			}
			else if(i == 1)
			{
				Location = Game::Zoe.ActorLocation;
				Location.Z = CenterActor.ActorLocation.Z;
			}
			else
			{
				float Angle = 360.0 * (i / 5.0);
				FVector Dir = FVector::ForwardVector.RotateAngleAxis(Angle, FVector::UpVector);
				float Range = DistanceFromCenter + Math::RandRange(-DistanceRandomization, DistanceRandomization);
				Location = CenterActor.ActorLocation + Dir * Range;
			}

			FVector UpOffset = FVector::UpVector * Height;
			FVector DownOffset = FVector::UpVector * 500;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(Location + UpOffset, Location - DownOffset);
			if(Hit.bBlockingHit)
				Location = Hit.ImpactPoint;
			else
				continue;

			FVector SpawnLocation = Location + UpOffset * Math::RandRange(0.75, 1);
			ASkylineTorRainDebris Debris = SpawnActor(DebrisComp.RainDebrisClass, Level = Owner.Level);
			Debris.ProjectileComp.AdditionalIgnoreActors.Add(Owner);
			Debris.ActorLocation = SpawnLocation;
			Debris.TargetLandLocation = Location;
			Debris.ProjectileComp.Prime();
			AllDebris.Add(Debris);
			SpawnLocations.Add(SpawnLocation);
		}

		USkylineTorEventHandler::Trigger_OnRainDebrisTelegraphStart(Owner, FSkylineTorEventHandlerOnRainDebrisTelegraphStartData(HammerComp.Hammer, SpawnLocations));
	}
}