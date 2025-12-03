
class USanctuaryWeeperChaseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	USanctuaryWeeperSettings WeeperSettings;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryWeeperViewComponent ViewComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WeeperSettings = USanctuaryWeeperSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		// ViewComp = USanctuaryWeeperViewComponent::Get(Owner);
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
	void TickActive(float DeltaTime)
	{
		TargetComp.Target = Game::Zoe;
		float MoveSpeed = BasicSettings.ChaseMoveSpeed;
		FVector Dir = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		FVector AttackLocation = TargetComp.Target.ActorLocation - Dir * BasicSettings.AttackRange;
		
		if(Owner.ActorLocation.IsWithinDist(AttackLocation, WeeperSettings.ChaseAttackSlowdownRange))
		{
			float Distance = Owner.ActorLocation.Distance(AttackLocation);
			float Alpha = Distance / WeeperSettings.ChaseAttackSlowdownRange;
			MoveSpeed = WeeperSettings.ChaseAttackSlowdownMinSpeed + Alpha * (BasicSettings.ChaseMoveSpeed - WeeperSettings.ChaseAttackSlowdownMinSpeed);
		}

		DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
		DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, MoveSpeed);

		// FVector DodgeDirection;
		// if(ViewComp.ShouldDodge(DodgeDirection))
		// 	DestinationComp.AddCustomAcceleration(DodgeDirection * WeeperSettings.DodgeSpeed);
	}
}

