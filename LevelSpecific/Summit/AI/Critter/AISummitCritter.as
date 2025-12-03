UCLASS(Abstract)
class AAISummitCritter : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCritterCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;

	AStoneBossArmorPoint ArmorPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (ArmorPoint != nullptr)
		{
			MovementComponent.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
			MovementComponent.FollowComponentMovement(ArmorPoint.RootComponent, this, Priority = EInstigatePriority::Normal);
			UPathfollowingSettings::SetIgnorePathfinding(this, true, this, EHazeSettingsPriority::Defaults);	
		}

		auto AcidResponseComp = UAcidResponseComponent::GetOrCreate(this);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		HealthComp.OnDie.AddUFunction(this, n"OnCritterDie");
	}

	UFUNCTION()
	private void OnCritterDie(AHazeActor ActorBeingKilled)
	{
		UBasicAIDamageEffectHandler::Trigger_OnDeath(this);
		MovementComponent.Reset();
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if(!MeltComp.bMelted)
			return;
		HealthComp.Die();
	}
}