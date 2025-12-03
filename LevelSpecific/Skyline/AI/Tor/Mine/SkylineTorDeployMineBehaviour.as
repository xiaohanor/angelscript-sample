class USkylineTorDeployMineBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(n"Attack");

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HammerComp;
	USkylineTorDeployMineComponent DeployMineComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AHazeActor Target;
	bool bLaunched;
	ASkylineTorMine Mine;
	FHazeAcceleratedVector AccMineLocation;
	float TelegraphDuration;
	float AttackDuration;
	float RecoveryDuration;
	int Amount;
	AActor CenterActor;

	float Duration = 3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		DeployMineComp = USkylineTorDeployMineComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
		CenterActor = TListedActors<ASkylineTorReferenceManager>().Single.ArenaCenter;
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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!HammerComp.bDetached)
			return false;
		if (!WantsToAttack())
			return false;
		ASkylineTorMine ExistingMine = TListedActors<ASkylineTorMine>().GetSingle();
		if(ExistingMine != nullptr)
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
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagSkylineTor::DebrisAttack, EBasicBehaviourPriority::Medium, this);

		Mine = SpawnActor(DeployMineComp.MineClass, Level = Owner.Level);
		Mine.BlockCapabilities(n"WhipDrag", this);
		Mine.AddActorCollisionBlock(this);
		Mine.ActorLocation = CenterActor.ActorLocation - FVector::UpVector * 1000;		
		AccMineLocation.SnapTo(Mine.ActorLocation);
		USkylineTorEventHandler::Trigger_OnDeployMineStart(Owner, FSkylineTorEventHandlerOnDeployMineStartData(HammerComp.Hammer, Mine));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		USkylineTorEventHandler::Trigger_OnDeployMineStop(Owner, FSkylineTorEventHandlerGeneralData(HammerComp.Hammer));

		if(Mine != nullptr)
		{
			Mine.UnblockCapabilities(n"WhipDrag", this);
			Mine.RemoveActorCollisionBlock(this);
			Mine.ActorLocation = CenterActor.ActorLocation;
			Mine.bDeployed = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(Mine == nullptr)	
			return;
		AccMineLocation.AccelerateTo(CenterActor.ActorLocation, Duration, DeltaTime);
		Mine.ActorLocation = AccMineLocation.Value;
	}
}