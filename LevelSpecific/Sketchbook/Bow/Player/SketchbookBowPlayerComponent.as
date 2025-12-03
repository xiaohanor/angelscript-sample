/**
 * 
 */
UCLASS(Abstract, HideCategories="Cooking Collision AssetUserData ComponentReplication Variable Activation")
class USketchbookBowPlayerComponent : UActorComponent
{
    UPROPERTY(EditDefaultsOnly, Category = "Bow")
	USkeletalMesh BowMesh;

    UPROPERTY(EditDefaultsOnly, Category = "Bow")
	UClass AnimBlueprint;

    UPROPERTY(EditDefaultsOnly, Category = "Bow")
	UStaticMesh ArrowMesh;

    UPROPERTY(EditDefaultsOnly, Category = "Bow")
	UStaticMeshComponent ArrowAnimMeshComponent;

	UPROPERTY(EditDefaultsOnly, Category = "Arrow")
	TSubclassOf<ASketchbookArrow> ArrowClass;

	UPROPERTY(EditDefaultsOnly, Category = "Arrow")
	TSubclassOf<ASketchbookArrowFire> ArrowFireClass;

	AHazePlayerCharacter Player = nullptr;
	USketchbookBowSettings BowSettings;
	USketchbookArrowSettings ArrowSettings;
	UPlayerAimingComponent AimComp;

	UHazeSkeletalMeshComponentBase BowMeshComponent;

    protected float ChargeFactor_Internal = 0.0;
	
	bool bIsAimingBow = false;
	bool bIsChargingBow = false;
	bool bIsFiringBow = false;

	bool bUseFire = false;

	FHazeRuntimeSpline AimTrajectorySpline;

	UHazeActorNetworkedSpawnPoolComponent SpawnPoolComponent;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference MioBowSoundDef;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference ZoeBowSoundDef;
	
	FVector AnimLocalAimDir;  // For animation only

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BowSettings = USketchbookBowSettings::GetSettings(Player);
		ArrowSettings = USketchbookArrowSettings::GetSettings(Player);
		AimComp = UPlayerAimingComponent::Get(Owner);
		SpawnPoolComponent = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(ArrowClass, Player);

		FSoundDefReference BowSoundDef = Player.IsMio() ? MioBowSoundDef : ZoeBowSoundDef;
		if(BowSoundDef.SoundDef.IsValid())
			BowSoundDef.SpawnSoundDefAttached(Player);
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("Is Using Bow", IsUsingBow())

			.Value("Aiming;Is Aiming", IsAiming())
			.Value("Aiming;Has Auto Aim Target", HasAutoAimTarget())

			.Value("Charge;IsCharging", IsCharging())
			.Value("Charge;Charge Factor", ChargeFactor_Internal)
			.Value("Charge;Is Fully Charged", IsFullyCharged())

