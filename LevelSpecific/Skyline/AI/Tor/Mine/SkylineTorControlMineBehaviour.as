class USkylineTorControlMineBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(n"Attack");

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorDeployMineComponent DeployMineComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	ASkylineTorMine Mine;
	FHazeAcceleratedVector AccMineLocation;
	float TelegraphDuration;
	float AttackDuration;
	float RecoveryDuration;
	AActor CenterActor;
	float Duration = 3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		DeployMineComp = USkylineTorDeployMineComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
		CenterActor = TListedActors<ASkylineTorReferenceManager>().Single.ArenaCenter;
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!HoldHammerComp.bDetached)
			return false;
		if (!WantsToAttack())
			return false;
		ASkylineTorMine ExistingMine = TListedActors<ASkylineTorMine>().GetSingle();
		if(ExistingMine == nullptr)
			return false;
		if(ExistingMine.MineComp.bGrabbed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(Mine == nullptr)
			return true;
		if(Mine.MineComp.bGrabbed)
			return true;
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagSkylineTor::DebrisAttack, EBasicBehaviourPriority::Medium, this);
		Mine = TListedActors<ASkylineTorMine>().GetSingle();
		Mine.MineComp.bControlled = true;
		USkylineTorEventHandler::Trigger_OnControlMineStart(Owner, FSkylineTorEventHandlerOnControlMineStartData(HoldHammerComp.Hammer, Mine));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		Mine.MineComp.bControlled = false;
		Mine.MineComp.bHasTargetLocation = false;
		USkylineTorEventHandler::Trigger_OnControlMineStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Mine == nullptr)
			return;

		// We should be live updating the target, keep that in mind when networking
		Mine.MineComp.MoveTowards(TargetComp.Target.ActorLocation, 2);
		DestinationComp.RotateTowards(Mine);
	}
}