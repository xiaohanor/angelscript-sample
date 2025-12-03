UCLASS(Abstract)
class ASketchbookBoulder : AHazeActor
{

	UPROPERTY(EditInstanceOnly)
	AActor LaunchToActor;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent OverlapComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	UForceFeedbackEffect RollForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect KillForceFeedback;

	UPROPERTY(BlueprintReadOnly)
	bool bKilledPlayer = false;

	UFUNCTION(BlueprintCallable)
	void OnStartRolling()
	{
		for(auto Player : Game::GetPlayers())
		{
			Player.PlayForceFeedback(RollForceFeedback, false, true, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter OverlapPlayer = Cast<AHazePlayerCharacter>(OtherActor);
		if(OverlapPlayer != nullptr)
			bKilledPlayer = true;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && LaunchToActor != nullptr)
		{
			FKnockdown Knockdown;
			Knockdown.Move = (LaunchToActor.ActorLocation - Player.ActorLocation) * 2;

			Player.PlayForceFeedback(KillForceFeedback, false, true, this);
			Player.ApplyKnockdown(Knockdown);
			Player.DamagePlayerHealth(0.0, FPlayerDeathDamageParams(), DamageEffect);
		}
	}
};
