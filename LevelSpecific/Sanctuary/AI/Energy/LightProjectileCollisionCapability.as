class ULightProjectileCollisionCapability : UHazeCapability
{
	default CapabilityTags.Add(SanctuaryAICapabilityTags::LightProjectileCollision);	

	UPrimitiveComponent Collision;
	ULightProjectileTargetComponent LightProjectileTargetComponent;
	ULightProjectileTargetComponent2D LightProjectileTargetComponent2D;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Collision = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		LightProjectileTargetComponent = ULightProjectileTargetComponent::Get(Owner);
		LightProjectileTargetComponent2D = ULightProjectileTargetComponent2D::Get(Owner);

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
		LightProjectileTargetComponent.Enable(this);
		LightProjectileTargetComponent2D.Enable(this);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	}

	void DisableCollision()
	{
		LightProjectileTargetComponent.Disable(this);
		LightProjectileTargetComponent2D.Disable(this);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Ignore);	
	}
}