struct FSkylineBossTankMortarBallOnFiredEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector Direction;
};

struct FSkylineBossTankMortarBallOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector Normal;
};

struct FSkylineBossTankMortarBallOnExplodeEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;
};

UCLASS(Abstract)
class USkylineBossTankMortarBallEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASkylineBossTankMortarBall MortarBall;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MortarBall = Cast<ASkylineBossTankMortarBall>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFired(FSkylineBossTankMortarBallOnFiredEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShotFiredFromTank() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSkylineBossTankMortarBallOnImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode(FSkylineBossTankMortarBallOnExplodeEventData EventData) {}
};