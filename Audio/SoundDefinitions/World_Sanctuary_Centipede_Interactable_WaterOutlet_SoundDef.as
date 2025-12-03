
UCLASS(Abstract)
class UWorld_Sanctuary_Centipede_Interactable_WaterOutlet_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnDetachWaterOutlet(FCentipedeWaterOutletEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnAttachWaterOutlet(FCentipedeWaterOutletEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnUnplugWaterOutlet(FCentipedeWaterOutletUnplugEventParams Params){}

	/* END OF AUTO-GENERATED CODE */

	ACentipede Centipede;

	UFUNCTION(BlueprintPure)
	float GetStickInputWaterMovement(const AHazePlayerCharacter Player)
	{
		if(Player == nullptr)
			return 0.0;

		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
		return MoveComp.GetSyncedMovementInputForAnimationOnly().X;
	}

	UFUNCTION(BlueprintPure)
	FVector GetCentipedeMiddlePoint()
	{
		if(Centipede == nullptr)
		{
			Centipede = UPlayerCentipedeComponent::Get(Game::GetMio()).Centipede;
			if(Centipede == nullptr)
				return FVector();
		}
			
		TArray<FVector> BodyLocations = Centipede.GetBodyLocations();
		return BodyLocations[Math::IntegerDivisionTrunc(BodyLocations.Num(), 2)];
	}
}