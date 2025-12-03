
class USkylineTorWhirlwindAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(SkylineTorAttackTags::WhirlwindAttack);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorCooldownComponent CooldownComp;
	USkylineTorDamageComponent DamageComp;
	USkylineTorDealDamageComponent DealDamageComp;
	UTargetTrailComponent TrailComp;
	USkylineTorAnimationComponent TorAnimComp;
	UForceFeedbackComponent WhirlwindForceFeedbackComp;
	UMovableCameraShakeComponent WhirlwindCameraShakeComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AHazePlayerCharacter Target;
	private AHazeCharacter Character;

	FBasicAIAnimationActionDurations Durations;

	bool bTelegraping;
	bool bRecovery;
	bool bSwitchedTarget;
	bool bBlocked;
	float SwitchedTargetTime;
	int SwitchedTargetNum;

	float TargetMaxTime;
	FVector TargetLocation;

	FVector PreviousBodyDamageLocation;
	FVector PreviousHammerDamageLocation;

	float ClearTargetTime;
	float ClearTargetInterval = 0.5;
	float RecoverTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		DamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);
		DealDamageComp = USkylineTorDealDamageComponent::GetOrCreate(Owner);
		TorAnimComp = USkylineTorAnimationComponent::GetOrCreate(Owner);
		WhirlwindForceFeedbackComp = UForceFeedbackComponent::GetOrCreate(Owner);
		WhirlwindCameraShakeComp = UMovableCameraShakeComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);

		Durations.Telegraph = AnimInstance.WhirlwindTelegraph.Sequence.PlayLength;
		Durations.Action = Settings.WhirlwindDuration;
		Durations.Recovery = AnimInstance.WhirlwindTelegraph.Sequence.PlayLength;

		WhirlwindForceFeedbackComp.Stop();
		WhirlwindCameraShakeComp.DeactivateMovableCameraShake();
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(HoldHammerComp.bDetached)
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
		if(RecoverTime > 0 && Time::GetGameTimeSince(RecoverTime) > 1)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AnimComp.RequestFeature(FeatureTagSkylineTor::Whirlwind, SubTagSkylineTorWhirlwind::Telegraph, EBasicBehaviourPriority::Medium, this);

		USkylineTorSettings::SetAnimationMovementTurnDuration(Owner, 2.5, this);
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TrailComp = UTargetTrailComponent::GetOrCreate(Target);
		TargetLocation = TrailComp.GetTrailLocation(0.75);

		USkylineTorEventHandler::Trigger_OnWhirlwindTelegraphStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		bTelegraping = true;
		bRecovery = false;
		bSwitchedTarget = false;
		SwitchedTargetNum = 0;
		SwitchedTargetTime = Time::GameTimeSeconds;
		bBlocked = false;
		RecoverTime = 0;

		PreviousBodyDamageLocation = FVector::ZeroVector;
		PreviousHammerDamageLocation = FVector::ZeroVector;

		DamageComp.bDisableRecoil.Apply(true, this);
		DealDamageComp.ResetDamage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnWhirlwindAttackStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		USkylineTorEventHandler::Trigger_OnWhirlwindTelegraphStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(PlayerTarget != nullptr)
			TargetComp.SetTarget(PlayerTarget.OtherPlayer);
		Character.MeshOffsetComponent.RelativeRotation = FRotator::ZeroRotator;
		Owner.ClearSettingsByInstigator(this);
		TorAnimComp.bAllowLoopingAnimationMovement = false;
		DamageComp.bDisableRecoil.Clear(this);
		Cooldown.Set(1);
		WhirlwindForceFeedbackComp.Stop();
		WhirlwindCameraShakeComp.DeactivateMovableCameraShake();

		if(bBlocked)
			Owner.UnblockCapabilities(n"Hover", this);
	}

	private void SwitchTarget()
	{
		Target = Target.OtherPlayer;
		TrailComp = UTargetTrailComponent::GetOrCreate(Target);
		SwitchedTargetNum++;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(RecoverTime > 0)
			return;

		if(Durations.IsInTelegraphRange(ActiveDuration))
			return;

		if(bTelegraping)
		{	
			// WhirlwindForceFeedbackComp.Play();
			// WhirlwindCameraShakeComp.ActivateMovableCameraShake();

			bBlocked = true;
			Owner.BlockCapabilities(n"Hover", this);

			bTelegraping = false;
			USkylineTorEventHandler::Trigger_OnWhirlwindTelegraphStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
			USkylineTorEventHandler::Trigger_OnWhirlwindAttackStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
			ClearTargetTime = Time::GameTimeSeconds;

			float AttackSpeed = 2250;
			FVector Move = Owner.ActorForwardVector * AttackSpeed * AnimInstance.Whirlwind.Sequence.ScaledPlayLength;
			// HACK: Compensates for scaling in animation. Remove when we have proper model!
			Move *= 0.5;

			TorAnimComp.bAllowLoopingAnimationMovement = true;
			AnimComp.RequestFeature(FeatureTagSkylineTor::Whirlwind, SubTagSkylineTorWhirlwind::Attack, EBasicBehaviourPriority::Medium, this, AnimInstance.Whirlwind.Sequence.ScaledPlayLength, Move, true);
		}

		if(Target.ActorLocation.IsWithinDist(Owner.ActorLocation, 500)
			|| Time::GetGameTimeSince(SwitchedTargetTime) > 5
		)
		{
			SwitchTarget();
			SwitchedTargetTime = Time::GameTimeSeconds;
		}

		if(Target.IsPlayerDead())
		{
			SwitchTarget();
		}

		if(Time::GetGameTimeSince(SwitchedTargetTime) > 1)
		{
			TargetLocation = TrailComp.GetTrailLocation(0.75);

			if(SwitchedTargetNum >= 4)
			{
				RecoverTime = Time::GameTimeSeconds;
				if(bBlocked)
				{
					Owner.UnblockCapabilities(n"Hover", this);
					bBlocked = false;
				}
			}

			FVector MoveLocation = TargetLocation;
			if(!Pathfinding::FindNavmeshLocation(TargetLocation, 150, 1000, MoveLocation))
				SwitchTarget();
		}

		DestinationComp.RotateTowards(TargetLocation);
		DealDamageComp.DealHammerDamage(0.5, ESkylineTorDealDamageDirection::Side);
		DealDamageComp.DealBodyDamage(0.5, ESkylineTorDealDamageDirection::Side);

		if(Time::GetGameTimeSince(ClearTargetTime) > ClearTargetInterval)
		{
			DealDamageComp.ResetHits();
			ClearTargetTime = Time::GameTimeSeconds;
		}

		FVector OwnerLocation = Owner.ActorLocation;
		if(!Pathfinding::FindNavmeshLocation(Owner.ActorLocation, 100, 1000, OwnerLocation))
			DeactivateBehaviour();
	}
}