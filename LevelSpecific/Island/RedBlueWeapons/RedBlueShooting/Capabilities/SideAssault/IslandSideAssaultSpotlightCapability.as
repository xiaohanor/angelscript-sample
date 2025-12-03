class UIslandRedBlueSidescrollerAssaultSpotlightCapability : UHazePlayerCapability
{
	// Since we don't want the crosshair to be hidden even if we block weapons for a bit, we don't have the below tag
	//default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueWeapon);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueEquipped);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(BlockedWhileIn::AirJump);
	default CapabilityTags.Add(BlockedWhileIn::Dash);
	default CapabilityTags.Add(BlockedWhileIn::DashRollState);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UPlayerAimingComponent AimComponent;
	UIslandRedBlueSidescrollerAssaultSettings SidescrollerAssaultSettings;

	FHazeAcceleratedVector AcceleratedSpotlightDirection;

	const float MaxSpotlightLength = 4000.0;
	AIslandRedBlueSidescrollerSpotlightActor SpotlightActor;
	float DistanceToStart = 70.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		AimComponent = UPlayerAimingComponent::Get(Player);
		SidescrollerAssaultSettings = UIslandRedBlueSidescrollerAssaultSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CanEverShowSpotlight())
			return false;

		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::SidescrollerAssault)
			return false;

		if(!WeaponUserComponent.HasEquippedWeapons())
			return false;
		
		if(!WeaponUserComponent.IsAiming())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CanEverShowSpotlight())
			return true;

		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::SidescrollerAssault)
			return true;

		if(!WeaponUserComponent.HasEquippedWeapons())
			return true;

		if(!WeaponUserComponent.IsAiming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DistanceToStart = 70.0;

		auto AimDir = GetAimDirection();
		AcceleratedSpotlightDirection.SnapTo(AimDir);

		if(SpotlightActor == nullptr)
			SpawnSpotlight();

		SpotlightActor.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SpotlightActor.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetAimDir = GetAimDirection();
		AcceleratedSpotlightDirection.AccelerateTo(TargetAimDir, SidescrollerAssaultSettings.SpotlightAimAccelerationDuration, DeltaTime);

		UpdateSpotlight();
	}

	private void UpdateSpotlight()
	{
		FAimingRay AimRay = AimComponent.GetPlayerAimingRay();

		FVector Start = AimRay.Origin;
		FVector Direction = AcceleratedSpotlightDirection.Value.GetSafeNormal();
		FVector End = Start + Direction * MaxSpotlightLength;

		float Angle = SidescrollerAssaultSettings.ConeMaxDegreeOffset;
		SpotlightActor.SetAngle(Angle);

		FVector StartToEnd = (End - Start);

		if(AimComponent.HasAiming2DConstraint() && AimComponent.GetCurrentAimingConstraintType() == EAimingConstraintType2D::Spline)
		{
			FVector Normal = AimComponent.Get2DConstraintPlaneNormal();
			StartToEnd = StartToEnd.VectorPlaneProject(Normal);
			FVector DirToEnd = StartToEnd.GetSafeNormal();
			FVector Up = DirToEnd.CrossProduct(Normal);
			StartToEnd = StartToEnd.RotateAngleAxis(-20.0, Up);
			End = Start + StartToEnd;
		}
		
		// Debug::DrawDebugArrow(Start, Start + Up * 200.0, 10.0, FLinearColor::Red, 5.0);
		// Debug::DrawDebugArrow(Start, Start + StartToEnd, 5.0, FLinearColor::Green);
		// Debug::DrawDebugArrow(Start, Start + DirToEnd * 200.0, 5.0, FLinearColor::Yellow);

		if(SidescrollerAssaultSettings.bFadeOverShortDistance)
		{
			FVector DirToEnd = (End - Start).GetSafeNormal();
			End = Start + DirToEnd * SidescrollerAssaultSettings.SpotlightFadeLength;
		}

		SetSpotlightPositionAndInnerRadius(Start, End, Direction);
		SpotlightActor.SetEndLocation(End);
	}

	private FVector GetAimDirection() const
	{
		// if(WeaponUserComponent.IsThrowingOrDetonatingGrenade())
		// {
		// 	FAimingRay AimRay = AimComponent.GetPlayerAimingRay();
		// 	return AimRay.Direction;
		// }

		FVector Direction = FVector::ZeroVector;
		for(AIslandRedBlueWeapon Weapon : WeaponUserComponent.GetWeapons())
		{
			bool bRightWeapon = Weapon.HandType == EIslandRedBlueWeaponHandType::Right;
			if(WeaponUserComponent.IsLeftGrenadeAnimRunning() && !bRightWeapon)
				continue;

			if(WeaponUserComponent.IsRightGrenadeAnimRunning() && bRightWeapon)
				continue;

			Direction += Weapon.ActorForwardVector;
		}

		Direction = Direction.GetSafeNormal();
		return Direction;
	}

	private void SpawnSpotlight()
	{
		SpotlightActor = SpawnActor(WeaponUserComponent.SpotlightActorClass);
		SpotlightActor.ActorRotation = FRotator::MakeFromZ(WeaponUserComponent.Weapons[0].Muzzle.ForwardVector);
		SpotlightActor.SetPlayerOwner(Player);
	}

	private void SetSpotlightPositionAndInnerRadius(FVector Start, FVector End, FVector Direction)
	{
		if(WeaponUserComponent.IsLeftGrenadeAnimRunning() || WeaponUserComponent.IsRightGrenadeAnimRunning())
		{
			SpotlightActor.ActorLocation = Start + Direction * DistanceToStart;
			return;
		}

		FVector Weapon1 = WeaponUserComponent.Weapons[0].Muzzle.WorldLocation;
		FVector Weapon2 = WeaponUserComponent.Weapons[1].Muzzle.WorldLocation;
		FVector Furthest = Weapon1.Distance(End) < Weapon2.Distance(End) ? Weapon2 : Weapon1;
		FVector WeaponToEndDir = (End - Furthest).GetSafeNormal();
		Weapon1 = Weapon1.PointPlaneProject(Furthest, WeaponToEndDir);
		Weapon2 = Weapon2.PointPlaneProject(Furthest, WeaponToEndDir);
		Weapon1 = Weapon1.PointPlaneProject(Furthest, Player.ViewRotation.ForwardVector);
		Weapon2 = Weapon2.PointPlaneProject(Furthest, Player.ViewRotation.ForwardVector);

		SpotlightActor.ActorLocation = (Weapon1 + Weapon2) * 0.5;
		DistanceToStart = Start.Distance(SpotlightActor.ActorLocation);
		SpotlightActor.SetInnerRadius(Weapon1.Distance(Weapon2));
	}

	bool CanEverShowSpotlight() const
	{
		EAimingConstraintType2D ConstraintType = AimComponent.GetCurrentAimingConstraintType();
		switch(ConstraintType)
		{
			case EAimingConstraintType2D::Plane:
			{
				if(!SidescrollerAssaultSettings.bShowSpotlightInTopDown)
					return false;
				break;
			}
			case EAimingConstraintType2D::Spline:
			{
				if(!SidescrollerAssaultSettings.bShowSpotlightInSidescroller)
					return false;
				break;
			}
			case EAimingConstraintType2D::None:
			{
				if(!SidescrollerAssaultSettings.bShowSpotlightIn3D)
					return false;
				break;
			}
			default:
		}

		return true;
	}
}