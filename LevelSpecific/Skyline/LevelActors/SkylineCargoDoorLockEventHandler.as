enum ELockSprintIndex
{
	Left = 0,
	Right = 1
}

struct FSkylineCargoDoorLockEventConstrainHit
{
	float HitStrength = 0.0;
}

struct FSkylineCargoDoorLockSprintBrokenParams
{
	UPROPERTY()
	FVector SprintLocation;

	UPROPERTY()
	ELockSprintIndex SprintIndex;
}

UCLASS(Abstract)
class USkylineCargoDoorLockEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstrainHitLowAlpha(FSkylineCargoDoorLockEventConstrainHit HitStrength) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstrainHitHighAlpha(FSkylineCargoDoorLockEventConstrainHit HitStrength) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityWhipGrabbed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityWhipReleased() {}	
}