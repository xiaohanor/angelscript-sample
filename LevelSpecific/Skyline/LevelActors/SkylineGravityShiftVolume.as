class ASkylineGravityShiftVolume : APlayerTrigger
{
	default bTriggerForMio = true;
	default bTriggerForZoe = false;

	UPROPERTY(DefaultComponent)
	UGravityBladeGravityShiftComponent ShiftComponent;
	default ShiftComponent.bForceSticky = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeave");
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		auto UserComp = UGravityBladeGrappleUserComponent::Get(Player);
		if (UserComp == nullptr)
			return;
		
		// Force set gravity shift to our surface if we enter
		FGravityBladeGravityAlignSurface Surface;
		Surface.ShiftComponent = ShiftComponent;
		Surface.SurfaceComponent = BrushComponent;
		UserComp.ActiveAlignSurface = Surface;
		
		// Disable querying while in the volume, we can still grapple out of it though
		//  but if grappling within the volume we're done for probably :^)
		UserComp.AlignQueryDisablers.AddUnique(this);
	}

	UFUNCTION()
	private void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		auto UserComp = UGravityBladeGrappleUserComponent::Get(Player);
		if (UserComp == nullptr)
			return;

		UserComp.AlignQueryDisablers.Remove(this);
	}
}