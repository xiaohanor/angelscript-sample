UCLASS(Abstract)
class ATrashChuteFlap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent FlapRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> FlipCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FlipFF;

	UFUNCTION(BlueprintCallable)
	void FlipFlap()
	{
		BP_FlipFlap();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(FlipCamShake, this);
			Player.PlayForceFeedback(FlipFF, false, true, this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_FlipFlap() {}
}