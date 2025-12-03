class AIslandWalkerFan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent FanAComp;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent FanBComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	FRotator RotationSpeed = FRotator(0,0,1);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FanAComp.AddLocalRotation(FRotator(0,0,10) * DeltaSeconds);
		FanBComp.AddLocalRotation(FRotator(0,0,-10) * DeltaSeconds);
	}

	UFUNCTION()
	void DestroyFan()
	{
		UIslandWalkerFanEventHandler::Trigger_OnFansDestroyed(this);
		BP_DestroyFan();
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyFan() {};

};

UCLASS(Abstract)
class UIslandWalkerFanEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFansDestroyed() {}

}