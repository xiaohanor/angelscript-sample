struct FSkylineTorHoldHammerVolleyBehaviourParams
{
	AHazePlayerCharacter Target;
	FVector TargetLocation;
}

class USkylineTorHoldHammerVolleyBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(SkylineTorAttackTags::HammerVolleyAttack);

	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorBehaviourComponent TorBehaviourComp;
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorTargetingComponent TorTargetingComp;
	USkylineTorEjectComponent EjectComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AActor CenterActor;
	private AHazePlayerCharacter Target;
	private AHazeCharacter Character;
	FBasicAIAnimationActionDurations Durations;
	bool bHasDetached;
	int AttackIndex;

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
		EjectComp = USkylineTorEjectComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);

		CenterActor = TListedActors<ASkylineTorReferenceManager>().Single.ArenaCenter;
		AnimComp.bIsAiming = true;

		AttackIndex = TorBehaviourComp.GetNewAttackIndex(Outer.Name);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineTorHoldHammerVolleyBehaviourParams& OutParams) const
	{
		if(TorBehaviourComp.bIgnoreActivationRequirements)
			return true;
		if (Super::ShouldActivate() == false)
			return false;
		if(AttackIndex != TorBehaviourComp.GetAttackIndex(Outer.Name))
			return false;
		if(HoldHammerComp.bDetached)
			return false;
		if(HoldHammerComp.Hammer.HammerComp.bGrabbed)
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		OutParams.Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		OutParams.TargetLocation = TorTargetingComp.GetPlayerLocation(OutParams.Target);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	private bool HasHammerReturned() const
	{
		if(!HoldHammerComp.bAttached)
			return false;
		if(!bHasDetached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineTorHoldHammerVolleyBehaviourParams Params)
	{
		Super::OnActivated();
		bHasDetached = false;

		AnimInstance.FinalizeDurations(FeatureTagSkylineTor::HammerVolley, NAME_None, Durations);
		AnimComp.RequestAction(FeatureTagSkylineTor::HammerVolley, EBasicBehaviourPriority::Medium, this, Durations);

		if(Params.Target != Game::Zoe && TargetComp.IsValidTarget(Game::Zoe))
		{
			DeactivateBehaviour();
			return;
		}

		USkylineTorHammerEventHandler::Trigger_OnVolleyTelegraphStart(HoldHammerComp.Hammer, FSkylineTorHammerOnVolleyTelegraphStartData(Params.Target.ActorLocation));
		Target = Params.Target;
		EjectComp.AllowEjectAttack = true;

		USkylineTorHammerVolleyComponent::GetOrCreate(HoldHammerComp.Hammer).TargetLocation = Params.TargetLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		TargetComp.SetTarget(Game::Zoe);
		if(HoldHammerComp.bDetached)
			TorBehaviourComp.IncrementAttackIndex(Outer.Name);
		USkylineTorHammerEventHandler::Trigger_OnVolleyTelegraphStop(HoldHammerComp.Hammer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Target == nullptr)
			return;

		DestinationComp.RotateTowards(Target);

		if(HoldHammerComp.bDetached)
			return;

		if(Durations.IsInActionRange(ActiveDuration))
		{
			HoldHammerComp.Hammer.TargetingComponent.SetTarget(Target);
			HoldHammerComp.Detach(ESkylineTorHammerMode::Volley);
			USkylineTorEventHandler::Trigger_OnHoldHammerVolleyThrow(Owner, FSkylineTorEventHandlerGeneralData());
			bHasDetached = true;
			return;
		}

		if(PhaseComp.Phase != ESkylineTorPhase::Grounded && PhaseComp.Phase != ESkylineTorPhase::Hovering)
			return;

		if(Owner.ActorLocation.IsWithinDist(Target.ActorLocation, 1000))
		{
			FVector Dir = (CenterActor.ActorLocation - Target.ActorLocation).GetSafeNormal2D();
			DestinationComp.MoveTowards(Target.ActorLocation + Dir * 1500, 1500);
		}
	}
}