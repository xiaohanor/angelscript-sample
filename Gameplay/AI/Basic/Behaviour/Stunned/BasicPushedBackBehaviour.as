
// Simple impulse away from attacker
class UBasicPushedBackBehaviour : UBasicBehaviour
{
	UBasicAIHealthComponent HealthComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)		
			return false;
		if (HealthComp.LastAttacker == nullptr)
			return false;
		if (!HealthComp.ShouldReactToDamage(BasicSettings.PushedBackDamageTypes, 0.5))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!HealthComp.IsStunned())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		HealthComp.SetStunned();

		// Only get pushed back once during push back interval; if we want to be pushed back several times we 
		// need to network that as we can get damage several times per frame etc. 

		// Apply an impulse away from attacker
		FVector PushDir = (Owner.ActorCenterLocation - HealthComp.LastAttacker.ActorCenterLocation).GetSafeNormal();
		float PushForce = BasicSettings.PushedBackForce + BasicSettings.PushedBackDamageFactor * HealthComp.LastDamage;
		Owner.AddMovementImpulse(PushDir * PushForce);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HealthComp.ClearStunned();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > BasicSettings.PushedBackDuration)
		{
			HealthComp.ClearStunned();
			TargetComp.SetTarget(nullptr);
			AnimComp.Reset();
			return;
		}
	}
}