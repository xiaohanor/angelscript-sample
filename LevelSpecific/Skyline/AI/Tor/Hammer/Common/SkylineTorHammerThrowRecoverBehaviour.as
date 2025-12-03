
class USkylineTorHammerThrowRecoverBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerProjectileComponent ProjectileComp;
	USkylineTorPhaseComponent TorPhaseComp;
	USkylineTorHammerPivotComponent PivotComp;
	USkylineTorHammerStealComponent StealComp;
	USkylineTorHammerSmashComponent SmashComp;
	USkylineTorSettings Settings;

	const float Duration = 1;
	FHazeAcceleratedRotator AccRotation;
	FRotator TargetRotation;
	FHazeAcceleratedVector AccLocation;
	FVector TargetLocation;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		ProjectileComp = USkylineTorHammerProjectileComponent::GetOrCreate(Owner);
		TorPhaseComp = USkylineTorPhaseComponent::GetOrCreate(HammerComp.HoldHammerComp.Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);
		SmashComp = USkylineTorHammerSmashComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (HammerComp.CurrentMode == ESkylineTorHammerMode::Smash && SmashComp.AttackNum < 2)
			return false;
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
	void OnActivated()
	{
		Super::OnActivated();

		PivotComp.SetPivot(UHazeCapsuleCollisionComponent::GetOrCreate(Owner).WorldLocation);
		AccRotation.SnapTo(PivotComp.Pivot.ActorRotation);
		TargetRotation = FRotator::ZeroRotator;
		TargetLocation = Owner.ActorLocation;
		StealComp.InitializeStealing();

		USkylineTorHammerEventHandler::Trigger_OnRecover(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		PivotComp.RemovePivot();
		Owner.ActorRotation = FRotator::ZeroRotator;

		UHazeCrumbSyncedActorPositionComponent NetworkMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner);
		if (NetworkMotionComp != nullptr)
			NetworkMotionComp.TransitionSync(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRotation.SpringTo(TargetRotation, 500, 0.2, DeltaTime);
		PivotComp.Pivot.ActorRotation = AccRotation.Value;
		// PivotComp.Pivot.ActorLocation += FVector::UpVector * 100 * DeltaTime;

		if(ActiveDuration > Duration)
		{
			if(HammerComp.HoldHammerComp.Tor.PhaseComp.Phase == ESkylineTorPhase::Hovering) //&& !Settings.ShieldBreakModeEnabled)
			{
				if(HammerComp.HoldHammerComp.Tor.PhaseComp.SubPhase == ESkylineTorSubPhase::None)
					HammerComp.SetMode(ESkylineTorHammerMode::Melee);
				else
					HammerComp.SetMode(ESkylineTorHammerMode::MeleeSecond);
			}
			else if(HammerComp.HoldHammerComp.Tor.PhaseComp.SubPhase == ESkylineTorSubPhase::GroundedSecond)
			{
				HammerComp.SetMode(ESkylineTorHammerMode::MeleeGrounded);
			}
			DeactivateBehaviour();
		}
	}
}