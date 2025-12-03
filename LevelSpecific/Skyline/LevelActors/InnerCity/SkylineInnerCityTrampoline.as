struct FSkylineInnerCityTrampolineParams
{
	UPROPERTY()
	float Strenght;
}

UCLASS(Abstract)
class USkylineInnerCityTrampolineEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FSkylineInnerCityTrampolineParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWobble()
	{
	}

};

class ASkylineInnerCityTrampoline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ImpulseLocation;

	UPROPERTY(DefaultComponent)
	UBoxComponent BounceChecker;

	UPROPERTY(DefaultComponent, Attach = BeamRoot)
	UBoxComponent CollisionCheck;

	UPROPERTY(DefaultComponent, Attach = BeamRoot)
	UBoxComponent WobbleCollison;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpCallbackComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent BeamRoot;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY(EditAnywhere)
	float BounceStrength = 1400;

	float StartingBounceStrength;
	
	int RandomKnockBackNumber;

	int MioBounceCounter = Math::Clamp(1,1, 3);
	int ZoeBounceCounter = Math::Clamp(1,1, 3);;

	TArray<AHazePlayerCharacter> PerchingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpact");
		WobbleCollison.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
		BounceChecker.OnComponentEndOverlap.AddUFunction(this, n"HandeLeaveZone");
		StartingBounceStrength = BounceStrength;
	}



	UFUNCTION()
	private void HandeLeaveZone(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
			auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			MioBounceCounter = 1;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			ZoeBounceCounter = 1;

	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		BeamRoot.ApplyImpulse(ImpulseLocation.WorldLocation, -FVector::UpVector * 35.0);
		USkylineInnerCityTrampolineEventHandler::Trigger_OnWobble(this);


	}

	UFUNCTION()
	private void HandleGroundImpact(AHazePlayerCharacter Player)
	{
		RandomKnockBackNumber = Math::RandRange(1, 1000);

		if(CollisionCheck.IsOverlappingActor(Player))
		{
			if(RandomKnockBackNumber == 13)
		{
			Player.ApplyKnockdown(Player.ActorForwardVector * 1000 + Player.ActorUpVector * 1500, 1.2);
			FSkylineInnerCityTrampolineParams Params;
			Params.Strenght = BounceStrength;
			USkylineInnerCityTrampolineEventHandler::Trigger_OnLaunch(this, Params);
		}else
		HandleBounce(Player);						
		}
		
	}

	 
	UFUNCTION()
	void HandleBounce(AHazePlayerCharacter Player)
	{
		BeamRoot.ApplyImpulse(ImpulseLocation.WorldLocation, -FVector::UpVector * 200.0);
		Player.ResetAirJumpUsage();
		BounceStrength = StartingBounceStrength;

		if(Player==Game::Mio)
		{
			if(MioBounceCounter == 1)
				BounceStrength = BounceStrength * 1.0;

			if(MioBounceCounter == 2)
				BounceStrength = BounceStrength * 1.25;

			if(MioBounceCounter >= 3)
				BounceStrength = BounceStrength * 1.50;
			
			Player.AddMovementImpulse(Player.GetMovementWorldUp() * BounceStrength);
			Player.PlayForceFeedback(ForceFeedbackEffect, false, true, this, BounceStrength);
			MioBounceCounter++;			
		}	

		if(Player==Game::Zoe)
		{
			if(ZoeBounceCounter == 1)
				BounceStrength = BounceStrength * 1.0;

			if(ZoeBounceCounter == 2)
				BounceStrength = BounceStrength * 1.25;

			if(ZoeBounceCounter >= 3)
				BounceStrength = BounceStrength * 1.50;
			
			Player.PlayForceFeedback(ForceFeedbackEffect, false, true, this, BounceStrength);
			Player.AddMovementImpulse(Player.GetMovementWorldUp() * BounceStrength);
			ZoeBounceCounter++;
		}

		FSkylineInnerCityTrampolineParams Params;
		Params.Strenght = BounceStrength;
		USkylineInnerCityTrampolineEventHandler::Trigger_OnLaunch(this, Params);
		

		PrintToScreenScaled("Params: " + Params.Strenght, 2.0, FLinearColor::Red, 5.0);
		PrintToScreenScaled("Bounce: " + BounceStrength, 2.0, FLinearColor::Purple, 5.0);

		
	}
};