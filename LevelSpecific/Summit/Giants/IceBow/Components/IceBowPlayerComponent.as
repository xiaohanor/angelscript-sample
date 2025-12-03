/**
 * 
 */
UCLASS(Abstract, HideCategories="Cooking Collision AssetUserData ComponentReplication Variable Activation")
class UIceBowPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(NotEditable, BlueprintReadOnly, Category = "IceBow")
	UStaticMeshComponent IceBowMeshComponent;

	UPROPERTY(Category = "IceBow")
	protected UIceBowSettings DefaultBowSettings;

	UPROPERTY()
	UMaterialParameterCollection WindParams;

	AHazePlayerCharacter Player = nullptr;
	UPlayerAimingComponent AimComp = nullptr;
	UPlayerTargetablesComponent PlayerTargetableComp;

    protected float ChargeFactor_Internal = 0.0;
	
	bool bIsAimingIceBow = false;
	bool bIsChargingIceBow = false;
	bool bIsFiringIceBow = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		PlayerTargetableComp = UPlayerTargetablesComponent::Get(Owner);

		Player.ApplyDefaultSettings(DefaultBowSettings);
	}

	bool GetIsAiming() const
	{
		if(AimComp.IsAiming(this))
			return true;

		if(bIsAimingIceBow)
			return true;

		return false;
	}

	bool GetIsCharging() const
	{
		return bIsChargingIceBow;
	}

	bool GetIsFiring() const
	{
		return bIsFiringIceBow;
	}

	bool GetIsUsingIceBow() const
	{
		return bIsAimingIceBow || bIsFiringIceBow;
	}

    void ShowAutoAimWidgets()
	{
		PlayerTargetableComp.ShowWidgetsForTargetables(
			UIceBowAutoAimTargetComponent,
			BowSettings.AutoAimTargetWidget
		);
	}
    bool HasAutoAimTarget() const
	{
		const FAimingResult AimResult = AimComp.GetAimingTarget(this);
		return AimResult.AutoAimTarget != nullptr;
	}

    FVector GetArrowSpawnLocation() const
    {
        return IceBowMeshComponent.WorldLocation;
    }

    bool IsFullyCharged() const
    {
        return GetChargeFactor() > (1.0 - KINDA_SMALL_NUMBER);
    }

	void SetChargeFactor(float InChargeFactor)
	{
		ChargeFactor_Internal = Math::Clamp(InChargeFactor, 0.0, 1.0);

		float TargetFov = BowSettings.AimMaxFOV;
		const float FOV = Math::Lerp(0.0, TargetFov, BowSettings.ChargeFOVCurve.GetFloatValue(ChargeFactor_Internal));
		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(FOV, this, 0.5);
	}

	UFUNCTION(BlueprintPure)
	float GetChargeFactor() const
	{
		return ChargeFactor_Internal;
	}

	FIceBowTargetData CalculateTargetData(EIceBowArrowType ArrowType)
	{
		float Speed, Gravity;
		switch(ArrowType)
		{
			case EIceBowArrowType::Ice:
			{
				auto IceArrowPlayerComp = UIceArrowPlayerComponent::Get(Owner);
				Speed = IceArrowPlayerComp.GetArrowSpeed();
				Gravity = IceArrowPlayerComp.GetArrowGravity();
				break;
			}
			case EIceBowArrowType::Blizzard:
			{
				auto BlizzardArrowPlayerComp = UBlizzardArrowPlayerComponent::Get(Owner);
				Speed = BlizzardArrowPlayerComp.GetArrowSpeed();
				Gravity = BlizzardArrowPlayerComp.GetArrowGravity();
				break;
			}
			case EIceBowArrowType::Rope:
			{
				auto RopeArrowPlayerComp = URopeArrowPlayerComponent::Get(Owner);
				Speed = RopeArrowPlayerComp.GetArrowSpeed();
				Gravity = RopeArrowPlayerComp.GetArrowGravity();
				break;
			}
			case EIceBowArrowType::Wind:
			{
				auto WindArrowPlayerComp = UWindArrowPlayerComponent::Get(Owner);
				Speed = WindArrowPlayerComp.GetArrowSpeed();
				Gravity = WindArrowPlayerComp.GetArrowGravity();
				break;
			}
		}

		FVector Origin = GetArrowSpawnLocation();

		FIceBowTargetData TargetData = FIceBowTargetData();

		FIceBowTraceForTargetResult TraceResult = TraceForTarget();

		if(TraceResult.bHit)
		{
			TargetData.Origin = Origin;
			TargetData.TargetLocation = TraceResult.HitLocation;
		}
		else
		{
			TargetData.Origin = Origin;
			const FVector AimLine = TraceResult.TraceEnd - TraceResult.TraceStart;
			TargetData.TargetLocation = TraceResult.TraceStart + AimLine * Math::Max(GetChargeFactor(), 0.2);
		}

		TargetData.Gravity = Gravity;
		TargetData.Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(TargetData.Origin, TargetData.TargetLocation, Gravity, Speed);

		return TargetData;
	}

	FIceBowTraceForTargetResult TraceForTarget()
	{
		FAimingResult AimResult = AimComp.GetAimingTarget(this);

		const FVector TraceStart = AimResult.AimOrigin;
		const FVector TraceEnd = TraceStart + AimResult.AimDirection * IceBow::MaxShootDistance;

		// If we hit an auto aim, then we have already done a trace and don't need to do another.
		if(AimResult.AutoAimTarget != nullptr)
		{
			FIceBowTraceForTargetResult Result;
			Result.bHit = true;
			Result.HitLocation = AimResult.AutoAimTargetPoint;
			Result.TraceStart = TraceStart;
			Result.TraceEnd = TraceEnd;
			return Result;
		}

		FHazeTraceSettings Settings = Trace::InitChannel(ETraceTypeQuery::Visibility);
		Settings.UseLine();

		if(IceBow::ShouldIgnoreOtherPlayer())
            Settings.IgnorePlayers();
        else
            Settings.IgnoreActor(Player);
		
		const FHitResult Hit = Settings.QueryTraceSingle(TraceStart, TraceEnd);

		return FIceBowTraceForTargetResult(Hit);
	}

	UIceBowSettings GetBowSettings() const property
	{
		return UIceBowSettings::GetSettings(Player);
	}
}

struct FIceBowTraceForTargetResult
{
	FIceBowTraceForTargetResult(FHitResult Hit)
	{
		bHit = Hit.bBlockingHit;
		HitLocation = Hit.Location;
		TraceStart = Hit.TraceStart;
		TraceEnd = Hit.TraceEnd;
	}

	bool bHit;
	FVector HitLocation;
	FVector TraceStart;
	FVector TraceEnd;
}

struct FIceBowTargetData
{
	FVector Origin;
	FVector TargetLocation;
	FVector Velocity;
	float Gravity;

	FVector GetDirection() const
	{
		return (TargetLocation - Origin).GetSafeNormal();
	}
}