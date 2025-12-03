
UCLASS(Abstract)
class UVO_Tundra_Swamp_SideContent_Seesaw_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLaunched(FTundraSwingEventData TundraSwingEventData){}

	UFUNCTION(BlueprintEvent)
	void OnBothPlayersEntered(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditAnywhere)
	APlayerLookAtTrigger LookAtTrigger;

	UPROPERTY(EditAnywhere)
	ATundraSwing Swing;

	UPROPERTY(EditDefaultsOnly)
	bool bTriggeredViewLine = false;

	UPROPERTY(EditAnywhere)
	float TriggerInViewRange = 1000;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (bTriggeredViewLine)
			return;

		for (auto Player: Game::Players)
		{

			auto SwingDirection = Swing.ActorLocation - Player.ActorLocation;
			SwingDirection.Normalize();
			auto Dot = Player.ViewRotation.ForwardVector.DotProduct(SwingDirection);
			
			if (Dot < .2)
				continue;

			if (Player.GetSquaredDistanceTo(Swing) < TriggerInViewRange*TriggerInViewRange)
			{
				OnInRangeOfSeeSaw(Player);
				bTriggeredViewLine = true;
				break;
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnInRangeOfSeeSaw(AHazePlayerCharacter Player) {}
}