
UCLASS(Abstract)
class UGameplay_Creature_StoneBeastCritter_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStopTelegraphing(){}

	UFUNCTION(BlueprintEvent)
	void OnStartTelegraphing(){}

	UFUNCTION(BlueprintEvent)
	void OnDamage(FOnStoneCritterDamageParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(){}

	UFUNCTION(BlueprintEvent)
	void OnHitPlayer(FOnStoneCritterHitPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnAttackStart(){}

	UFUNCTION(BlueprintEvent)
	void OnAttackRecover(){}

	UFUNCTION(BlueprintEvent)
	void OnAttackLunge(){}

	UFUNCTION(BlueprintEvent)
	void OnLand(){}

	/* END OF AUTO-GENERATED CODE */

	AAISummitStoneBeastCritter StoneBeastCritter;

	FVector2D PreviousScreenPosition;

	UFUNCTION(BlueprintEvent)
	void OnStartMovement() {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		StoneBeastCritter = Cast<AAISummitStoneBeastCritter>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto CritterSettings = USummitStoneBeastCritterSettings::GetSettings(StoneBeastCritter);
		if(CritterSettings.bUseCrawlSplineEntrance)
			OnStartMovement();	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		float PanningRTPC = 0.0;
		float _Y;
		Audio::GetScreenPositionRelativePanningValue(StoneBeastCritter.Mesh.WorldLocation, PreviousScreenPosition, PanningRTPC, _Y);
		DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, PanningRTPC, 0.0);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Normalized Movement Speed"))
	float GetNormalizedMovementSpeed() 
	{
		return Math::Min(1, StoneBeastCritter.AnimComp.SpeedForward / 300);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Crowd Control Value"))
	float GetCrowdControlValue() 
	{
		return StoneBeastCritter.CrowdControlComp.GetCrowdControlValue();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Distance To Closest Player"))
	float GetDistanceToClosestPlayer() 
	{
		float ClosestDistSqrd = MAX_flt;
		for(auto Player : Game::GetPlayers())
		{
			const float PlayerDistSqrd = Player.ActorLocation.DistSquared(StoneBeastCritter.Mesh.WorldLocation);
			ClosestDistSqrd = Math::Min(ClosestDistSqrd, PlayerDistSqrd);
		}

		return Math::Sqrt(ClosestDistSqrd);
	}

}