struct FBattlefieldHoverboardGrindEffectParams
{
	UPROPERTY()
	USceneComponent AttachRootOnHoverboard;

	UPROPERTY()
	UBattlefieldHoverboardGrindSplineComponent GrindSpline;
}

struct FBattlefieldHoverboardOnGroundedParams
{
	UPROPERTY()
	UPhysicalMaterial GroundPhysicalMaterial;
}

struct FBattlefieldHoverboardOnGroundMaterialChangedParams
{
	UPROPERTY()
	UPhysicalMaterial NewGroundPhysicalMaterial;
}

struct FBattlefieldHoverboardTrickParams
{
	UPROPERTY()
	EBattlefieldHoverboardTrickType TrickType;

	bool bIncreaseMult;
}

UCLASS(Abstract)
class UBattlefieldHoverboardEffectHandler : UHazeEffectEventHandler
{
	ABattlefieldHoverboard Hoverboard;
	UBattlefieldHoverboardComponent HoverboardComp;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hoverboard = Cast<ABattlefieldHoverboard>(Owner);

		Player = Hoverboard.Player;
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnNewTrick(FBattlefieldHoverboardTrickParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSuccessfulLand() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrickFailed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedGrinding(FBattlefieldHoverboardGrindEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedGrinding() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedWallRun(FBattlefieldHoverboardGrindEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedWallRun() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrickBoostStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrickBoostEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrickBoostStored() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrounded(FBattlefieldHoverboardOnGroundedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundMaterialChanged(FBattlefieldHoverboardOnGroundMaterialChangedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeftGround() {}

	UFUNCTION(BlueprintPure, BlueprintCallable)
	FVector GetGroundLocation() const {	return Player.ActorLocation; }

	UFUNCTION(BlueprintPure, BlueprintCallable)
	FVector GetGroundNormal() const { return MoveComp.CurrentGroundNormal; }

	UFUNCTION(BlueprintPure, BlueprintCallable)
	bool SnowEffectsAreEnabled() const { return HoverboardComp.bSnowEffectsEnabled; }
};