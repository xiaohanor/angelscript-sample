class UMoonMarketPlayerBouncyBallResponseComp : UMoonMarketBouncyBallResponseComponent
{
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnHitByBallEvent.AddUFunction(this, n"HitByBall");
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION()
	private void HitByBall(FMoonMarketBouncyBallHitData Data)
	{
		if(Data.InstigatingPlayer == Player && UMoonMarketShapeshiftComponent::Get(Player).IsShapeshiftActive())
			return;

		FKnockdown Knockdown;
		Knockdown.Move = Data.ImpactVelocity * 0.12;
		Knockdown.Duration = 1;
		Player.ApplyKnockdown(Knockdown);
	}
};