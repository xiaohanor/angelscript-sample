class USkylineFlyingCar2DPilotCapability : UHazePlayerCapability
{
	USkylineFlyingCar2DPilotComponent PilotComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PilotComponent = USkylineFlyingCar2DPilotComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PilotComponent.FlyingCar2D == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PilotComponent.FlyingCar2D == nullptr)
			return true;

		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Visibility, this);
		Player.BlockCapabilities(n"GravityWhip", this);

		Player.AttachToActor(PilotComponent.FlyingCar2D);
		Player.ActivateCamera(PilotComponent.FlyingCar2D.Camera, 0.0, this);
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Visibility, this);		

		Player.DetachFromActor();
		Player.DeactivateCameraByInstigator(this);
		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		PrintScaled("Input: " + Input, 0.0, FLinearColor::Green, 1.0);
		PilotComponent.FlyingCar2D.Input = Input;
	}
}