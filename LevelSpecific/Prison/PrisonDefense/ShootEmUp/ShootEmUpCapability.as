class UShootEmUpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UShootEmUpPlayerComponent ShootEmUpComp;
	AShootEmUpShip Ship;

	float ShootCooldown = 0.1;
	float CurShootCooldown = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShootEmUpComp = UShootEmUpPlayerComponent::Get(Player);
		Ship = ShootEmUpComp.CurrentShip;
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
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Visibility, this);

		Player.AttachToComponent(Ship.RootComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Visibility, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D PlayerInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		Ship.UpdatePlayerInput(PlayerInput);

		if (IsActioning(ActionNames::WeaponFire))
		{
			CurShootCooldown += DeltaTime;
			if (CurShootCooldown >= ShootCooldown)
			{
				CurShootCooldown = 0.0;
				FireShot();
			}
		}
	}

	void FireShot()
	{
		SpawnActor(ShootEmUpComp.ProjectileClass, Ship.ShotRoot.WorldLocation, Ship.ActorRotation);
	}
}