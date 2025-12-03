class UEnforcerArmorGravityWhipBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UGravityWhipResponseComponent WhipResponse;
	UEnforcerArmorComponent ArmorComp;

	bool bGrabbed = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
		WhipResponse.OnReleased.AddUFunction(this, n"OnReleased");
		ArmorComp = UEnforcerArmorComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult,
		FVector Impulse)
	{
		auto HazeUser = Cast<AHazeActor>(UserComponent.Owner);
		if (HazeUser == nullptr)
			return;

		bGrabbed = false;
		if(Impulse.IsNearlyZero(100.0)) return;
		ArmorComp.DisableArmor(HazeUser);
	}

	UFUNCTION()
	private void OnReleased(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		auto HazeUser = Cast<AHazeActor>(UserComponent.Owner);
		if (HazeUser == nullptr)
			return;

		bGrabbed = false;
		if(Impulse.IsNearlyZero(100.0)) return;
		ArmorComp.DisableArmor(HazeUser);
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		bGrabbed = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(bGrabbed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(!bGrabbed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhippable, SubTagAIGravityWhippable::Grabbed, EBasicBehaviourPriority::Medium, this);
	}
}