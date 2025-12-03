UCLASS(Abstract)
class AAISummitClimbingCritter : ABasicAIWallclimbingCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitClimbingCritterCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitClimbingCritterSpawnGravityCapability");	

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		auto AcidResponseComp = UAcidResponseComponent::GetOrCreate(this);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if(!MeltComp.bMelted)
			return;
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Acid, Hit.PlayerInstigator);
	}
}