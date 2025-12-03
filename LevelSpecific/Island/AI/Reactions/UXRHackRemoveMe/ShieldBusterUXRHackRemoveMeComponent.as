// TODO: HACK! Remove once Island Enforcer is not used anymore!
class UShieldBusterUXRHackRemoveMeComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	UNiagaraSystem StunFx;
	UBasicAIAnimationComponent AnimComp;
	AHazeActor HazeOwner;
	float StunDuration = 1.27;
	float StunTime;

	private UNiagaraComponent StunFxComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		auto ShieldBusterComp = UScifiShieldBusterImpactResponseComponent::Get(Owner);
		ShieldBusterComp.OnImpact.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	private void OnImpact(AHazePlayerCharacter ImpactInstigator,
	                      UScifiShieldBusterTargetableComponent Component)
	{
		if(StunTime > 0) 
			return;
		
		StunTime = Time::GetGameTimeSeconds();
		StunFxComp = Niagara::SpawnLoopingNiagaraSystemAttached(StunFx, Owner.RootComponent);
		HazeOwner.BlockCapabilities(n"Behaviour", this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(StunTime == 0)
			return;

		AnimComp.RequestFeature(n"GravityBladeHitReactionSmall", EBasicBehaviourPriority::Maximum, this);

		if(Time::GetGameTimeSince(StunTime) > StunDuration)
		{
			StunTime = 0;
			DestroyComponent(StunFxComp);
			StunFxComp.DestroyComponent(StunFxComp);
			HazeOwner.UnblockCapabilities(n"Behaviour", this);
			AnimComp.ClearFeature(this);
		}
	}
}