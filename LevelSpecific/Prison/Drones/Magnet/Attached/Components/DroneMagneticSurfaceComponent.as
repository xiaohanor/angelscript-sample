struct FOnMagnetDroneStartAttractionParams
{

};

struct FOnMagnetDroneEndAttractionParams
{
	UPROPERTY(BlueprintReadOnly)
	bool bSuccess = false;
};

struct FOnMagnetDroneAttachedParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	FVector Location;
	
	UPROPERTY()
	FVector Normal;
}

struct FOnMagnetDroneDetachedParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

event void FOnMagnetDroneStartAttraction(FOnMagnetDroneStartAttractionParams Params);
event void FOnMagnetDroneEndAttraction(FOnMagnetDroneEndAttractionParams Params);
event void FOnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params);
event void FOnMagnetDroneDetached(FOnMagnetDroneDetachedParams Params);

enum EMagnetDroneAttachedInputMethod
{
	Default,
	TopDown,
	SideScrollerScreenspace,
	SeeSawScreenspace,
	HarpoonGun,
	Custom,
}

enum EMagnetDroneAttachedCustomAxis
{
	LocalX,
	LocalY,
	LocalZ,
	LocalNegativeX,
	LocalNegativeY,
	LocalNegativeZ,

	GlobalX,
	GlobalY,
	GlobalZ,
	GlobalNegativeX,
	GlobalNegativeY,
	GlobalNegativeZ,

	/*
	 * Forward is Right.CrossProduct(WorldUp).
	 * Right is WorldUp.CrossProduct(Forward).
	 */
	Automatic,

	NoInput,
}

enum EMagneticSurfaceComponentCameraType
{
	AutomaticWall,
	NoAutomaticWallCamera,
	AlignWithSurface,
	ActivateCamera
}

/**
 * Component used for the drone magnet attraction ability
 */
 UCLASS(HideCategories = "Debug Activation Cooking Tags Collision")
class UDroneMagneticSurfaceComponent : UActorComponent 
{
	UPROPERTY(EditAnywhere, Category = "Attraction")
	float MaxTargetDistance = MagnetDrone::MaxTargetableDistance_Aim;

	UPROPERTY(EditAnywhere, Category = "Attraction")
	bool bRelativeAttraction = false;

	UPROPERTY(EditAnywhere, Category = "Attached|Camera")
	EMagneticSurfaceComponentCameraType CameraType = EMagneticSurfaceComponentCameraType::ActivateCamera;

	UPROPERTY(EditAnywhere, Category = "Attached|Camera", Meta = (EditCondition = "CameraType == EMagneticSurfaceComponentCameraType::AlignWithSurface", EditConditionHides))
	float AlignCameraWithSurfaceDuration = MagnetDrone::DefaultAlignCameraWithSurfaceDuration;

	UPROPERTY(EditAnywhere, Category = "Attached|Camera", Meta = (EditCondition = "CameraType != EMagneticSurfaceComponentCameraType::ActivateCamera", EditConditionHides))
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(EditAnywhere, Category = "Attached|Camera", Meta = (EditCondition = "CameraType != EMagneticSurfaceComponentCameraType::ActivateCamera && CameraSettings != nullptr", EditConditionHides))
	float CameraSettingsBlend;

