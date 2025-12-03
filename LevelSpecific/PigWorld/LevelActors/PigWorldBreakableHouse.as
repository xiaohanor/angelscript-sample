event void FPigWorldBreakableHouseEvent();

class APigWorldBreakableHouse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY()
	FPigWorldBreakableHouseEvent OnBroken;

	bool bBroken = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
	}

	UFUNCTION()
	void TryToBreakHouse(AHazePlayerCharacter Player)
	{
		if (bBroken)
			return;
		
		if (!Player.HasControl())
			return;

		if (!Player.IsAnyCapabilityActive(n"Fart"))
			return;

		float Dot = ActorForwardVector.DotProduct(Player.ActorForwardVector);
		if (Dot <= 0.5)
			return;

		bBroken = true;
		CrumbBreakHouse();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBreakHouse()
	{
		OnBroken.Broadcast();
		UPigWorldBreakableHouseEffectEventHandler::Trigger_BreakHouse(this);
		Online::UnlockAchievement(n"BrickHouse");
	}
}

class UPigWorldBreakableHouseEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void BreakHouse() {}
}