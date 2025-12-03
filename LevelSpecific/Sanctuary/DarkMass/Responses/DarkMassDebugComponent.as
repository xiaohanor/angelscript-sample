class UDarkMassDebugComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto ResponseComp = UDarkMassResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnAttach.AddUFunction(this, n"HandleAttached");
		ResponseComp.OnDetach.AddUFunction(this, n"HandleDetached");
		ResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}
	
	UFUNCTION()
	private void HandleAttached(ADarkMassActor MassActor,
		FDarkMassSurfaceData SurfaceData)
	{
		Print(f"Attached: {SurfaceData.SurfaceComponent.Name}", 1.0);
	}

	UFUNCTION()
	private void HandleDetached(ADarkMassActor MassActor,
		FDarkMassSurfaceData SurfaceData)
	{
		Print(f"Detached: {SurfaceData.SurfaceComponent.Name}", 1.0);
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkMassActor MassActor,
		FDarkMassGrabData GrabData)
	{
		Print(f"Grabbed: {GrabData.Component.Name}", 1.0);
	}

	UFUNCTION()
	private void HandleReleased(ADarkMassActor MassActor,
		FDarkMassGrabData GrabData)
	{
		Print(f"Released: {GrabData.Component.Name}", 1.0);
	}
#endif
}