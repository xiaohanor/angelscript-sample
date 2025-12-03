class USanctuaryUnseenChaseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	USanctuaryUnseenSettings UnseenSettings;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryUnseenChaseComponent ChaseComp;

	private float StepTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		UnseenSettings = USanctuaryUnseenSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		ChaseComp = USanctuaryUnseenChaseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ChaseComp.bChasing = true;
		StepTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ChaseComp.bChasing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float MoveSpeed = BasicSettings.ChaseMoveSpeed;
		FVector Dir = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		FVector AttackLocation = TargetComp.Target.ActorLocation - Dir * BasicSettings.AttackRange;
		
		if(Owner.ActorLocation.IsWithinDist(AttackLocation, UnseenSettings.ChaseAttackSlowdownRange))
		{
			float Distance = Owner.ActorLocation.Distance(AttackLocation);
			float Alpha = Distance / UnseenSettings.ChaseAttackSlowdownRange;
			MoveSpeed = UnseenSettings.ChaseAttackSlowdownMinSpeed + Alpha * (BasicSettings.ChaseMoveSpeed - UnseenSettings.ChaseAttackSlowdownMinSpeed);
		}

		DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
		DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, MoveSpeed);

		if(ChaseComp.bDarkness) return;
		if(StepTime == 0 || Time::GetGameTimeSince(StepTime) > UnseenSettings.ChaseStepInterval)
		{
			StepTime = Time::GetGameTimeSeconds();
			USanctuaryUnseenEffectHandler::Trigger_ChaseStep(Owner);
		}
	}
}

