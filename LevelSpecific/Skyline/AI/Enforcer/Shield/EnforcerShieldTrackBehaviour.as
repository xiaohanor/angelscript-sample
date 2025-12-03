class UEnforcerShieldTrackBehaviour : UBasicBehaviour
{
	UGravityWhipResponseComponent WhipResponse;
	UEnforcerShieldComponent ShieldComp;
	FHazeAcceleratedRotator AccRotation;

	AHazeActor GrabbingActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShieldComp = UEnforcerShieldComponent::Get(Owner);
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);

		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnReleased.AddUFunction(this, n"OnReleased");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
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
		GrabbingActor = Cast<AHazeActor>(UserComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!ShieldComp.bEnabled)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!ShieldComp.bEnabled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazeActor Target;

		if(GrabbingActor != nullptr)
			Target = GrabbingActor;
		else
			Target = TargetComp.FindClosestTarget(BasicSettings.AwarenessRange);

		if(Target == nullptr)
			return;

		FRotator Rotation = (Target.ActorLocation - Owner.ActorLocation).Rotation();
		AccRotation.Value = ShieldComp.WorldRotation;
		AccRotation.AccelerateTo(Rotation, 0.3, DeltaTime);
		ShieldComp.SetWorldRotation(AccRotation.Value);
	}
}