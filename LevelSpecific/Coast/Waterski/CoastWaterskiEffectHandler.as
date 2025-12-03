struct FCoastWaterskiGeneralParams
{
	UPROPERTY()
	AHazePlayerCharacter WaterskiPlayer;

	UPROPERTY()
	UCoastWaterskiPlayerComponent WaterskiComp;

	UPROPERTY()
	ACoastWaterskiActor LeftWaterski;

	UPROPERTY()
	ACoastWaterskiActor RightWaterski;

	UPROPERTY()
	FVector SurfaceLocation;
}

struct FCoastWaterskiOnHitWaterSurfaceParams
{
	UPROPERTY()
	AHazePlayerCharacter WaterskiPlayer;

	UPROPERTY()
	UCoastWaterskiPlayerComponent WaterskiComp;

	UPROPERTY()
	ACoastWaterskiActor LeftWaterski;

	UPROPERTY()
	ACoastWaterskiActor RightWaterski;

	UPROPERTY()
	float Speed;

	UPROPERTY()
	FVector SurfaceLocation;
}

struct FCoastWaterskiOnHitGroundParams
{
	UPROPERTY()
	AHazePlayerCharacter WaterskiPlayer;

	UPROPERTY()
	UCoastWaterskiPlayerComponent WaterskiComp;

	UPROPERTY()
	ACoastWaterskiActor LeftWaterski;

	UPROPERTY()
	ACoastWaterskiActor RightWaterski;

	UPROPERTY()
	float Speed;

	UPROPERTY()
	FVector ImpactLocation;
}

struct FCoastWaterskiOnLeaveGroundParams
{
	UPROPERTY()
	AHazePlayerCharacter WaterskiPlayer;

	UPROPERTY()
	UCoastWaterskiPlayerComponent WaterskiComp;

	UPROPERTY()
	ACoastWaterskiActor LeftWaterski;

	UPROPERTY()
	ACoastWaterskiActor RightWaterski;
}

struct FCoastWaterskiOnCollidedParams
{
	UPROPERTY()
	AHazePlayerCharacter WaterskiPlayer;

	UPROPERTY()
	UCoastWaterskiPlayerComponent WaterskiComp;

	UPROPERTY()
	ACoastWaterskiActor LeftWaterski;

	UPROPERTY()
	ACoastWaterskiActor RightWaterski;

	UPROPERTY()
	float Speed;

	UPROPERTY()
	FVector ImpactLocation;
}

class UCoastWaterskiEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartWaterskiing(FCoastWaterskiGeneralParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopWaterskiing(FCoastWaterskiGeneralParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitWaterSurface(FCoastWaterskiOnHitWaterSurfaceParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitGround(FCoastWaterskiOnHitGroundParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeaveGround(FCoastWaterskiOnLeaveGroundParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeaveWaterSurface(FCoastWaterskiGeneralParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJump() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCollided(FCoastWaterskiOnCollidedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivateWaterskiRope() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeactivateWaterskiRope() {}

	UFUNCTION(BlueprintPure)
	FVector GetCurrentPointOnWave()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		auto WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);

		return WaterskiComp.GetWaveData().PointOnWave;
	}
}