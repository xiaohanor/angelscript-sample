class UGravityWhipResistBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UGravityWhipResponseComponent WhipResponse;

	AHazeActor GrabbingActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
		WhipResponse.OnReleased.AddUFunction(this, n"OnReleased");
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult,
		FVector Impulse)
	{
		OnReleased(UserComponent, TargetComponent, Impulse);
	}

	UFUNCTION()
	private void OnReleased(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FVector Impulse)
	{
		GrabbingActor = nullptr;
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		auto HazeUser = Cast<AHazeActor>(UserComponent.Owner);
		if (HazeUser == nullptr)
			return;

		TargetComp.SetTarget(HazeUser);
		GrabbingActor = HazeUser;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(GrabbingActor == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(GrabbingActor == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// DestinationComp.RotateTowards(GrabbingActor.FocusLocation);
		AnimComp.RequestFeature(n"NotGravityWhippable", EBasicBehaviourPriority::Medium, this);
	}
}