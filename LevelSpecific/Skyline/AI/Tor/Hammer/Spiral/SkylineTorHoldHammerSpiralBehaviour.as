
class USkylineTorHoldHammerSpiralBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(SkylineTorAttackTags::HammerSpiralAttack);

	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorBehaviourComponent TorBehaviourComp;
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorTargetingComponent TorTargetingComp;
	USkylineTorHoverComponent HoverComp;
	USkylineTorDamageComponent DamageComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AActor CenterActor;
	private AHazePlayerCharacter Target;
	private AHazeCharacter Character;
	FBasicAIAnimationActionDurations Durations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		TorBehaviourComp = USkylineTorBehaviourComponent::GetOrCreate(Owner);
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		TorTargetingComp = USkylineTorTargetingComponent::GetOrCreate(Owner);
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);
		DamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);

		CenterActor = TListedActors<ASkylineTorReferenceManager>().Single.ArenaCenter;
		AnimComp.bIsAiming = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(TorBehaviourComp.bIgnoreActivationRequirements)
			return true;
		if (Super::ShouldActivate() == false)
			return false;
		if (HoldHammerComp.bDetached)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(HoldHammerComp.Hammer.VolleyComp.bLanded)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AnimInstance.FinalizeDurations(FeatureTagSkylineTor::HammerSpiral, NAME_None, Durations);
		AnimComp.RequestAction(FeatureTagSkylineTor::HammerSpiral, EBasicBehaviourPriority::Medium, this, Durations);

		TargetComp.SetTarget(Game::Zoe);
		if(!TargetComp.HasValidTarget())
			TargetComp.SetTarget(Game::Mio);

		if(!TargetComp.HasValidTarget())
			DeactivateBehaviour();

		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		DamageComp.bDisableRecoil.Apply(true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		TargetComp.SetTarget(Game::Zoe);
		HoverComp.ClearHover(this);
		DamageComp.bDisableRecoil.Clear(this);
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Target);

		if(HoldHammerComp.bDetached)
			return;

		if(Durations.IsInActionRange(ActiveDuration))
		{
			HoldHammerComp.Hammer.TargetingComponent.SetTarget(Target);
			USkylineTorHammerSpiralComponent::GetOrCreate(HoldHammerComp.Hammer).TargetLocation = TorTargetingComp.GetPlayerLocation(Target);
			HoldHammerComp.Detach(ESkylineTorHammerMode::Spiral);
			USkylineTorEventHandler::Trigger_OnHoldHammerSpiralThrow(Owner, FSkylineTorEventHandlerGeneralData());
			HoverComp.StopHover(this);
			return;
		}

		if(PhaseComp.Phase != ESkylineTorPhase::Grounded && PhaseComp.Phase != ESkylineTorPhase::Hovering)
			return;

		if(Owner.ActorLocation.IsWithinDist(Target.ActorLocation, 1700))
		{
			FVector Dir = (CenterActor.ActorLocation - Target.ActorLocation).GetSafeNormal2D();
			DestinationComp.MoveTowards(Target.ActorLocation + Dir * 2200, 1500);
			HoverComp.StartHover(this);
			USkylineTorSettings::SetHoverHeight(Owner, 50, this);
			USkylineTorSettings::SetHoverMinHeight(Owner, 25, this);
		}
	}
}