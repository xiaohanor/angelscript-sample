struct FSkylineBallBossKilledPlayerEventHandlerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FSkylineBallBossMeteorEventHandlerParams
{
	UPROPERTY()
	FVector TargetLocation;
}

class USkylineBallBossMiscVOEventHandler : UHazeEffectEventHandler
{
	//Ball Boss Efforts

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SlidingCarThrow(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashingCarSmash(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WheeleMotorcycleThrow(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BusThrow(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ExplodingMotorcycleThrow(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LobbingCarThrow(){} //

	//Ball Boss Take Damage

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DetonatorHit(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DetonatorExplode(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargeLaserHit(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargerEnterInteract(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargerExitInteract(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargeLaserExtruded(){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargerExitRippedOff(){} //

	//Ball Boss Taunts

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BallBossKilledPlayer(FSkylineBallBossKilledPlayerEventHandlerParams Params){} //

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BallBossWon(){} //

	//Misc

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MeteorCarTelegraph(FSkylineBallBossMeteorEventHandlerParams Params){} //
}