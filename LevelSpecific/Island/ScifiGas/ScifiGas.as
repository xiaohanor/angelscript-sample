
class UScifiGasZoneSettings : UDataAsset
{
	// Stay in the gas this amount, and you will be dead
	UPROPERTY()
	float TimeUntilDeath = 10.0;

	// stay in the gas this amount, and you will enter a critical stage
	// moving slower and having a new MH
	UPROPERTY()
	float TimeUntilCritical = 3.0;

	// stay in the gas this amount, and you will not be able to sprint
	UPROPERTY()
	float TimeUntilSprintBlock = 1.0;

	// stay in the gas this amount, and you will not be able to dash
	UPROPERTY()
	float TimeUntilDashBlock = 1.0;

	// stay in the gas this amount, and you will not be able to slide
	UPROPERTY()
	float TimeUntilSlideBlock = 1.0;

	// stay in the gas this amount, and you will not be able to jump
	UPROPERTY()
	float TimeUntilJumpBlock = 1.0;

	// How fast we can move
	UPROPERTY()
	FHazeRange MovementSpeed = FHazeRange(0.1, 1.0);

	/** If true, the movespeed min range is reached by the time of 'death' 
	 * else, its reached by the time of 'critical'
	*/
	UPROPERTY()
	bool bMovementSpeedCountsUpUntilDeath = true;
}

UCLASS(Abstract)
class UScifiPlayerGasZoneComponent : UActorComponent
{
	UPROPERTY()
	UScifiGasZoneSettings Settings;

	UPROPERTY()
	TPerPlayer<UHazeLocomotionFeatureBase> AnimationAssets;
	
	AHazePlayerCharacter PlayerOwner;
	TArray<AScifiGasZone> GasZones;
	float CurrentDamageTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerOwner.AddLocomotionFeature(AnimationAssets[PlayerOwner], this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		PlayerOwner.RemoveLocomotionFeature(AnimationAssets[PlayerOwner], this);
	}

	bool IsCriticalExposure() const
	{
		return CurrentDamageTime >= Settings.TimeUntilCritical;
	}

}