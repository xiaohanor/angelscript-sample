enum EIslandRedBlueWeaponType
{
	Red,
	Blue,
	MAX
}

enum EIslandRedBlueWeaponUpgradeType
{
	SingleShot,
	Burst,
	Assault,
	OverheatAssault,
	AutoShotgun,
	SidescrollerAssault,
	MAX
}

enum EIslandRedBlueWeaponHandType
{
	Left,
	Right,
	MAX
}

enum EIslandRedBlueShieldType
{
	Red,
	Blue,
	Both
}

enum EIslandRedBlueWeaponAttachSocketType
{
	UnEquipped,
	AttachToThigh,
	AttachToHand,
	MAX
}

namespace IslandRedBlueWeapon
{
	const FName IslandRedBlueBlockedWhileInAnimation = n"IslandRedBlueBlockedWhileInAnimation";
	const FName IslandRedBlueWeapon = n"IslandRedBlueWeapon";
	const FName IslandRedBlueEquipped = n"IslandRedBlueEquipped";
	const FName IslandTargeting = n"IslandTargeting";

	AHazePlayerCharacter GetPlayerForColor(EIslandRedBlueWeaponType Color)
	{
		if(Color == EIslandRedBlueWeaponType::Red)
			return Game::Mio;
		else
			return Game::Zoe;
	}

	EIslandRedBlueWeaponType GetPlayerColor(const AHazePlayerCharacter Player)
	{
		if(Player.IsMio())
			return EIslandRedBlueWeaponType::Red;
		else
			return EIslandRedBlueWeaponType::Blue;
	}

	bool IsPlayerRed(const AHazePlayerCharacter Player)
	{
		return Player.IsMio();
	}

	bool IsPlayerBlue(const AHazePlayerCharacter Player)
	{
		return Player.IsZoe();
	}

	bool PlayerCanHitShieldType(AHazePlayerCharacter Player, EIslandRedBlueShieldType ShieldType)
	{
		if (Player == nullptr)
			return true;

		if(ShieldType == EIslandRedBlueShieldType::Red && IsPlayerRed(Player))
			return true;
		
		if(ShieldType == EIslandRedBlueShieldType::Blue && IsPlayerBlue(Player))
			return true;

		if(ShieldType == EIslandRedBlueShieldType::Both)
			return true;

		return false;
	}

	bool PlayerCanHitOverchargeComponent(AHazePlayerCharacter Player, EIslandRedBlueOverchargeColor Color)
	{
		if(Color == EIslandRedBlueOverchargeColor::Red && IsPlayerRed(Player))
			return true;
		
		if(Color == EIslandRedBlueOverchargeColor::Blue && IsPlayerBlue(Player))
			return true;

		return false;
	}

	// Will return a start location that is in line with the player so you can't hit anything that is between the camera and the player
	FVector GetCameraWeaponTraceStartLocation(AHazePlayerCharacter Player, FVector ViewLocation, FVector TraceEnd)
	{
		const FVector TraceDirection = (TraceEnd - ViewLocation).GetSafeNormal();
		const FVector HorizontalDirection = TraceDirection.VectorPlaneProject(Player.MovementWorldUp).GetSafeNormal();

		auto Plane = FPlane(Player.ActorLocation, HorizontalDirection.IsNearlyZero() ? FVector::UpVector : HorizontalDirection);
		FVector ProjectedPoint = Plane.RayPlaneIntersection(ViewLocation, TraceDirection);

		FVector BottomCapsuleLoc = Player.ActorLocation + FVector::UpVector * 3.0;
		if(ProjectedPoint.Z < BottomCapsuleLoc.Z)
			return FPlane(BottomCapsuleLoc, Player.MovementWorldUp).RayPlaneIntersection(ViewLocation, TraceDirection);

		return ProjectedPoint;
	}