	UPROPERTY(EditAnywhere, Category = "Attached|Camera", Meta = (EditCondition = "CameraType != EMagneticSurfaceComponentCameraType::ActivateCamera && CameraSettings != nullptr", EditConditionHides))
	EHazeCameraPriority CameraSettingsPriority = EHazeCameraPriority::Medium;

	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "CameraType == EMagneticSurfaceComponentCameraType::ActivateCamera", EditConditionHides))
	AHazeActor CameraActor;
	UHazeCameraComponent CameraComp;

	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "CameraType == EMagneticSurfaceComponentCameraType::ActivateCamera && CameraActor != nullptr", EditConditionHides))
	float ActivateCameraBlendInTime = 1;

	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "CameraType == EMagneticSurfaceComponentCameraType::ActivateCamera && CameraActor != nullptr", EditConditionHides))
	float ActivateCameraBlendOutTime = 1;

	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "CameraType == EMagneticSurfaceComponentCameraType::ActivateCamera && CameraActor != nullptr", EditConditionHides))
	float ActivateCameraWaitUntilDeactivateDuration = 0.5;

	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "CameraType == EMagneticSurfaceComponentCameraType::ActivateCamera && CameraActor != nullptr", EditConditionHides))
	EHazeCameraPriority ActivateCameraPriority = EHazeCameraPriority::Low;

	UPROPERTY(EditAnywhere, Category = "Attached|Input")
	EMagnetDroneAttachedInputMethod InputMethod;

	UPROPERTY(EditAnywhere, Category = "Attached|Input", Meta = (EditCondition = "InputMethod == EMagnetDroneAttachedInputMethod::Custom"))
	EMagnetDroneAttachedCustomAxis CustomForwardAxis = EMagnetDroneAttachedCustomAxis::LocalZ;

	UPROPERTY(EditAnywhere, Category = "Attached|Input", Meta = (EditCondition = "InputMethod == EMagnetDroneAttachedInputMethod::Custom"))
	EMagnetDroneAttachedCustomAxis CustomRightAxis = EMagnetDroneAttachedCustomAxis::LocalY;

	UPROPERTY(EditAnywhere, Category = "Attached|Apply Settings")
	UDroneMovementSettings MovementSettings;

	UPROPERTY(EditAnywhere, Category = "Attached|Apply Settings")
	UMagnetDroneSettings MagnetSettings;

	UPROPERTY(Category = "Attached|Attract Jump")
	bool bAttractJumpInheritVelocity = false;

	UPROPERTY(Category = "Attached|Attract Jump", Meta = (EditCondition = "bAttractJumpInheritVelocity", UIMin = "0.0", UIMax = "1.0"))
	float AttractJumpInheritVelocityFactor = 0.75;

	UPROPERTY(EditAnywhere, Category = "Attached|Top Down")
	bool bForceMoveToHeight = false;

	UPROPERTY(EditAnywhere, Category = "Attached|Top Down", Meta = (EditCondition = "bForceMoveToHeight"))
	float ForceMoveToHeight = 0.0;

	/**
	 * Should the drone detach if a flat ground surface is found underneath the drone, even when attached to this surface?
	 */
	UPROPERTY(EditAnywhere, Category = "Detach")
	bool bDetachIfFloorFound = false;

	/**
	 * If true, we can still attract, but will immediately detach. Use for when we just want to smash into something.
	 */
	UPROPERTY(EditAnywhere, Category = "Detach")
	bool bImmediatelyDetach = false;

	UPROPERTY()
	FOnMagnetDroneStartAttraction OnMagnetDroneStartAttraction;

	UPROPERTY()
	FOnMagnetDroneEndAttraction OnMagnetDroneEndAttraction;

	UPROPERTY()
    FOnMagnetDroneAttached OnMagnetDroneAttached;

	UPROPERTY()
    FOnMagnetDroneDetached OnMagnetDroneDetached;

	TArray<UDroneMagneticZoneComponent> MagneticZones;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if EDITOR
		TArray<UDroneMagneticSurfaceComponent> SurfaceComps;
		GetOwner().GetComponentsByClass(SurfaceComps);
		if(SurfaceComps.Num() > 1)
			PrintError(f"There are more than 1 UDroneMagneticSurfaceComponent present on {Owner.GetFullName()}!");
