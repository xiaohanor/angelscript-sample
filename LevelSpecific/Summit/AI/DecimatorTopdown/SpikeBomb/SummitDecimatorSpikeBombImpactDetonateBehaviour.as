// Can only damage the Decimator
class USummitDecimatorSpikeBombImpactDetonateBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAIHealthComponent HealthComp;
	USummitMeltComponent MeltComp;
	UHazeActorRespawnableComponent RespawnComp;
	USummitDecimatorSpikeBombAutoAimComponent AutoAimComp;
	
	USummitDecimatorSpikeBombSettings Settings;
	
	AAISummitDecimatorSpikeBomb SpikeBomb;

	bool bHasBeenHitByRoll = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MeltComp = USummitMeltComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
		AutoAimComp = USummitDecimatorSpikeBombAutoAimComponent::GetOrCreate(Owner);
		AutoAimComp.OnAutoAimAssistedHit.AddUFunction(this, n"OnAutoAimAssistedHit");
		SpikeBomb = Cast<AAISummitDecimatorSpikeBomb>(Owner);
		Settings = USummitDecimatorSpikeBombSettings::GetSettings(Owner);						
	}

	UFUNCTION()
	private void Reset()
	{
		bHasBeenHitByRoll = false;
	}

	UFUNCTION()
	private void OnAutoAimAssistedHit()
	{
		bHasBeenHitByRoll = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!MeltComp.bMelted)
			return false;

		if (!Owner.ActorCenterLocation.IsWithinDist(SpikeBomb.DecimatorOwner.ActorCenterLocation, Settings.DecimatorDetonationRange))
			return false;

		if (!bHasBeenHitByRoll)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if (Super::ShouldDeactivate())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		// Kill self
		HealthComp.TakeDamage(1.0, EDamageType::Explosion, Owner);
				
		// Deal damage to Decimator
		FVector HitDirection = Owner.ActorVelocity.GetSafeNormal2D();
		SpikeBomb.DecimatorOwner.OnSpikeBombHit(Owner, HitDirection);

		// Trigger effect		
		USummitDecimatorSpikeBombEffectsHandler::Trigger_OnDecimatorImpact(Owner);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Owner.ActorCenterLocation, 1000, LineColor = FLinearColor::Red, Duration = 1.0);
		}
#endif
	}

}