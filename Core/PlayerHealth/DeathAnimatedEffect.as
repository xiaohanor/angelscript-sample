
UCLASS(Abstract)
class UDeathAnimatedEffect : UDeathEffect
{
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence DeathAnimation;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DeathVFX;

	private FHazeAnimationDelegate OnBlendingOutCallback;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		OnBlendingOutCallback.BindUFunction(this, n"OnAnimationDone");
		if (DeathAnimation != nullptr)
			DeathEffectDuration = DeathAnimation.SequenceLength + 0.5;
	}

	UFUNCTION()
	private void OnAnimationDone()
	{
		DiedAnimationDone();
	}

	/**
	* The player has finished death animation
	*/
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DiedAnimationDone() {}

	UFUNCTION(BlueprintOverride)
	void Died()
	{
		if (DeathAnimation != nullptr)
		{
			Player.PlaySlotAnimation(
				OnBlendingOut = OnBlendingOutCallback,
				Animation = DeathAnimation);

			if (DeathVFX != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(DeathVFX, Player.ActorLocation, Player.ActorRotation);
		}
		else
		{
			DiedAnimationDone();
		}
	}
};