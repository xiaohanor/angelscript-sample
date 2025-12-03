class UEnforcerGravityWhipThrowRecoverBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	USkylineEnforcerGravityWhipComponent EnforcerGravityWhipComp;
	UGravityWhippableComponent WhippableComp;
	USkylineEnforcerSettings EnforcerSettings;
	bool bRecover;
	float ThrownTime;
	FVector ThrownImpulse;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		EnforcerSettings = USkylineEnforcerSettings::GetSettings(Owner);
		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);

		UGravityWhipResponseComponent WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");

		EnforcerGravityWhipComp = USkylineEnforcerGravityWhipComponent::GetOrCreate(Owner);
		EnforcerGravityWhipComp.OnImpact.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	private void OnImpact()
	{
		ThrownTime = 0;
		bRecover = false;
	}

	UFUNCTION()
	private void OnReset()
	{
		ThrownTime = 0;
		bRecover = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult, FVector Impulse)
	{
		ThrownTime = Time::GameTimeSeconds;
		ThrownImpulse = Impulse;
		Owner.SetActorRotation((-ThrownImpulse).Rotation());
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(bRecover)
			return;
		if(ThrownTime == 0)
			return;
		if(Time::GetGameTimeSince(ThrownTime) > EnforcerSettings.GravityWhipThrownDuration)
		{
			bRecover = true;
			WhippableComp.bThrown = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bRecover)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > EnforcerSettings.GravityWhipRecoverDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ThrownTime = 0;
		bRecover = false;
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhipThrown, SubTagAIGravityWhipThrown::Recover, EBasicBehaviourPriority::Medium, this, EnforcerSettings.GravityWhipRecoverDuration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Dir = ThrownImpulse.GetSafeNormal();
		FVector RecoveryLocation = Owner.ActorLocation + Dir * -100;
		DestinationComp.MoveTowards(RecoveryLocation, 500);
	}
}