	// Validate if a hit made with a trace from the camera is actually valid or if it is invalid because we hit a force field hole or if camera is on the other side of the force field than the player, etc.
	bool CurrentCameraWeaponTraceHitIsValid(AHazePlayerCharacter Player, FHitResult Hit, const UObject TemporalLogObject)
	{
		if(!Hit.bBlockingHit)
		{
			TemporalLogInvalidHit(Hit, TemporalLogObject, "Not Blocking Hit");
			return false;
		}

		if(Hit.bStartPenetrating)
		{
			TemporalLogInvalidHit(Hit, TemporalLogObject, "Start Penetrating");
			return false;
		}

		// Before we traced from GetCameraWeaponTraceStartLocation, but a bug with spherical force fields came up where the start location would actually be outside the sphere
		// when the player was actually inside, so trace from the camera and check if we hit a spherical force field and do a special case for that.
		//                     \┌─┐
		//					   /└─┘
		//		   -------a--------
		//		 be				   \
		// c	 /					\
		//		/0					 \
		//		-----------------------
		// The above image represents a dome spherical force field (0 is the player capsule), imagine a line trace from the camera through the points a-e-b-c.
		// with the old code GetCameraWeaponTraceStartLocation would return b as the trace start which is outside the force field so c would be the hit
		// e is what we expect to hit since we are inside the force field, a is what we would hit if we just traced from the camera to the destination which is wrong since that is behind the player.
		const FVector CameraTraceStartLocation = GetCameraWeaponTraceStartLocation(Player, Hit.TraceStart, Hit.TraceEnd);
		const float TotalTraceLength = Hit.TraceStart.Distance(Hit.TraceEnd);
		const float CameraStartTime = Hit.TraceStart.Distance(CameraTraceStartLocation) / TotalTraceLength;
		const bool bHitBeforeCameraStart = Hit.Time < CameraStartTime;

#if !RELEASE
		TEMPORAL_LOG(TemporalLogObject).Point("CameraTraceStartLocation", CameraTraceStartLocation, 100.0f);
#endif

		auto ForceField = Cast<AIslandRedBlueForceField>(Hit.Actor);
		if(ForceField == nullptr)
		{
			if(bHitBeforeCameraStart)
			{
				TemporalLogInvalidHit(Hit, TemporalLogObject, "Hit Before Camera Start");
				return false;
			}
			else
			{
				TemporalLogValidHit(Hit, TemporalLogObject, "Hit After Camera Start");
				return true;
			}
		}

		// If this player can't hit the shield however and we are aiming through a hole, we should try to hit something behind so that means this hit is invalid.
		if(ForceField.IsPointInsideHoles(Hit.ImpactPoint))
		{
			TemporalLogInvalidHit(Hit, TemporalLogObject, "Hit Was Inside Hole");
			return false;
		}

		if(ForceField.bIsSphereForceField && ForceField.IsPointInsideSphere(Player.Mesh.GetSocketLocation(n"RightShoulder")))
		{
			FVector Center = ForceField.ActorLocation;
			FVector StartToCenter = Center - Hit.TraceStart;
			float TimeOfForceFieldCenter = (Hit.TraceEnd - Hit.TraceStart).GetSafeNormal().DotProduct(StartToCenter) / TotalTraceLength;
			// This hit was "a" (see above picture) since it was before the center of the force field, so ignore it.
			if(Hit.Time < TimeOfForceFieldCenter)
			{
				TemporalLogInvalidHit(Hit, TemporalLogObject, "Hit Was Before Center Of Sphere Force Field");
				return false;
			}
		}
		else if(bHitBeforeCameraStart)
		{
			TemporalLogInvalidHit(Hit, TemporalLogObject, "Hit Before Camera Start On Force Field");
			return false;
		}

		TemporalLogValidHit(Hit, TemporalLogObject, "Fallback Valid");
		return true;
	}

	void TemporalLogInvalidHit(FHitResult Hit, const UObject TemporalLogObject, FString Reason)
	{
#if !RELEASE
			TEMPORAL_LOG(TemporalLogObject)
				.Value(f"{Hit.Actor} Hit Invalid Reason: ", Reason)
			;
#endif
	}

