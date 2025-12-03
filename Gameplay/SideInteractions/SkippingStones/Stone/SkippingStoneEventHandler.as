struct FSkippingStoneOnThrowEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Velocity;
};

struct FSkippingStoneOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult Hit;

	UPROPERTY(BlueprintReadOnly)
	FVector Velocity;
};

struct FSkippingStoneOnHitPlayerEventData
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
};

struct FSkippingStoneOnWaterBounceEventData
{
	UPROPERTY(BlueprintReadOnly)
	int Bounces;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactPoint;

	UPROPERTY(BlueprintReadOnly)
	float VerticalVelocity;

	UPROPERTY(BlueprintReadOnly)
	FVector HorizontalDirection;
};

struct FSkippingStoneOnWaterSplashEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactPoint;

	UPROPERTY(BlueprintReadOnly)
	float VerticalVelocity;
};

UCLASS(Abstract)
class USkippingStoneEventHandler : UHazeEffectEventHandler
{
	ASkippingStone SkippingStone;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SkippingStone = Cast<ASkippingStone>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrow(FSkippingStoneOnThrowEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSkippingStoneOnImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitPlayer(FSkippingStoneOnHitPlayerEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterBounce(FSkippingStoneOnWaterBounceEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterSplash(FSkippingStoneOnWaterSplashEventData EventData) {}
};