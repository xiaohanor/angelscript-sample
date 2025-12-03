class AMedallionHydraBelowBiteBreakablePlatform : ASanctuaryBossMedallionStaticPrototypePlatform
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathTriggerComp;

	UPROPERTY(EditInstanceOnly)
	AGrapplePoint GrappleToEnable;

	float DamageRadius = 500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (GrappleToEnable != nullptr)
			GrappleToEnable.AddActorDisable(this);
	}

	void Break()
	{
		DelayedBreak();
		//Timer::SetTimer(this, n"DelayedBreak", 0.2);
	}

	UFUNCTION(BlueprintEvent)
	private void DelayedBreak()
	{
		BP_Break();

		for (auto Player : Game::Players)
		{
			if (DeathTriggerComp.IsOverlappingActor(Player))
				Player.KillPlayer();
		}

		if (GrappleToEnable != nullptr)
			GrappleToEnable.RemoveActorDisable(this);

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Break(){}
};