	void TemporalLogValidHit(FHitResult Hit, const UObject TemporalLogObject, FString Reason)
	{
#if !RELEASE
			TEMPORAL_LOG(TemporalLogObject)
				.Value(f"{Hit.Actor} Hit Valid Reason: ", Reason)
			;
#endif
	}

	UFUNCTION()
	void IslandApplyForcedTarget(AHazePlayerCharacter Player, USceneComponent Target, FInstigator Instigator, bool bAlsoApplyForced2DOverheatWidget = true, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.ApplyForcedTarget(Target, Instigator, bAlsoApplyForced2DOverheatWidget, Priority);
	}

	UFUNCTION()
	void IslandClearForcedTarget(AHazePlayerCharacter Player, FInstigator Instigator, bool bAlsoClearForced2DOverheatWidget = true)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.ClearForcedTarget(Instigator, bAlsoClearForced2DOverheatWidget);
	}

	UFUNCTION()
	void IslandApplyForced2DOverheatWidget(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.ApplyForced2DOverheatWidget(Instigator);
	}

	UFUNCTION()
	void IslandClearForced2DOverheatWidget(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.ClearForced2DOverheatWidget(Instigator);
	}

	UFUNCTION()
	bool IslandIsGrenadeThrown(AHazePlayerCharacter Player)
	{
		auto UserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		return UserComp.IsGrenadeThrown();
	}

	UFUNCTION()
	bool IslandIsGrenadeAttached(AHazePlayerCharacter Player)
	{
		auto UserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		return UserComp.IsGrenadeAttached();
	}

	UFUNCTION()
	void IslandBlockGrenadeThrowing(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto UserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		UserComp.BlockGrenadeThrowing(Instigator);
	}

	UFUNCTION()
	void IslandUnblockGrenadeThrowing(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto UserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		UserComp.UnblockGrenadeThrowing(Instigator);
	}

	UFUNCTION()
	bool IslandIsGrenadeThrowingBlocked(AHazePlayerCharacter Player)
	{
		auto UserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		return UserComp.IsGrenadeThrowingBlocked();
	}

	// Will disable both weapons, mostly used for cutscenes
	UFUNCTION()
	void IslandAddWeaponDisable(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.AddWeaponDisable(Instigator);
	}

	// Will remove a previous disable for both weapons, mostly used for cutscenes
	UFUNCTION()
	void IslandRemoveWeaponDisable(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.RemoveWeaponDisable(Instigator);
	}

	// Will disable a specific weapon, mostly used for cutscenes
	UFUNCTION()
	void IslandAddSpecificWeaponDisable(AHazePlayerCharacter Player, EIslandRedBlueWeaponHandType Hand, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.AddSpecificWeaponDisable(Hand, Instigator);
	}

	// Will remove a previous disable for a specific weapon, mostly used for cutscenes
	UFUNCTION()
	void IslandRemoveSpecificWeaponDisable(AHazePlayerCharacter Player, EIslandRedBlueWeaponHandType Hand, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.RemoveSpecificWeaponDisable(Hand, Instigator);
	}

	UFUNCTION()
	void IslandApplyOverrideBulletClass(AHazePlayerCharacter Player, TSubclassOf<AIslandRedBlueWeaponBullet> OverrideClass, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.ApplyOverrideBulletClass(OverrideClass, Instigator);
	}

	UFUNCTION()
	void IslandClearOverrideBulletClass(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.ClearOverrideBulletClass(Instigator);
	}

	UFUNCTION()
	void IslandAddForceHoldWeaponInHandInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.AddForceHoldWeaponInHandInstigator(Instigator);
	}

	UFUNCTION()
	void IslandRemoveForceHoldWeaponInHandInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.RemoveForceHoldWeaponInHandInstigator(Instigator);
	}
}
