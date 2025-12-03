
class USkylineTorBoloAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(SkylineTorAttackTags::BoloAttack);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HammerComp;
	USkylineTorBoloComponent BoloComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;
	AHazeCharacter Character;

	private AHazePlayerCharacter Target;
	FBasicAIAnimationActionDurations Durations;
	float LaunchTime;
	int TypeIndex;

	int Attacks;
	const int MaxAttacks = 4;
	bool bEnded;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		BoloComp = USkylineTorBoloComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(HammerComp.Hammer.HammerComp.bRecall)
			return false;
		if (!HammerComp.bAttached)
			return false;
		if (HammerComp.Hammer.HammerComp.bGrabbed)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(bEnded)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimInstance.FinalizeDurations(FeatureTagSkylineTor::BoloAttack, NAME_None, Durations);
		AnimComp.RequestAction(FeatureTagSkylineTor::BoloAttack, EBasicBehaviourPriority::Medium, this, Durations);
		LaunchTime = 0;		
		bEnded = false;
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		USkylineTorEventHandler::Trigger_OnBoloAttackStart(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();	
		TypeIndex++;
		if(TypeIndex >= 6)
			TypeIndex = 0;

		Attacks++;
		if(Attacks >= MaxAttacks)
		{
			Cooldown.Set(1);
			Attacks = 0;
		}

		TargetComp.SetTarget(Target.OtherPlayer);
		USkylineTorEventHandler::Trigger_OnBoloAttackStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Target);

		if(ActiveDuration < Durations.Telegraph)
			return;

		if(Durations.IsInActionRange(ActiveDuration))
		{
			if(LaunchTime == 0)
				Launch();
		}

		if(ActiveDuration > Durations.GetTotal())
		{
			AnimComp.ClearFeature(this);
			bEnded = true;
		}
	}

	private void Launch()
	{
		ASkylineTorBolo Bolo = SpawnActor(BoloComp.BoloClass, Level = Owner.Level);
		Bolo.ProjectileComp.AdditionalIgnoreActors.Add(Owner);
		Bolo.ActorLocation = HammerComp.Hammer.ActorLocation;
		Bolo.ActorRotation = Owner.ActorForwardVector.Rotation();
		Bolo.ProjectileComp.Launcher = Owner;

		if(TypeIndex == 0)
			Bolo.Type = ESkylineTorBoloType::Propeller;
		if(TypeIndex == 1)
			Bolo.Type = ESkylineTorBoloType::Propeller;
		if(TypeIndex == 2)
			Bolo.Type = ESkylineTorBoloType::Pump;
		if(TypeIndex == 3)
			Bolo.Type = ESkylineTorBoloType::Pump;
		if(TypeIndex == 4)
			Bolo.Type = ESkylineTorBoloType::PropellerReverse;
		if(TypeIndex == 5)
			Bolo.Type = ESkylineTorBoloType::PropellerReverse;

		FVector Prediction = Target.ActorVelocity.GetSafeNormal() * 500;
		Prediction.Z *= 0.1;
		FVector TargetLocation = Target.ActorCenterLocation + Prediction;
		FVector Dir = (TargetLocation - Bolo.ActorLocation).GetSafeNormal();
		Bolo.ProjectileComp.Launch(Dir * 1250);

		LaunchTime = Time::GameTimeSeconds;

		USkylineTorEventHandler::Trigger_OnBoloAttackFire(Owner);
	}
}