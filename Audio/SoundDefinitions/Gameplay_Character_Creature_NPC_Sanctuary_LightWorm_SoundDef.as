
UCLASS(Abstract)
class UGameplay_Character_Creature_NPC_Sanctuary_LightWorm_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void StopChasingLight(){}

	UFUNCTION(BlueprintEvent)
	void StartChasingLight(){}

	/* END OF AUTO-GENERATED CODE */

	const float CHASE_ALPHA_OVERSHOOT_BUFFER = 0.210463;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter BodyMultiEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter HeadEmitter;

	UPROPERTY(EditInstanceOnly, Meta = (DisplayName = "Vocalizations - Master Pitch", Category = "Vocalizations", ForceUnits = "cents"))
	float VocalizationsMasterPitch = 0.0;

	ALightSeeker LightWorm;
	ULightSeekerTargetingComponent LightTargetComp;
	TArray<FAkSoundPosition> PlayerBodyEmitterPositions;
	default PlayerBodyEmitterPositions.SetNum(2);

	ASanctuaryLightBirdSocket TargetSocket;

	FVector GetMouthLocation() const property
	{
		return LightWorm.SkeletalMesh.GetSocketLocation(n"Mouth");
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LightWorm = Cast<ALightSeeker>(HazeOwner);
		LightTargetComp = ULightSeekerTargetingComponent::Get(LightWorm);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"BodyMultiEmitter")
		{
			bUseAttach = false;
			return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		HeadEmitter.AudioComponent.SetWorldLocation(MouthLocation);

		for(auto Player : Game::GetPlayers())
		{
			FVector ClosestPlayerPos;
			LightWorm.SkeletalMesh.GetClosestPointOnCollision(Player.ActorLocation, ClosestPlayerPos);

			PlayerBodyEmitterPositions[Player.Player].SetPosition(ClosestPlayerPos);
		}

		BodyMultiEmitter.AudioComponent.SetMultipleSoundPositions(PlayerBodyEmitterPositions);
	}

	UFUNCTION(BlueprintCallable)
	void SetTargetLightBirdSocket()
	{
		auto Bird = ULightBirdUserComponent::Get(Game::GetMio()).Companion;
		TargetSocket = Cast<ASanctuaryLightBirdSocket>(Bird.AttachParentActor);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Chase Alpha"))
	float GetLightWormChaseAlpha()
	{
		if(TargetSocket == nullptr)
			return 0.0;

		auto DistToSocket = TargetSocket.ActorLocation.Distance(LightWorm.Origin.WorldLocation);		
		auto WantedDist = Math::Min(DistToSocket, LightWorm.MaximumReach);

		auto Alpha = (LightWorm.RuntimeSpline.Length) / WantedDist;
		return Math::Clamp(Alpha, 0.0, 1.0);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Has Reached Maxiumum Reach"))
	bool IsConstrained()
	{
		return LightWorm.bIsConstrained;
	}
}