#endif

		OnMagnetDroneAttached.AddUFunction(this, n"OnAttached");
		OnMagnetDroneDetached.AddUFunction(this, n"OnDetached");

		if(CameraType == EMagneticSurfaceComponentCameraType::ActivateCamera)
		{
			if(CameraActor == nullptr)
			{
				PrintError(f"SurfaceComp attached to {Owner.GetFullName()} has CameraType set to ActivateCamera, but no CameraActor is assigned!");
			}
			else
			{
				CameraComp = UHazeCameraComponent::Get(CameraActor);
				if(CameraComp == nullptr)
				{
					PrintError(f"SurfaceComp attached to {Owner.GetFullName()} has CameraActor assigned that does not have a UHazeCameraComponent!");
				}
			}
		}
	}

	bool ShouldFallOffFromZones(FVector Point) const
	{
		bool bHadFallOffIfOutsideZone = false;
		bool bIsInsideAtLeastOneZone = false;
		for(UDroneMagneticZoneComponent Zone : MagneticZones)
		{
			switch(Zone.GetZoneType())
			{
				case EMagnetDroneZoneType::FallOffIfOutside:
				{
					bHadFallOffIfOutsideZone = true;
					const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
					if (DistanceFromPoint < KINDA_SMALL_NUMBER)
						bIsInsideAtLeastOneZone = true;

					break;
				}

				case EMagnetDroneZoneType::FallOffIfInside:
				{
					const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
					if (DistanceFromPoint < KINDA_SMALL_NUMBER)
						return true;

					break;
				}

				case EMagnetDroneZoneType::ConstrainToWithin:
					break;

				case EMagnetDroneZoneType::ConstrainToOutside:
					break;
			}
		}

		if(bHadFallOffIfOutsideZone)
			return !bIsInsideAtLeastOneZone;
		else
			return false;
	}

	/**
	 * @param bIgnoreConstraints If true, only Fall Off zones will count as non-valid magnetic zones
	 */
	bool IsValidMagneticLocation(FVector Point, bool bIgnoreConstraints)
	{
		bool bHadFallOffIfOutsideZone = false;
		bool bIsInsideAtLeastOneZone = false;

		bool bHadConstrainToWithinZone = false;
		bool bIsInsideAtLeastOneConstrainToWithinZone = false;

		for(UDroneMagneticZoneComponent Zone : MagneticZones)
		{
			switch(Zone.GetZoneType())
			{
				case EMagnetDroneZoneType::FallOffIfOutside:
				{
					bHadFallOffIfOutsideZone = true;
					const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
					if (DistanceFromPoint < 1)
						bIsInsideAtLeastOneZone = true;

					break;
				}

				case EMagnetDroneZoneType::FallOffIfInside:
				{
					const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
					if (DistanceFromPoint < 1)
						return false;

					break;
				}

				case EMagnetDroneZoneType::ConstrainToWithin:
				{
					if(bIgnoreConstraints)
						break;

					bHadConstrainToWithinZone = true;
					const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
					if (DistanceFromPoint < 1)
						bIsInsideAtLeastOneConstrainToWithinZone = true; 

					break;
				}

				case EMagnetDroneZoneType::ConstrainToOutside:
				{
					if(bIgnoreConstraints)
						break;

					const float DistanceFromPoint = Zone.DistanceFromPoint(Point, true);
					if (DistanceFromPoint < 1)
						return false;

					break;
				}
			}
		}

		if(bHadFallOffIfOutsideZone)
			return bIsInsideAtLeastOneZone;

		if(!bIgnoreConstraints)
		{
			if(bHadConstrainToWithinZone)
				return bIsInsideAtLeastOneConstrainToWithinZone;
		}

		return true;
	}

	FVector GetCustomAxis(FVector WorldUp, EMagnetDroneAttachedCustomAxis Axis)
	{
		switch(Axis)
		{
			case EMagnetDroneAttachedCustomAxis::LocalX:
				return Owner.ActorForwardVector;

			case EMagnetDroneAttachedCustomAxis::LocalY:
				return Owner.ActorRightVector;

			case EMagnetDroneAttachedCustomAxis::LocalZ:
				return Owner.ActorUpVector;


			case EMagnetDroneAttachedCustomAxis::LocalNegativeX:
				return Owner.ActorForwardVector * -1;

			case EMagnetDroneAttachedCustomAxis::LocalNegativeY:
				return Owner.ActorRightVector * -1;

			case EMagnetDroneAttachedCustomAxis::LocalNegativeZ:
				return Owner.ActorUpVector * -1;


			case EMagnetDroneAttachedCustomAxis::GlobalX:
				return FVector::ForwardVector;

			case EMagnetDroneAttachedCustomAxis::GlobalY:
				return FVector::RightVector;

			case EMagnetDroneAttachedCustomAxis::GlobalZ:
				return FVector::UpVector;


			case EMagnetDroneAttachedCustomAxis::GlobalNegativeX:
				return FVector::ForwardVector * -1;

			case EMagnetDroneAttachedCustomAxis::GlobalNegativeY:
				return FVector::RightVector * -1;

			case EMagnetDroneAttachedCustomAxis::GlobalNegativeZ:
				return FVector::UpVector * -1;


			case EMagnetDroneAttachedCustomAxis::Automatic:
			{
				if(Axis == CustomForwardAxis)
				{
					check(CustomRightAxis != EMagnetDroneAttachedCustomAxis::Automatic);
					const FVector RightAxis = GetCustomAxis(WorldUp, CustomRightAxis);
					return RightAxis.CrossProduct(WorldUp).GetSafeNormal();

				}
				else if(Axis == CustomRightAxis)
				{
					check(CustomForwardAxis != EMagnetDroneAttachedCustomAxis::Automatic);
					const FVector ForwardAxis = GetCustomAxis(WorldUp, CustomForwardAxis);
					return WorldUp.CrossProduct(ForwardAxis).GetSafeNormal();
				}

				break;
			}

			case EMagnetDroneAttachedCustomAxis::NoInput:
				return FVector::ZeroVector;
		}

		check(false);
		return FVector::UpVector;
	}

	UFUNCTION()
	private void OnAttached(FOnMagnetDroneAttachedParams Params)
	{
		if(CameraType != EMagneticSurfaceComponentCameraType::ActivateCamera && CameraSettings != nullptr)
			Params.Player.ApplyCameraSettings(CameraSettings, CameraSettingsBlend, this, CameraSettingsPriority);

		if(MovementSettings != nullptr)
			Params.Player.ApplySettings(MovementSettings, this, EHazeSettingsPriority::Gameplay);

		if(MagnetSettings != nullptr)
			Params.Player.ApplySettings(MagnetSettings, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION()
	private void OnDetached(FOnMagnetDroneDetachedParams Params)
	{
		if(MovementSettings != nullptr || MagnetSettings != nullptr)
			Params.Player.ClearSettingsByInstigator(this);

		if(CameraSettings != nullptr)
			Params.Player.ClearCameraSettingsByInstigator(this);
	}
};

#if EDITOR
class UDroneMagneticSurfaceComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDroneMagneticSurfaceComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto SurfaceComp = Cast<UDroneMagneticSurfaceComponent>(Component);
		if(SurfaceComp == nullptr)
			return;

		if(SurfaceComp.bForceMoveToHeight)
		{
			FVector Location = SurfaceComp.Owner.ActorLocation;
			Location.Z += SurfaceComp.ForceMoveToHeight;
			DrawWireBox(Location, FVector(25, 25, 0), FQuat::Identity, FLinearColor::DPink, 3);
			DrawWireBox(Location, FVector(50, 50, 0), FQuat::Identity, FLinearColor::DPink, 3);
			DrawWireBox(Location, FVector(75, 75, 0), FQuat::Identity, FLinearColor::DPink, 3);
			DrawWireBox(Location, FVector(100, 100, 0), FQuat::Identity, FLinearColor::DPink, 3);
		}
	}
}
#endif