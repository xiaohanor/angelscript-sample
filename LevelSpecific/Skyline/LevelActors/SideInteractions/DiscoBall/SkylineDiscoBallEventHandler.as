UCLASS(Abstract)
class USkylineDiscoBallEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	float SwingVelocity;

	UPROPERTY()
	float BallTwistVelocity;

	ASkylineDiscoBall DiscoBall;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DiscoBall = Cast<ASkylineDiscoBall>(Owner);
		SwingVelocity = Cast<ASkylineDiscoBall>(Owner).SwingVelocity;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SwingVelocity = DiscoBall.SwingVelocity;
		BallTwistVelocity = DiscoBall.TwistVelocity;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByKatana() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GravityWhipGrabbed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GravityWhipReleased() {}
};