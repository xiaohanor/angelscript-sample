struct FJetskiOnLandOnWaterEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector Velocity;

	UPROPERTY(BlueprintReadOnly)
	FVector WaveNormal;
};

struct FJetskiOnEnterUnderwaterEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector Velocity;

	UPROPERTY(BlueprintReadOnly)
	FVector WaveNormal;

	UPROPERTY(BlueprintReadOnly)
	bool bEnterWasFromAir;

	UPROPERTY(BlueprintReadOnly)
	bool bEnterWasFromGround;
};

struct FJetskiOnExitUnderwaterEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector Velocity;

	UPROPERTY(BlueprintReadOnly)
	bool bExitWasJump;
};

struct FJetskiOnHitWallEventData
{
	UPROPERTY()
	FVector Impulse;

	UPROPERTY()
	AHazePlayerCharacter Player;
};

UCLASS(Abstract)
class UJetskiEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AJetski Jetski;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	/**
	 * Movement Events
	 */

	/**
	 * When the Jetski goes from being in the air to being on the water surface movement (not underwater!)
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLandOnWater(FJetskiOnLandOnWaterEventData EventData) {}

	/**
	 * When the Jetski starts using an Underwater movement mode.
	 * This may not line up with when the jetski visually goes underwater, but gives more info since it's tied to gameplay.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartUnderwaterMovement(FJetskiOnEnterUnderwaterEventData EventData) {}

	/**
	 * When the Jetski stops using an Underwater movement mode.
	 * This may not line up with when the jetski visually exits underwater, but gives more info since it's tied to gameplay.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopUnderwaterMovement(FJetskiOnExitUnderwaterEventData EventData) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDiving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopDiving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedDiving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGroundMovement() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopGroundMovement() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartAirMovement() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartAirDive() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopAirMovement() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitWall(FJetskiOnHitWallEventData EventData) {}

	/**
	 * Visual Events
	 */

	/**
	 * When the Jetski visually starts riding on the surface of the water.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartWaterSurfaceVisual() {}

	/**
	 * When the Jetski visually stops riding on the surface of the water.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopWaterSurfaceVisual() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartThrottle() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopThrottle() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartThrottleInWaterVisual() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopThrottleInWaterVisual() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartAirVisual() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopAirVisual() {}

	/**
	 * When the Jetski visually starts being fully underwater.
	 * This may not line up with gameplay, such as when we aren't holding the Dive action, but a big wave forces us fully underwater.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartUnderwaterVisual() {}

	/**
	 * When the Jetski visually stops being fully underwater.
	 * This may not line up with gameplay.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopUnderwaterVisual() {}

	/**
	 * Death Events
	 */

	/**
	 * When the jetski driver dies and the jetski explodes.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}

	/**
	 * When the jetski respawns.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawn() {}

	UFUNCTION(BlueprintPure)
	FHitResult GetGroundImpact()
	{
		return Jetski.MoveComp.GroundContact.ConvertToHitResult();
	}
};