struct FSkylineBossChaserEventData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	UPROPERTY(BlueprintReadOnly)
	FVector Velocity = FVector::ZeroVector;
}

UCLASS(Abstract)
class USkylineBossChaserEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	ASkylineBossChaser Chaser = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Chaser = Cast<ASkylineBossChaser>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Die() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hit(FSkylineBossChaserEventData ChaserEventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundImpact(FSkylineBossChaserEventData ChaserEventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WallImpact(FSkylineBossChaserEventData ChaserEventData) {}
}