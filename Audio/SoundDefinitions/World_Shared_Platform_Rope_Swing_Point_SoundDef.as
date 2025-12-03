struct FPlayerSwingPointAudioData
{
	AHazePlayerCharacter Player = nullptr;
	USwingPointComponent SwingPointComp = nullptr;
	UPlayerSwingComponent PlayerSwingComp = nullptr;
	UHazeAudioEmitter PlayerSwingEmitter = nullptr;
	FHazeAudioPostEventInstance SwingLoopEventInstance;

	FVector PlayerSwingVelo;
	FVector CachedSwingLocation;

	bool IsValid() const
	{
		return SwingPointComp != nullptr;
	}
}

UCLASS(Abstract)
class UWorld_Shared_Platform_Rope_Swing_Point_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */	

	UPROPERTY(Category = "Audio Events", DisplayName = "Event - Sweetener - Swing")
	UHazeAudioEvent EventSweetenerSwing;

	UPROPERTY(Category = "Swinging", DisplayName = "Swinging - Sweetener - Swing - Trigger Alpha", Meta=(EditCondition = "EventSweetenerSwing != nullptr"))
	float SwingingSweetenerSwingTriggerAlpha = 0.45;

	const float MAX_SWING_VELO_SPEED = 25.0;

	int PlayerSwingCount = 0;
	TPerPlayer<FPlayerSwingPointAudioData> PlayerSwingDatas;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return PlayerSwingCount > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return PlayerSwingCount == 0;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AActor TargetActor = HazeOwner;
		if (ActorInstigator == HazeOwner.GetAttachParentActor())
		{
			TargetActor = ActorInstigator;
		}

		TArray<USwingPointComponent> SwingPoints;
		TargetActor.GetComponentsByClass(USwingPointComponent, SwingPoints);

		for(auto SwingPoint : SwingPoints)
		{
			SwingPoint.OnPlayerAttachedEvent.AddUFunction(this, n"OnPlayerStartedSwinging");
			SwingPoint.OnPlayerDetachedEvent.AddUFunction(this, n"OnPlayerStoppedSwinging");	
		}
	}

	UFUNCTION()
	void OnPlayerStartedSwinging(AHazePlayerCharacter Player, USwingPointComponent SwingPointComponent)
	{
		auto& PlayerSwingData = PlayerSwingDatas[Player];	
		PlayerSwingData.SwingPointComp = SwingPointComponent;

		if(PlayerSwingData.PlayerSwingComp == nullptr)
		{
			PlayerSwingData.PlayerSwingComp =  UPlayerSwingComponent::Get(Player);
		}
		if(PlayerSwingData.PlayerSwingEmitter == nullptr)
		{
			auto EmitterAttachParams = FHazeAudioEmitterAttachmentParams();
			EmitterAttachParams.Attachment = SwingPointComponent;
			EmitterAttachParams.EmitterName = n"SwingPointEmitter";
			EmitterAttachParams.Owner = Player;
			EmitterAttachParams.Instigator = this;
			EmitterAttachParams.bCanAttach = true;

			PlayerSwingData.PlayerSwingEmitter = Audio::GetPooledEmitter(EmitterAttachParams);
			PlayerSwingData.PlayerSwingEmitter.SetPlayerPanning(Player);

			PlayerSwingData.Player = Player;
		}

		StartPlayerSwinging(Player, PlayerSwingData.PlayerSwingEmitter);
		++PlayerSwingCount;
	}

	UFUNCTION()
	void OnPlayerStoppedSwinging(AHazePlayerCharacter Player, USwingPointComponent SwingPointComponent)
	{
		auto& SwingData = PlayerSwingDatas[Player];
		if(!SwingData.IsValid())
			return;

		StopPlayerSwinging(Player, SwingData.PlayerSwingEmitter, SwingData.SwingLoopEventInstance);			
		SwingData.SwingPointComp = nullptr;
		--PlayerSwingCount;
	}

	UFUNCTION(BlueprintEvent)
	void StartPlayerSwinging(AHazePlayerCharacter Player, UHazeAudioEmitter SwingEmitter) {};

	UFUNCTION(BlueprintEvent)
	void StopPlayerSwinging(AHazePlayerCharacter Player, UHazeAudioEmitter SwingEmitter, const FHazeAudioPostEventInstance&in SwingLoopEventInstance) {};

	UFUNCTION(BlueprintEvent)
	void TickPlayerSwinging(AHazePlayerCharacter Player, UHazeAudioEmitter SwingEmitter, const FHazeAudioPostEventInstance&in SwingLoopEventInstance) {};

	UFUNCTION(BlueprintCallable)
	void SetPlayerSwingLoopEventInstance(AHazePlayerCharacter Player, FHazeAudioPostEventInstance EventInstance)
	{
		PlayerSwingDatas[Player].SwingLoopEventInstance = EventInstance;
	}

	UFUNCTION(BlueprintPure)
	void GetPlayerSwingEmitter(AHazePlayerCharacter Player, UHazeAudioEmitter&out SwingEmitter)
	{
		SwingEmitter = PlayerSwingDatas[Player].PlayerSwingEmitter;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto& SwingData : PlayerSwingDatas)
		{			
			if(!SwingData.IsValid())
				continue;

			FVector PlayerSwingLocation = SwingData.Player.ActorCenterLocation;
			SwingData.PlayerSwingVelo = PlayerSwingLocation - SwingData.CachedSwingLocation;

			TickPlayerSwinging(SwingData.Player, SwingData.PlayerSwingEmitter, SwingData.SwingLoopEventInstance);
			SwingData.CachedSwingLocation = PlayerSwingLocation;			
		}
	}

	UFUNCTION(BlueprintPure)
	float GetSwingArchAlpha(AHazePlayerCharacter Player)
	{
		auto& SwingData = PlayerSwingDatas[Player];
		if(!SwingData.IsValid())
			return 0.0;
	
		auto NormalizedSwingAngle = SwingData.PlayerSwingComp.SwingAngle / 90.0;
		FVector ToSwing = (SwingData.SwingPointComp.WorldLocation - Player.ActorCenterLocation).GetSafeNormal();
		const float SwingDirectionDot = SwingData.PlayerSwingVelo.GetSafeNormal().DotProduct(ToSwing);

		const float SwingAlpha = NormalizedSwingAngle * (Math::Sign(SwingDirectionDot * -1));
		return NormalizedSwingAngle;
	}

	UFUNCTION(BlueprintPure)
	float GetSwingSpeed(AHazePlayerCharacter Player)
	{
		auto PlayerSwingData = PlayerSwingDatas[Player];
		if(!PlayerSwingData.IsValid())
			return 0.0;

		auto SwingSpeed = Math::Min(1.0, PlayerSwingData.PlayerSwingVelo.Size() / MAX_SWING_VELO_SPEED);
		return SwingSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for(auto& PlayerSwingData : PlayerSwingDatas)
		{
			Audio::ReturnPooledEmitter(this, PlayerSwingData.PlayerSwingEmitter);
		}
	}
}
