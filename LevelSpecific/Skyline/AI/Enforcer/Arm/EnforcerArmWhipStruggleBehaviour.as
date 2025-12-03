class UEnforcerArmWhipStruggleBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UGravityWhipResponseComponent WhipResponse;
	UEnforcerArmComponent ArmComp;

	AHazeActor GrabbingActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ArmComp = UEnforcerArmComponent::Get(Owner);
		ArmComp.Initialize();
		WhipResponse = UGravityWhipResponseComponent::Get(ArmComp.Arm);
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
		ArmComp.EndStruggle();
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
		ArmComp.StartStruggle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!ArmComp.bStruggling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!ArmComp.bStruggling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// DestinationComp.RotateTowards(GrabbingActor.FocusLocation);
		FVector Direction = (GrabbingActor.FocusLocation - Owner.FocusLocation).GetSafeNormal();
		ArmComp.Arm.SetActorRotation(Direction.Rotation());
		ArmComp.SetArmWorldLocation(Owner.FocusLocation + Direction * 200.0);
		AnimComp.RequestFeature(n"NotGravityWhippable", EBasicBehaviourPriority::Medium, this);
	}
}