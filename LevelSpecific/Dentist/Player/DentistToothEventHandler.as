struct FDentistToothBounceOnBounceEventData
{
	UPROPERTY()
	UDentistToothMovementResponseComponent MovementResponseComp;

	UPROPERTY()
	FVector Impulse;

	UPROPERTY()
	FHitResult Impact;
}

struct FDentistToothRagdollOnImpulseFromObstacleEventData
{
	UPROPERTY()
	AActor Obstacle;
	
	UPROPERTY()
	FVector Impulse;
};

struct FDentistToothSplitEventHandlerOnSplitEventData
{
	UPROPERTY(BlueprintReadOnly)
	FTransform SplitTransform;
};

struct FDentistToothSplitEventHandlerOnStartRecombineEventData
{
	UPROPERTY(BlueprintReadOnly)
	FTransform PlayerTransform;

	UPROPERTY(BlueprintReadOnly)
	FTransform AITransform;
};

struct FDentistToothSplitEventHandlerOnFinishRecombineEventData
{
	UPROPERTY(BlueprintReadOnly)
	FTransform RecombineTransform;
};

/**
 * Player events for all movement while being the full size tooth
 */
UCLASS(Abstract)
class UDentistToothEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	/**
	 * BOUNCE
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounce(FDentistToothBounceOnBounceEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopBounced() {}

	/**
	 * DASH
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDash() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopDash() {}

	/**
	 * We landed from a dash, and will perform a summersault
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDashLanding() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopDashLanding() {}

	/**
	 * We had a wall impact while dashing, and will perform a backflip out if it (as you do)
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDashBackflipping() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopDashBackflipping() {}

	/**
	 * GROUND POUND
	 */
	
	/**
	 * Ground Pound is active while anticipating and dropping, but not while recovering
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGroundPound() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopGroundPound() {}

	/**
	 * Anticipation is when the player stops mid-air and starts turning upside down
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGroundPoundAnticipation() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopGroundPoundAnticipation() {}

	/**
	 * Drop is when we are falling down
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGroundPoundDrop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopGroundPoundDrop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundPoundImpact(FDentistGroundPoundOnGroundHit EventData) {}

	/**
	 * Recovery is when the player flips back to facing upwards after a ground hit
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGroundPoundRecovery() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopGroundPoundRecovery() {}

	/**
	 * JUMP
	 */
	
	/**
	 * First Jump
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJump() {}

	/**
	 * Second Jump
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwirlJump() {}

	/**
	 * Third Jump
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFrontFlipJump() {}
	
	/**
	 * We have landed after a jump
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJumpLanding() {}

	/**
	 * Something interrupted the jump (usually dash, ground pound or being ragdolled)
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJumpCanceled() {}

	/**
	 * RAGDOLL
	 */
	
	/**
	 * Something has imparted an impulse and wants us to start ragdolling
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpulseFromObstacle(FDentistToothRagdollOnImpulseFromObstacleEventData EventData) {}

	/**
	 * We went into the ragdoll movement mode
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRagdoll() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopRagdoll() {}

	/**
	 * SPLIT
	 */

	/**
	 * We split into two halves
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSplit(FDentistToothSplitEventHandlerOnSplitEventData EventData) {}

	/**
	 * We have started moving together with the other half
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRecombine(FDentistToothSplitEventHandlerOnStartRecombineEventData EventData) {}

	/**
	 * We reached the other half and have been fused back into one tooth
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishRecombine(FDentistToothSplitEventHandlerOnFinishRecombineEventData EventData) {}
};