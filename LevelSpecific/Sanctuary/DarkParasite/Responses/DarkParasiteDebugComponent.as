class UDarkParasiteDebugComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto ResponseComp = UDarkParasiteResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnFocused.AddUFunction(this, n"HandleFocused");
		ResponseComp.OnUnfocused.AddUFunction(this, n"HandleUnfocused");
		ResponseComp.OnAttached.AddUFunction(this, n"HandleAttached");
		ResponseComp.OnDetached.AddUFunction(this, n"HandleDetached");
		ResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION()
	private void HandleFocused(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		Print(f"Focused: {TargetData.TargetComponent.Name}", 1.0);
	}

	UFUNCTION()
	private void HandleUnfocused(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		Print(f"Unfocused: {TargetData.TargetComponent.Name}", 1.0);
	}

	UFUNCTION()
	private void HandleAttached(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		Print(f"Attached: {TargetData.TargetComponent.Name}", 1.0);
	}
	
	UFUNCTION()
	private void HandleDetached(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		Print(f"Detached: {TargetData.TargetComponent.Name}", 1.0);
	}

	UFUNCTION()
	private void HandleGrabbed(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData AttachedData,
		FDarkParasiteTargetData GrabbedData)
	{
		Print(f"Grabbed: {AttachedData.TargetComponent.Name} => {GrabbedData.TargetComponent.Name}", 1.0);
	}

	UFUNCTION()
	private void HandleReleased(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData AttachedData,
		FDarkParasiteTargetData GrabbedData)
	{
		Print(f"Released: {AttachedData.TargetComponent.Name} => {GrabbedData.TargetComponent.Name}", 1.0);
	}
#endif
}