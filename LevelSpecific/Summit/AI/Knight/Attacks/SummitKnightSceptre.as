class USummitKnightSceptreComponent : UStaticMeshComponent
 {
	default CollisionProfileName = n"NoCollision";
	default bCanEverAffectNavigation = false;

	void Equip()
	{
		SetHiddenInGame(false);
	}

	void Unequip()
	{
		SetHiddenInGame(true);
	}

	FVector GetHeadLocation() const property
	{
		return WorldLocation + RightVector * 1500.0;
	}
 }
