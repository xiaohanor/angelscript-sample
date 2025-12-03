class ULightBeamCollisionCapability : UHazeCapability
{
	default CapabilityTags.Add(SanctuaryAICapabilityTags::LightBeamCollision);	

	UPrimitiveComponent Collision;
	ULightBeamTargetComponent LightBeamTargetComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Collision = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		LightBeamTargetComponent = ULightBeamTargetComponent::Get(Owner);

		DisableCollision();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		EnableCollision();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DisableCollision();
	}

	void EnableCollision()
	{
		LightBeamTargetComponent.Enable(this);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	}

	void DisableCollision()
	{
		LightBeamTargetComponent.Disable(this);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Ignore);	
	}
}