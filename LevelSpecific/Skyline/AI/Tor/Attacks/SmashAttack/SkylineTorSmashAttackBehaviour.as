struct FSkylineTorSmashAttackBehaviourParams
{
	FVector AttackLocation;
	TArray<FVector> HammerAttackLocations;
}

class USkylineTorSmashAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(SkylineTorAttackTags::SmashAttack);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorCooldownComponent CooldownComp;
	USkylineTorDamageComponent DamageComp;
	USkylineTorSmashComponent SmashComp;
	USkylineTorHoverComponent HoverComp;
	USkylineTorBehaviourComponent TorBehaviourComp;
	USkylineTorHammerVolleyComponent VolleyComp;

	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;
	private AHazeCharacter Character;
	private AActor CenterActor;

	FBasicAIAnimationActionDurations Durations;

	bool bLanding;
	bool bTelegraping;
	bool bAction;
	bool bAtLocation;
	bool bStarted;
	float ActiveTimer;
	int Attacks;
	AHazeActor Target;

	FVector PreviousHammerDamageLocation;
	TArray<AHazeActor> HitTargets;
	int AttackIndex;

	FVector AttackLocation;
	TArray<FVector> RandomizedTargetLocations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		DamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);
		SmashComp = USkylineTorSmashComponent::GetOrCreate(Owner);
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);
		TorBehaviourComp = USkylineTorBehaviourComponent::GetOrCreate(Owner);
		VolleyComp = USkylineTorHammerVolleyComponent::GetOrCreate(Owner);

		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		CenterActor = TListedActors<ASkylineTorReferenceManager>().Single.ArenaCenter;
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);

		AttackIndex = TorBehaviourComp.GetNewAttackIndex(Outer.Name);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineTorSmashAttackBehaviourParams& Params) const
	{
		if(Super::ShouldActivate() == false)
			return false;
		if(AttackIndex != TorBehaviourComp.GetAttackIndex(Outer.Name))
			return false;
		if(HoldHammerComp.bDetached)
			return false;
		if(HoldHammerComp.Hammer.HammerComp.bGrabbed)
			return false;

		float CapsuleHalfHeight = 500;
		float CapsuleRadius = 500;
		FVector Dir = (Owner.ActorLocation - CenterActor.ActorLocation).GetSafeNormal2D();
		FVector Location;
		float Dummy;
		Math::ProjectPositionOnLineSegment(CenterActor.ActorLocation + CenterActor.ActorForwardVector * -CapsuleHalfHeight, CenterActor.ActorLocation + CenterActor.ActorForwardVector * CapsuleHalfHeight, Owner.ActorLocation, Location, Dummy);
		FVector TargetAttackLocation = Location + Dir * CapsuleRadius;

		FVector BaseLocation;
		if(!Pathfinding::FindNavmeshLocation(TargetAttackLocation, 0, 1000, BaseLocation))
			return false;
		else
		{
			TArray<FVector> TargetLocations;
			float AddAngle = Math::IntegerDivisionTrunc(360, SmashComp.AttacksMax);
			for(int i = 0; i < SmashComp.AttacksMax; i++)
			{
				FVector AddLocation = BaseLocation + Owner.ActorForwardVector.RotateAngleAxis(i * AddAngle, FVector::UpVector) * 200;
				if(Pathfinding::FindNavmeshLocation(AddLocation, 0, 1000, AddLocation))
					TargetLocations.Add(AddLocation);
				else
					TargetLocations.Add(BaseLocation);
			}
			Params.HammerAttackLocations = TargetLocations;
		}
		Params.AttackLocation = TargetAttackLocation;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineTorSmashAttackBehaviourParams Params)
	{
		Super::OnActivated();
		
		USkylineTorEventHandler::Trigger_OnSmashAttackTelegraphStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		USkylineTorHammerEventHandler::Trigger_OnSmashAttackAnticipationStart(HoldHammerComp.Hammer);
		bAtLocation = false;
		Attacks = 0;
		Reset();
		PreviousHammerDamageLocation = FVector::ZeroVector;
		DamageComp.bDisableRecoil.Apply(true, this);
		AttackLocation = Params.AttackLocation;
		RandomizedTargetLocations = Params.HammerAttackLocations;
		Target = TargetComp.Target;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnSmashAttackTelegraphStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		DamageComp.bDisableRecoil.Clear(this);
		Owner.ClearSettingsByInstigator(this);
		TorBehaviourComp.IncrementAttackIndex(Outer.Name);

		Cooldown.Set(1);
	}

	private void Reset()
	{
		HitTargets.Empty();
		bTelegraping = true;
		bAction = false;
		bStarted = false;
		bLanding = false;
		ActiveTimer = 0;
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector LookAtLocation = CenterActor.ActorLocation;
		if(Target != nullptr)
			LookAtLocation = Target.ActorLocation;
		DestinationComp.RotateTowards(LookAtLocation);

		FVector CurrentAttackLocation = RandomizedTargetLocations[Attacks] - (LookAtLocation - RandomizedTargetLocations[Attacks]).GetSafeNormal2D() * 350;
		float Speed = Math::Clamp(Owner.ActorLocation.Dist2D(CurrentAttackLocation) * 3, 100, 1250);
		DestinationComp.MoveTowardsIgnorePathfinding(CurrentAttackLocation, Speed);
		if(!bStarted && Owner.ActorLocation.Dist2D(CurrentAttackLocation) > 50)
			return;

		if(!bStarted)
		{
			bStarted = true;

			if(Attacks > 0)
				Durations.Telegraph = 0.5;
			else
				Durations.Telegraph = 0;
			Durations.Recovery = 0.5;
			
			AnimInstance.FinalizeDurations(FeatureTagSkylineTor::SmashAttack, NAME_None, Durations);
			AnimComp.RequestAction(FeatureTagSkylineTor::SmashAttack, EBasicBehaviourPriority::Medium, this, Durations);	

			USkylineTorHammerEventHandler::Trigger_OnVolleyThrow(HoldHammerComp.Hammer, FSkylineTorHammerOnVolleyTelegraphStartData(VolleyComp.TargetLocation));		
		}
		
		ActiveTimer += DeltaTime;

		if(ActiveTimer > Durations.GetTotal())
		{
			if(Attacks >= SmashComp.AttacksMax-1)
				DeactivateBehaviour();
			else if(HoldHammerComp.bAttached)
			{
				Attacks++;
				Reset();
			}
			return;
		}

		if(Durations.IsInTelegraphRange(ActiveTimer))
		{
			if(!bLanding && ActiveTimer > Durations.Telegraph - 0.25)
				bLanding = true;
			return;
		}

		if(bTelegraping)
		{
			bTelegraping = false;
			USkylineTorEventHandler::Trigger_OnSmashAttackTelegraphStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		}

		if(Durations.IsInActionRange(ActiveTimer+0.025) && !bAction)
		{
			bAction = true;
			auto HammerSmashComp = USkylineTorHammerSmashComponent::GetOrCreate(HoldHammerComp.Hammer);
			HammerSmashComp.TargetLocation = RandomizedTargetLocations[Attacks];
			HammerSmashComp.AttackNum = Attacks;
			HoldHammerComp.Detach(ESkylineTorHammerMode::Smash);
		}
	}
}