event void FSkylineBossTankArenaCircleRampSignature();

class ASkylineBossTankArenaCircleRamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	FSkylineBossTankArenaCircleRampSignature OnActivateRamp;

	TArray<ASkylineBossTankArenaCircleRampSegment> Segments;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto BossTank = ASkylineBossTank::Get();
		if (BossTank != nullptr)
			BossTank.OnAssemble.AddUFunction(this, n"HandleBossTankDie");
	}

	UFUNCTION()
	private void HandleBossTankDie()
	{
		ActivateRamp();
	}

	UFUNCTION(DevFunction)
	void ActivateRamp()
	{
		OnActivateRamp.Broadcast();
	}
};