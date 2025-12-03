struct FCoastWaterskiWaveData
{
	UPROPERTY()
	FVector PointOnWave;

	UPROPERTY()
	FVector PointOnWaveNormal;
}

struct FCoastWaterskiAnimData
{
	bool bTransitioningToWingsuit;
	int JumpTrickIndex;
}

UCLASS(Abstract)
class UCoastWaterskiPlayerComponent : UActorComponent
{	
	access ExternalReadOnly = private, * (readonly);
	access WaterskiManager = private, ACoastWaterskiManager;
	access JumpExternalReadOnly = private, UCoastWaterskiJumpCapability, UCoastWaterskiChargeJumpCapability, * (readonly);
	access Jump = private, UCoastWaterskiJumpCapability, UCoastWaterskiChargeJumpCapability;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Settings")
	TSubclassOf<ACoastWaterskiActor> WaterskiActorClass;

	UPROPERTY(Category = "Settings")
	UCoastWaterskiSettings DefaultSettings;

	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(Category = "Settings")
	UMovementGravitySettings GravitySettings;

	/* A reference to the jump feature, is used to determine a random index for a trick animation (since we want this networked) */
	UPROPERTY(Category = "Settings")
	ULocomotionFeatureWaterskiJump JumpFeature;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	TArray<ACoastWaterskiActor> WaterskiActors;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> WaterSkiCamShakeLooping;

	ACoastWaterskiManager WaterskiManager;

	UPROPERTY(BlueprintReadOnly)
	access:ExternalReadOnly USceneComponent CurrentWaterskiAttachPoint;

	access:JumpExternalReadOnly float TimeOfJump = -1.0;

	float DistanceFromAttach;
	float CurrentWorldRadians;
	ALandscape WaterLandscape;
	TArray<FInstigator> WaterskiRopeBlockers;
	TArray<FInstigator> BuoyancyBlockers;
	uint FrameOfDestroyWaterski;
	FCoastWaterskiAnimData AnimData;
	access:ExternalReadOnly float TimeOfStartWaterski;
	bool bLastEnterCameFromWingsuit = false;
	bool bShouldBePushedOffWake = false;
	bool bCurrentlyJumping = false;
	TOptional<uint> FrameOfStopTransitionFromWingsuit;

	TArray<ACoastWaterskiBoostZone> OverlappedBoostZones;
	TArray<FInstigator> SpawnInWingsuitInstigators;

	FHazeAcceleratedFloat AccScale;

