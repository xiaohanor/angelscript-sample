class UGravityWhipFauxPhysicsComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Only apply the force to attached components on this actor, ignoring any attach parents on different actors
	UPROPERTY(Category = "Faux Physics", EditAnywhere, AdvancedDisplay)
	bool bOnlyApplyForceToThisActor = false;

	private UGravityWhipResponseComponent ResponseComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComponent = UGravityWhipResponseComponent::GetOrCreate(Owner);
		ResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
		ResponseComponent.OnThrown.AddUFunction(this, n"HandleThrown");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (ResponseComponent.Grabs.Num() == 0)
		{
			SetComponentTickEnabled(false);
			return;
		}

		// Apply and consume pending forces
		for (int i = 0; i < ResponseComponent.Grabs.Num(); ++i)
		{
			auto& Grab = ResponseComponent.Grabs[i];

			FauxPhysics::ApplyFauxForceToParentsAt(Grab.TargetComponent,
				Grab.TargetComponent.WorldLocation,
				Grab.TargetComponent.ConsumeForce(),
				bSameActorOnly = bOnlyApplyForceToThisActor);
		}
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if (ResponseComponent.Grabs.Num() != 0)
			SetComponentTickEnabled(true);

		TArray<UFauxPhysicsComponentBase> PhysicsParents;
		FauxPhysics::CollectPhysicsParents(PhysicsParents, TargetComponent);

		for (UFauxPhysicsComponentBase PhysComp : PhysicsParents)
			PhysComp.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}
	
	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FVector Impulse)
	{
		FauxPhysics::ApplyFauxImpulseToParentsAt(TargetComponent,
			TargetComponent.WorldLocation,
			Impulse);

		if (ResponseComponent.Grabs.Num() == 0)
			SetComponentTickEnabled(false);

		TArray<UFauxPhysicsComponentBase> PhysicsParents;
		FauxPhysics::CollectPhysicsParents(PhysicsParents, TargetComponent);

		for (UFauxPhysicsComponentBase PhysComp : PhysicsParents)
			PhysComp.OverrideNetworkSyncRate(EHazeCrumbSyncRate::Standard);
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult,
		FVector Impulse)
	{
		FauxPhysics::ApplyFauxImpulseToParentsAt(TargetComponent,
			TargetComponent.WorldLocation,
			Impulse,
			bSameActorOnly = bOnlyApplyForceToThisActor);

		if (ResponseComponent.Grabs.Num() == 0)
			SetComponentTickEnabled(false);
	}
}