			.Value("Firing;IsFiring", IsFiring())
		;
	}
	#endif

	bool IsAiming() const
	{
		if(AimComp.IsAiming(this))
			return true;

		if(bIsAimingBow)
			return true;

		return false;
	}

	bool IsCharging() const
	{
		return bIsChargingBow;
	}

	bool IsFiring() const
	{
		return bIsFiringBow;
	}

	bool IsUsingBow() const
	{
		return bIsAimingBow || bIsFiringBow;
	}

    bool HasAutoAimTarget() const
	{
		if(!IsAiming())
			return false;

		const FAimingResult AimResult = AimComp.GetAimingTarget(this);
		return AimResult.AutoAimTarget != nullptr;
	}

    FVector GetArrowSpawnLocation() const
    {
        FTransform SocketTransform = BowMeshComponent.GetSocketTransform(n"Base");
		FVector SpawnLocation = SocketTransform.Location + SocketTransform.Rotation.ForwardVector * 20;
		//Debug::DrawDebugPoint(SpawnLocation, 1);
		return SpawnLocation;
    }

    bool IsFullyCharged() const
    {
        return GetChargeFactor() > (1.0 - KINDA_SMALL_NUMBER);
    }

	void SetChargeFactor(float InChargeFactor)
	{
		ChargeFactor_Internal = Math::Clamp(InChargeFactor, 0.0, 1.0);
	}

	UFUNCTION(BlueprintPure)
	float GetChargeFactor() const
	{
		return ChargeFactor_Internal;
	}

	FTraversalTrajectory CalculateLaunchTrajectory() const
	{
		const float Speed = GetArrowSpeed();
		const float Gravity = GetArrowGravity();
		const FVector Origin = GetArrowSpawnLocation();

		FTraversalTrajectory LaunchTrajectory;
		LaunchTrajectory.LaunchLocation = Origin;
		LaunchTrajectory.Gravity = FVector::DownVector * Gravity;

		if(!BowSettings.bLineTraceAim)
		{
			if(ShouldAutoAim())
			{
				if(CalculateAutoAimTrajectory(LaunchTrajectory))
					return LaunchTrajectory;
			}

			// No auto aim target, just fire in the direction we are aiming
			LaunchTrajectory.LaunchVelocity = AimComp.GetPlayerAimingRay().Direction * Speed;
			return LaunchTrajectory;
		}

		FSketchbookBowTraceForTargetResult TraceResult = TraceForTarget();

		if(TraceResult.bHit)
		{
			LaunchTrajectory.LandLocation = TraceResult.HitLocation;
			LaunchTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(LaunchTrajectory.LaunchLocation, LaunchTrajectory.LandLocation, Gravity, Speed);
		}
		else
		{
			const FVector AimLine = TraceResult.TraceEnd - TraceResult.TraceStart;
			LaunchTrajectory.LandLocation = TraceResult.TraceStart + AimLine * Math::Max(GetChargeFactor(), 0.2);
			LaunchTrajectory.LaunchVelocity = AimLine.GetSafeNormal() * Speed;
		}

		return LaunchTrajectory;
	}

	bool ShouldAutoAim() const
	{
		if(ChargeFactor_Internal < BowSettings.MinimumChargeForAutoAim)
			return false;

		if(!Player.IsUsingGamepad())
			return false;

		return true;
	}

	bool CalculateAutoAimTrajectory(FTraversalTrajectory&out OutTrajectory) const
	{
		auto AutoAimTargetable = UPlayerTargetablesComponent::Get(Player).GetPrimaryTarget(USketchbookBowAutoAimComponent);
		if(AutoAimTargetable == nullptr)
			return false;

		const float Speed = GetArrowSpeed();
		const float Gravity = GetArrowGravity();
		const FVector Origin = GetArrowSpawnLocation();

		FTraversalTrajectory LaunchTrajectory;
		LaunchTrajectory.LaunchLocation = Origin;
		LaunchTrajectory.Gravity = FVector::DownVector * Gravity;
		
		FVector TargetLocation = AutoAimTargetable.WorldLocation.VectorPlaneProject(FVector::ForwardVector);

		// Rough calculation of time to hit the target if a straight line and no deceleration
		float DistanceToTarget = LaunchTrajectory.LaunchLocation.Distance(TargetLocation);
		float TimeToHit = DistanceToTarget / Speed;

		// Calculate the horizontal speed needed to travel the horizontal distance
		float HorizontalDistance = Math::Abs((TargetLocation - LaunchTrajectory.LaunchLocation).Y);
		float HorizontalSpeed = HorizontalDistance / TimeToHit;


		// First trajectory, aiming at the targets current location
		LaunchTrajectory.LandLocation = TargetLocation;
		LaunchTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Origin, TargetLocation, Gravity, HorizontalSpeed);

		//LaunchTrajectory.DrawDebug(FLinearColor::Red, 3);

		// Get the velocity of the target
		FVector TargetVelocity = AutoAimTargetable.AverageVelocity;
		
		//Print(f"{TargetVelocity.Size()=}");
		if(Math::Abs(TargetVelocity.Size()) > ArrowSettings.MaxTargetVelocity)
			return false;

		// Calculate where we think the target will actually be when we hit the original location
		FVector PredictedLocation = TargetLocation + (TargetVelocity * TimeToHit) * AutoAimTargetable.PredictionModifier;

		// Recalculate the horizontal speed based on the first trajectory
		TimeToHit = LaunchTrajectory.GetTotalTime();
		HorizontalDistance = Math::Abs((PredictedLocation - LaunchTrajectory.LaunchLocation).Y);
		HorizontalSpeed = HorizontalDistance / TimeToHit;

		// Calculate a second trajectory based on the time and speed from the first, this time aiming for the predicted location
		LaunchTrajectory.LandLocation = PredictedLocation;
		LaunchTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Origin, PredictedLocation, Gravity, HorizontalSpeed);

		//LaunchTrajectory.DrawDebug(FLinearColor::Blue, 3);

		OutTrajectory = LaunchTrajectory;
		return true;
	}

	FSketchbookBowTraceForTargetResult TraceForTarget() const
	{
		FAimingResult AimResult = AimComp.GetAimingTarget(this);

		const FVector TraceStart = AimResult.AimOrigin;
		const FVector TraceEnd = TraceStart + AimResult.AimDirection * Sketchbook::Bow::MaxShootDistance;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ETraceTypeQuery::Visibility);
		TraceSettings.UseLine();
        TraceSettings.IgnorePlayers();
		
		const FHitResult Hit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
		
		if(Hit.bBlockingHit)
		{
			USketchbookBowAutoAimComponent AutoAimComp = USketchbookBowAutoAimComponent::Get(Hit.Actor);
			if(AutoAimComp != nullptr)
			{
				FSketchbookBowTraceForTargetResult Result;
				Result.bHit = true;
				Result.HitLocation = AutoAimComp.WorldLocation;
				Result.TraceStart = TraceStart;
				Result.TraceEnd = TraceEnd;
				return Result;
			}
		}

		return FSketchbookBowTraceForTargetResult(Hit);
	}

	float GetArrowSpeed() const
	{
		return Math::Lerp(ArrowSettings.MinLaunchSpeed, ArrowSettings.MaxLaunchSpeed, GetChargeFactor());
	}

    float GetArrowGravity() const
	{
		return Math::Lerp(ArrowSettings.MinChargeGravity, ArrowSettings.MaxChargeGravity, GetChargeFactor());
	}
}

struct FSketchbookBowTraceForTargetResult
{
	FSketchbookBowTraceForTargetResult(FHitResult Hit)
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

struct FSketchbookBowTargetData
{
	FVector Origin;
	TOptional<FVector> TargetLocation;
	FVector Velocity;
	float Gravity;

	FVector GetDirection() const
	{
		if(TargetLocation.IsSet())
			return (TargetLocation.Value - Origin).GetSafeNormal();
		else
			return Velocity.GetSafeNormal();
	}
}