	private bool bInternal_WaterskiActive = false;
	private AHazePlayerCharacter Player;
	private UCoastWaterskiSettings Settings;
	private UPlayerMovementComponent MoveComp;
	private float SinOffsetValue;
	private UPerchPointComponent DisabledPerchPointComp;
	private UPlayerHealthComponent HealthComp;
	private FInstigator RespawnWaveInstigator = FInstigator(n"RespawnWaterski");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Settings = UCoastWaterskiSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintPure)
	bool IsWaterskiing()
	{
		return bInternal_WaterskiActive;
	}

	bool IsBuoyancyBlocked()
	{
		return BuoyancyBlockers.Num() != 0;
	}

	bool IsWaterskiRopeBlocked()
	{
		return WaterskiRopeBlockers.Num() != 0;
	}

	void OnWaterskiRopeEnable()
	{
		UCoastWaterskiEffectHandler::Trigger_OnActivateWaterskiRope(Player);
	}

	void OnWaterskiRopeDisable()
	{
		UCoastWaterskiEffectHandler::Trigger_OnDeactivateWaterskiRope(Player);
	}

	void StartWaterskiing(USceneComponent AttachPoint, bool bCameFromWingsuit)
	{
		SetComponentTickEnabled(true);
		
		bLastEnterCameFromWingsuit = bCameFromWingsuit;
		if(bLastEnterCameFromWingsuit)
			WaterskiRopeBlockers.AddUnique(this);

		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		// auto PerchPoint = UPerchPointComponent::Get(AttachPoint.Owner);
		// if(PerchPoint != nullptr)
		// {
		// 	PerchPoint.DisableForPlayer(Player, this);
		// 	DisabledPerchPointComp = PerchPoint;
		// }

		bInternal_WaterskiActive = true;
		CurrentWaterskiAttachPoint = AttachPoint;
		TimeOfStartWaterski = Time::GetGameTimeSeconds();

		WaterskiManager.OnStartWaterski.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Target = bInternal_WaterskiActive ? 1 : KINDA_SMALL_NUMBER;
		AccScale.AccelerateTo(Target, 1.25, DeltaSeconds);
		
		if(Math::IsNearlyEqual(Target, AccScale.Value))
		{
			AccScale.SnapTo(Target);
			SetComponentTickEnabled(false);
		}
		
		WaterskiActors[0].ActorRelativeScale3D = FVector(AccScale.Value, AccScale.Value, AccScale.Value);
		WaterskiActors[1].ActorRelativeScale3D = FVector(AccScale.Value, AccScale.Value, AccScale.Value);
	}

	void StopWaterskiing()
	{
		SetComponentTickEnabled(true);

		if(!IsWaterskiRopeBlocked())
			OnWaterskiRopeDisable();

		if(DisabledPerchPointComp != nullptr)
		{
			DisabledPerchPointComp.EnableForPlayer(Player, this);
			DisabledPerchPointComp = nullptr;
		}

		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		bInternal_WaterskiActive = false;
		FrameOfDestroyWaterski = Time::FrameNumber;

		WaterskiManager.OnStopWaterski.Broadcast(Player);
	}

	bool IsAirborne()
	{
		if(Player.ActorLocation.Z < WaveData.PointOnWave.Z + 50.0)
			return false;

		if(MoveComp.HasGroundContact())
			return false;

		return true;
	}

	// Will return true when player is under water or on the surface
	bool IsInWater() const
	{
		if(MoveComp.HasGroundContact())
			return false;

		if(Player.ActorLocation.Z < WaveData.PointOnWave.Z + 50.0)
			return true;

		return false;
	}

	bool IsOnWaterSurface()
	{
		if(MoveComp.HasGroundContact())
			return false;

		if(Player.ActorLocation.Z < WaveData.PointOnWave.Z + 50.0 && Player.ActorLocation.Z > WaveData.PointOnWave.Z - 50.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	FCoastWaterskiWaveData GetWaveData() const property
	{
		return CoastWaterski::GetWaveData(Player.ActorLocation + Player.ActorHorizontalVelocity * OceanWaves::GetSmoothDelayInSeconds(), this);
	}

	float GetTargetLineLength() const
	{
		float Target = Settings.TargetLineLength;
		float TimeSince = Time::GetGameTimeSince(TimeOfStartWaterski);
		float SinValue = Math::Sin(Math::Fmod(TimeSince, Settings.TargetLineLengthSinCycleDuration) / Settings.TargetLineLengthSinCycleDuration * PI * 2.0 + (Player.IsMio() ? PI : 0.0));

		return Target + SinValue * Settings.TargetLineLengthSinMaxOffset;
	}

	bool GetRespawnTransform(FRespawnLocation& OutLocation) const
	{
		TArray<ASplineActor> RespawnSplines = WaterskiManager.RespawnSplines;
		if(RespawnSplines.Num() == 0)
		{
			PrintError("Please add respawn splines to the waterski manager!");
			return false;
		}

		TArray<FVector> CheckLocations;
		CheckLocations.Add(CurrentWaterskiAttachPoint.WorldLocation - CurrentWaterskiAttachPoint.ForwardVector * (GetTargetLineLength()));
		CheckLocations.Add(CurrentWaterskiAttachPoint.WorldLocation - CurrentWaterskiAttachPoint.ForwardVector.RotateAngleAxis(Settings.MaxWaterskiAngles, FVector::UpVector) * (GetTargetLineLength()));
		CheckLocations.Add(CurrentWaterskiAttachPoint.WorldLocation - CurrentWaterskiAttachPoint.ForwardVector.RotateAngleAxis(-Settings.MaxWaterskiAngles, FVector::UpVector) * (GetTargetLineLength()));

		FVector ClosestRespawnPoint;
		float ClosestSqrDistance = MAX_flt;
		for(auto SplineActor : RespawnSplines)
		{
			UHazeSplineComponent Spline = Spline::GetGameplaySpline(SplineActor);
			for(FVector CheckLocation : CheckLocations)
			{
				FVector Current = Spline.GetClosestSplineWorldLocationToWorldLocation(CheckLocation);
				float CurrentSqrDistance = Current.DistSquaredXY(CheckLocation);

				if(CurrentSqrDistance < ClosestSqrDistance)
				{
					ClosestRespawnPoint = Current;
					ClosestSqrDistance = CurrentSqrDistance;
				}
			}
		}

		FVector Point = ClosestRespawnPoint;
		FCoastWaterskiWaveData Temp = CoastWaterski::GetWaveData(ClosestRespawnPoint, RespawnWaveInstigator);

		FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
		FHitResult Hit = Trace.QueryTraceSingle(ClosestRespawnPoint + FVector::UpVector * 500.0, Temp.PointOnWave);

		if(Hit.bBlockingHit && Hit.Location.Z > Temp.PointOnWave.Z)
			Point = Hit.Location;
		else
			Point = Temp.PointOnWave;
		
		FRotator Rotation = FRotator::MakeFromXZ(CurrentWaterskiAttachPoint.WorldLocation - Point, FVector::UpVector);
		OutLocation.RespawnTransform = FTransform(Rotation, Point);
		OutLocation.bRecalculateOnRespawnTriggered = true;

#if TEST
		for(int i = 0; i < CheckLocations.Num(); i++)
		{
			TEMPORAL_LOG(this)
				.Point(f"Check Location [{i}]", CheckLocations[i], 20.f)
			;
		}

		TEMPORAL_LOG(this).Transform("Respawn Transform", OutLocation.RespawnTransform, 1000.f, 10.f);
		TEMPORAL_LOG(this).HitResults("Respawn Ground Trace", Hit, Trace.Shape, Trace.ShapeWorldOffset);
#endif

		return true;
	}

	ACoastWaterskiBoostZone GetCurrentBoostZone() const property
	{
		if(OverlappedBoostZones.Num() == 0)
			return nullptr;

		return OverlappedBoostZones[OverlappedBoostZones.Num() - 1];
	}
}

namespace CoastWaterski
{
	FCoastWaterskiWaveData GetWaveData(FVector Location, FInstigator Instigator)
	{
		FCoastWaterskiWaveData WaterskiWaterData;

		auto WaterskiPlayerComp = UCoastWaterskiPlayerComponent::Get(Game::Mio);

		if(WaterskiPlayerComp.IsBuoyancyBlocked())
		{
			bool bSet = false;
			auto CollisionContainer = UCoastWaterskiWaveCollisionContainerComponent::GetOrCreate(Game::Mio);
			for(UCoastWaterskiWaveCollisionComponent Comp : CollisionContainer.WaveCollisionComponents)
			{
				UPrimitiveComponent ClosestComp = GetClosestPrimitive(Comp.Owner, Location);
				if(ClosestComp == nullptr)
					continue;

				FBox Bounds = ClosestComp.Bounds.Box;
				FVector ClosestPoint = Bounds.GetClosestPointTo(Location);

				if(!Math::IsNearlyEqual(Location.X, ClosestPoint.X) || !Math::IsNearlyEqual(Location.Y, ClosestPoint.Y))
					continue;

				FVector TraceStart = FVector(Location.X, Location.Y, Bounds.Max.Z + 0.125);
				FVector TraceEnd = FVector(Location.X, Location.Y, Bounds.Min.Z - 0.125);

				FHazeTraceSettings Trace = Trace::InitAgainstComponent(ClosestComp);
				FHitResult Hit = Trace.QueryTraceComponent(TraceStart, TraceEnd);

				if(Hit.bBlockingHit)
				{
					WaterskiWaterData.PointOnWave = Hit.ImpactPoint;
					WaterskiWaterData.PointOnWaveNormal = Hit.ImpactNormal;
					bSet = true;
				}
			}

			if(!bSet)
			{
				WaterskiWaterData.PointOnWave = FVector(Location.X, Location.Y, -MAX_flt);
				WaterskiWaterData.PointOnWaveNormal = FVector::UpVector;
			}
		}
		else
		{
			OceanWaves::RequestWaveData(Instigator, Location);
			if(OceanWaves::IsWaveDataReady(Instigator))
			{
				FWaveData Temp = OceanWaves::GetLatestWaveData(Instigator);
				WaterskiWaterData.PointOnWave = FVector(Location.X, Location.Y, Temp.PointOnWave.Z);
				WaterskiWaterData.PointOnWaveNormal = Temp.PointOnWaveNormal;
			}
			else
			{
				WaterskiWaterData.PointOnWave = FVector(Location.X, Location.Y, OceanWaves::GetOceanWavePaint().TargetLandscape.ActorLocation.Z + 100.0);
				WaterskiWaterData.PointOnWaveNormal = FVector::UpVector;
			}
		}

		return WaterskiWaterData;
	}

	UPrimitiveComponent GetClosestPrimitive(AActor Actor, FVector Location)
	{
		TArray<UPrimitiveComponent> Primitives;
		Actor.GetComponentsByClass(UPrimitiveComponent, Primitives);

		float ClosestSqrDistance = MAX_flt;
		UPrimitiveComponent ClosestComp;
		for(UPrimitiveComponent Comp : Primitives)
		{
			FVector Origin = Comp.GetBoundsOrigin();
			float SqrDist = Origin.DistSquared(Location);

			if(SqrDist < ClosestSqrDistance)
			{
				ClosestSqrDistance = SqrDist;
				ClosestComp = Comp;
			}
		}

		return ClosestComp;
	}
}