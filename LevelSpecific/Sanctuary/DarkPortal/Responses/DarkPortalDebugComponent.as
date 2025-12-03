class UDarkPortalDebugComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

 	private UDarkPortalResponseComponent ResponseComponent;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComponent = UDarkPortalResponseComponent::GetOrCreate(Owner);
		ResponseComponent.OnAttached.AddUFunction(this, n"HandleAttached");
		ResponseComponent.OnDetached.AddUFunction(this, n"HandleDetached");
		ResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
		ResponseComponent.OnPushed.AddUFunction(this, n"HandlePushed");
		ResponseComponent.OnExploded.AddUFunction(this, n"HandleExploded");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (ResponseComponent.Grabs.Num() == 0)
		{
			SetComponentTickEnabled(false);
			return;
		}
	}

	UFUNCTION()
	private void HandleAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		Print(f"Attached: {Portal.Name} => {AttachComponent.Owner.Name}");
	}

	UFUNCTION()
	private void HandleDetached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		Print(f"Detached: {Portal.Name} => {AttachComponent.Owner.Name}");
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		Print(f"Grabbed: {Portal.Name} => {TargetComponent.Owner.Name}");

		if (ResponseComponent.Grabs.Num() != 0)
			SetComponentTickEnabled(true);
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		Print(f"Released: {Portal.Name} => {TargetComponent.Owner.Name}");
	}

	UFUNCTION()
	private void HandlePushed(ADarkPortalActor Portal, USceneComponent PushedComponent, FVector WorldLocation, FVector Impulse)
	{
		Print(f"Pushed: {Portal.Name} => {PushedComponent.Owner.Name} ({Impulse.Size()})");
	}

	UFUNCTION()
	private void HandleExploded(ADarkPortalActor Portal, FVector Direction)
	{
		Print(f"Exploded: {Portal.Name} => {Owner.Name}");
	}
#endif
}