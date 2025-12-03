UCLASS(Abstract)
class AAISummitFlyingCritter : ABasicAIFlyingCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitFlyingCritterCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		auto AcidResponseComp = UAcidResponseComponent::GetOrCreate(this);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		HealthComp.OnDie.AddUFunction(this, n"OnCritterDie");
	}

	UFUNCTION()
	private void OnCritterDie(AHazeActor ActorBeingKilled)
	{
		UBasicAIDamageEffectHandler::Trigger_OnDeath(this);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if(!MeltComp.bMelted)
			return;
		HealthComp.Die();
	}
}