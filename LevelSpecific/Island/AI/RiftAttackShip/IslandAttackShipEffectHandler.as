UCLASS(Abstract)
class UIslandAttackShipEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartCrashTrajectory(FIslandAttackShipOnStartCrashTrajectoryParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCrashImpact(FIslandAttackShipOnCrashImpactParams Params) {}
    
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphingTrackingLaser(FIslandAttackShipLaserTrackingTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraphingTrackingLaser() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBeamAttackStartTelegraphing(FIslandAttackShipBeamTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBeamAttackStopTelegraphing() {}
}

struct FIslandAttackShipOnPilotDeathParams
{
	FIslandAttackShipOnPilotDeathParams(AHazePlayerCharacter Player = nullptr)
	{
		LastAttacker = Player;
	}

	UPROPERTY()
	AHazePlayerCharacter LastAttacker;
}

struct FIslandAttackShipOnStartCrashTrajectoryParams
{
	FIslandAttackShipOnStartCrashTrajectoryParams(USceneComponent AttachComp)
	{
		AttachToComp = AttachComp;
	}
	
	UPROPERTY()
	USceneComponent AttachToComp;
}

struct FIslandAttackShipOnCrashImpactParams
{
	FIslandAttackShipOnCrashImpactParams(FVector Location, FVector Normal)
	{
		ImpactLocation = Location;
		ImpactNormal = Normal;
	}

	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;
}

struct FIslandAttackShipOnPilotTakeDamageParams
{
	FIslandAttackShipOnPilotTakeDamageParams(FVector Location)
	{
		HitLocation = Location;
	}

	UPROPERTY()
	FVector HitLocation;
}

struct FIslandAttackShipOnMoveStartParams
{
	FIslandAttackShipOnMoveStartParams()
	{
	}

	UPROPERTY()
	USceneComponent PlaceHolder; // will presumably be replaced by some component representing a jet or such.
}

struct FIslandAttackShipLaserTrackingTelegraphingParams
{
	FIslandAttackShipLaserTrackingTelegraphingParams(UIslandAttackShipTrackingLaserComponent& LaserComp)
	{
		TrackingLaserComp = LaserComp;
	}

	UPROPERTY()
	UIslandAttackShipTrackingLaserComponent TrackingLaserComp;
}

struct FIslandAttackShipBeamTelegraphingParams
{
	FIslandAttackShipBeamTelegraphingParams(FVector InMuzzleLocation, UIslandAttackShipTrackingLaserComponent& LaserComp)
	{
		MuzzleLocation = InMuzzleLocation;
		TrackingLaserComp = LaserComp;
	}

	UPROPERTY()
	FVector MuzzleLocation;

	UPROPERTY()
	UIslandAttackShipTrackingLaserComponent TrackingLaserComp;
}