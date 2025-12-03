
class UGravityWhipContainerDragTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(n"GravityWhipTutorial");
	default CapabilityTags.Add(n"Tutorial");

	UGravityWhipUserComponent GravityWhipUserComponent;
	UGravityWhipTutorialComponent GravityWhipTutorialComponent;
	UPlayerAimingComponent PlayerAimingComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityWhipUserComponent = UGravityWhipUserComponent::Get(Player);
		GravityWhipTutorialComponent = UGravityWhipTutorialComponent::Get(Player);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!GravityWhipUserComponent.IsGrabbingAny())
			return false;

		if (!HasDragGrabMode())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!GravityWhipUserComponent.IsGrabbingAny())
			return true;

		if (!HasDragGrabMode())
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<AGravityWhipContainerTutorialActor> GrabTutorials;
		auto GrabLocation = GravityWhipUserComponent.Grabs[0].TargetComponents[0];

		Player.ShowTutorialPromptWorldSpace(GravityWhipTutorialComponent.PromptDragHorizontal, this, GrabLocation, GravityWhipTutorialComponent.AttachOffset, GravityWhipTutorialComponent.ScreenSpaceOffset);

		//Player.ShowTutorialPrompt(GravityWhipTutorialComponent.PromptDrag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	bool HasDragGrabMode() const
	{
		if (GravityWhipUserComponent.GetPrimaryGrabMode() == EGravityWhipGrabMode::Drag)
			return true;

		if (GravityWhipUserComponent.GetPrimaryGrabMode() == EGravityWhipGrabMode::ControlledDrag)
			return true;

		if (GravityWhipUserComponent.GetPrimaryGrabMode() == EGravityWhipGrabMode::Control)
			return true;

		return false;
	}
}