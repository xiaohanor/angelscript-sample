class UDarkProjectileCollisionCapability : UHazeCapability
{
	default CapabilityTags.Add(SanctuaryAICapabilityTags::DarkProjectileCollision);	

	UPrimitiveComponent Collision;
	UDarkProjectileTargetComponent DarkProjectileTargetComponent;
//	UDarkProjectileTargetComponent2D DarkProjectileTargetComponent2D;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Collision = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		DarkProjectileTargetComponent = UDarkProjectileTargetComponent::Get(Owner);
//		DarkProjectileTargetComponent2D = UDarkProjectileTargetComponent2D::Get(Owner);

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
		DarkProjectileTargetComponent.Enable(this);
//		DarkProjectileTargetComponent2D.Enable(this);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	}

	void DisableCollision()
	{
		DarkProjectileTargetComponent.Disable(this);
//		DarkProjectileTargetComponent2D.Disable(this);
		Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Ignore);	
	}
}