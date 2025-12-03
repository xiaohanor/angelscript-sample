class ATailBombNightQueenChain : ANightQueenMetal
{
	UPROPERTY(EditAnywhere)
	AHazeActor TailBomb;

	UTeenDragonTailBombComponent BombComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BombComp = UTeenDragonTailBombComponent::Get(TailBomb);
		OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		Timer::SetTimer(this, n"DelayDisableBomb", 0.5, false);
	}

	UFUNCTION()
	void DelayDisableBomb()
	{
		BombComp.DisableBomb(this);
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		BombComp.EnableBomb(this);
	}
}