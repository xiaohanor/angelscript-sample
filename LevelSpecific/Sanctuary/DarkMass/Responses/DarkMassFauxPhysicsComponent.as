class UDarkMassFauxPhysicsComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Physics")
	float PullForce = 1500.0;

	ADarkMassActor GrabbingActor = nullptr;
	TArray<UTargetableComponent> GrabbedComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto ResponseComp = UDarkMassResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (GrabbingActor == nullptr || 
			GrabbedComponents.Num() == 0)
		{
			SetComponentTickEnabled(false);
			return;
		}

		for (auto Component : GrabbedComponents)
		{
			const FVector ToPortal = (GrabbingActor.ActorLocation - Component.WorldLocation);
			const FVector Force = (ToPortal.GetSafeNormal() * PullForce);

			FauxPhysics::ApplyFauxForceToParentsAt(Component, Component.WorldLocation, Force);
		}
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkMassActor MassActor,
		FDarkMassGrabData GrabData)
	{
		if (MassActor == nullptr || 
			GrabData.Component == nullptr)
			return;

		// Would override if we had more than one actor
		//  but we don't, so :^)
		GrabbingActor = MassActor;
		GrabbedComponents.AddUnique(GrabData.Component);

		if (GrabbedComponents.Num() != 0)
			SetComponentTickEnabled(true);
	}

	UFUNCTION()
	private void HandleReleased(ADarkMassActor MassActor,
		FDarkMassGrabData GrabData)
	{
		if (MassActor == nullptr || 
			GrabData.Component == nullptr)
			return;

		GrabbedComponents.Remove(GrabData.Component);

		if (GrabbedComponents.Num() == 0)
			SetComponentTickEnabled(false);
	}
}