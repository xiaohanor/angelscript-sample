UCLASS(Abstract)
class UIslandWalkerEffectHandler : UHazeEffectEventHandler
{
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerShellCasingsLauncher ShellCasingsLauncher;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		ShellCasingsLauncher = UIslandWalkerShellCasingsLauncher::Get(Owner);		
	}

	UFUNCTION(BlueprintPure)
	float GetArenaHeight()
	{
		if (WalkerComp.ArenaLimits == nullptr)
			return 0.0;
		return WalkerComp.ArenaLimits.Height;
	} 

	UFUNCTION()
	void UpdateShellCasings(UNiagaraComponent ShellsEffect)
	{
		NiagaraDataInterfaceArray::SetNiagaraArrayPosition(ShellsEffect, n"Positions", ShellCasingsLauncher.Locations);
		NiagaraDataInterfaceArray::SetNiagaraArrayVector(ShellsEffect, n"Velocities", ShellCasingsLauncher.Velocities);
		NiagaraDataInterfaceArray::SetNiagaraArrayBool(ShellsEffect, n"ParticleIsColliding", ShellCasingsLauncher.bHasReachedFloor);
		NiagaraDataInterfaceArray::SetNiagaraArrayFloat(ShellsEffect, n"ParticleNormalizedAge_Code", ShellCasingsLauncher.AgeFractions);
	}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnShellExplosion(FIslandWalkerShellExplosionEventData Data) {}

	// The owner died (IslandWalker.OnDeath)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphLaser(FIslandWalkerLaserEventData Data) {}

	// Laser started firing (IslandWalker.OnStartedLaser)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartedLaser(FIslandWalkerLaserEventData Data) {}

	// Laser stopped firing (IslandWalker.OnStoppedLaser)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStoppedLaser() {}

	// Laser beams crossed each other
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCrossedLasers() {}

	// Laser beams resume after pausing from having crossed
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCrossedLasersResume() {}

	// A minion was spawned (IslandWalker.OnSpawnedMinion)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSpawnedMinion(FIslandWalkerSpawnedMinionEventData Data) {}

	// Jump attack landing
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnJumpAttackLanded(FIslandWalkerJumpAttackLandedEventData Data) {}

	// Splash attack landing
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSplashAttackLanded() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLegAttack(FIslandWalkerLegAttackEventData Data) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnNeckTargetPowerUp(FIslandWalkerNeckTargetEventData Data){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnNeckTargetPowerDown(FIslandWalkerNeckTargetEventData Data){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCablesTargetPowerUp(FIslandWalkerCablesTargetEventData Data){}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCablesTargetPowerDown(FIslandWalkerCablesTargetEventData Data){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSuspensionCableStartMoving(FIslandWalkerCableEventData Data){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSuspensionCableLatchOn(FIslandWalkerCableEventData Data){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSuspensionCableBreak(FIslandWalkerCableEventData Data){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSuspensionCableWeaken(FIslandWalkerCableEventData Data){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClusterMineLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClusterMineTelegraph() {}

}

struct FIslandWalkerJumpAttackLandedEventData
{
	FIslandWalkerJumpAttackLandedEventData(TArray<FVector> InLegLocations)
	{
		LegLocations = InLegLocations;
	}

	UPROPERTY(BlueprintReadOnly)
	TArray<FVector> LegLocations;
}

struct FIslandWalkerCableEventData
{
	UPROPERTY(BlueprintReadOnly)
	AIslandWalkerSuspensionCable Cable;

	UPROPERTY(BlueprintReadOnly)
	FVector CableEndLocation;

	FIslandWalkerCableEventData(AIslandWalkerSuspensionCable _Cable)
	{
		Cable = _Cable;
		CableEndLocation = _Cable.CableEndRoot.WorldLocation;
	}
}

struct FIslandWalkerLaserEventData
{
	FIslandWalkerLaserEventData(UIslandWalkerLaserEmitterComponent Laser, float LaserBeamWidth, bool bInSpinning = false)
	{
		LaserComponent = Laser;
		BeamWidth = LaserBeamWidth;
		bSpinning = bInSpinning;
	}

	UPROPERTY(BlueprintReadOnly)
	UIslandWalkerLaserEmitterComponent LaserComponent;
	UPROPERTY(BlueprintReadOnly)
	float BeamWidth;
	UPROPERTY(BlueprintReadOnly)
	bool bSpinning = false;
}

struct FIslandWalkerShellExplosionEventData
{
	FIslandWalkerShellExplosionEventData(FVector InLocation, FVector InVelocity)
	{
		Location = InLocation;
		Velocity = InVelocity;
	}

	UPROPERTY(BlueprintReadOnly)
	FVector Location;
	UPROPERTY(BlueprintReadOnly)
	FVector Velocity;
}

struct FIslandWalkerSpawnedMinionEventData
{
	FIslandWalkerSpawnedMinionEventData(FVector InLocation, FVector InDirection)
	{
		Location = InLocation;
		Direction = InDirection;
	}

	UPROPERTY(BlueprintReadOnly)
	FVector Location;
	UPROPERTY(BlueprintReadOnly)
	FVector Direction;
}

struct FIslandWalkerLegAttackEventData
{
	FIslandWalkerLegAttackEventData(FVector InLocation)
	{
		Location = InLocation;
	}

	UPROPERTY(BlueprintReadOnly)
	FVector Location;
}

struct FIslandWalkerNeckTargetEventData
{
	UPROPERTY(BlueprintReadOnly)
	AIslandWalkerNeckTarget NeckTarget;

	FIslandWalkerNeckTargetEventData(AIslandWalkerNeckTarget Target)
	{
		NeckTarget = Target;
	}
}

struct FIslandWalkerCablesTargetEventData
{
	UPROPERTY(BlueprintReadOnly)
	AIslandWalkerCablesTarget CablesTarget;

	FIslandWalkerCablesTargetEventData(AIslandWalkerCablesTarget Target)
	{
		CablesTarget = Target;
	}
}
