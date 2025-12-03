class USlingshotKitePlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	ASlingshotKite CurrentKite;

	UPROPERTY()
	UBlendSpace BlendSpace;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ConstantCamShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
}