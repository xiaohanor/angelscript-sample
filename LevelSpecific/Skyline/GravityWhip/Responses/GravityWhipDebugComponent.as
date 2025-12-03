class UGravityWhipDebugComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

 	private UGravityWhipResponseComponent ResponseComponent;

#if EDITOR
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

		FVector AimDirection = (ResponseComponent.AimLocation - Owner.ActorLocation).GetSafeNormal();
		Debug::DrawDebugDirectionArrow(Owner.ActorLocation, AimDirection, GravityWhip::Grab::AimTraceRange);
		Debug::DrawDebugCoordinateSystem(ResponseComponent.DesiredLocation, ResponseComponent.DesiredRotation, 25.0);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		Print(f"Grabbed: {UserComponent.Owner.Name} => {TargetComponent.Name}");

		if (ResponseComponent.Grabs.Num() != 0)
			SetComponentTickEnabled(true);
	}
	
	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent, 
		FVector Impulse)
	{
		Print(f"Released: {UserComponent.Owner.Name} => {TargetComponent.Name} ({Impulse.Size()})");
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent, 
		FHitResult HitResult,
		FVector Impulse)
	{
		Print(f"Thrown: {UserComponent.Owner.Name} => {TargetComponent.Name} ({Impulse.Size()})");
	}
#endif
}