struct FPlayerGrapplePointAudioData
{
	AHazePlayerCharacter Player = nullptr;
	UGrapplePointBaseComponent GrapplePointComp = nullptr;
	UPlayerGrappleComponent PlayerGrappleComp = nullptr;
	UHazeAudioEmitter PlayerGrappleEmitter = nullptr;
	FHazeAudioPostEventInstance GrappleLoopEventInstance;

	FVector PlayerGrappleVelo;
	FVector CachedGrappleLocation;

	bool IsValid() const
	{
		return GrapplePointComp != nullptr;
	}
}

UCLASS(Abstract)
class UWorld_Shared_Platform_GrapplePoint_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(Category = "Audio Events", DisplayName = "Event - Grapple Point - Attach")
	UHazeAudioEvent GrapplePointAttachEvent;

	UPROPERTY(Category = "Audio Events", DisplayName = "Event - Grapple Point - Detach")
	UHazeAudioEvent GrapplePointDetachEvent;

	UPROPERTY(Category = "Audio Events", DisplayName = "Event - Grapple Point - Launch")
	UHazeAudioEvent GrapplePointLaunchEvent;

	UPROPERTY(Category = "Audio Events", DisplayName = "Event - Grapple Point - Passby")
	UHazeAudioEvent GrapplePointPassbyEvent;

	UPROPERTY(Category = "Passby", DisplayName = "Grapple - Passby - Apex Time", Meta=(EditCondition = "GrapplePointPassbyEvent != nullptr", ForceUnits = "seconds"))
	float GrapplePassbyApexTime = 0.3;

	UPROPERTY(Category = "Passby", DisplayName = "Grapple - Passby - Min Distance", Meta=(EditCondition = "GrapplePointPassbyEvent != nullptr"))
	float GrapplePassbyMinDistance = 0;

	UPROPERTY(Category = "Passby", DisplayName = "Grapple - Passby - Max Distance", Meta=(EditCondition = "GrapplePointPassbyEvent != nullptr"))
	float GrapplePassbyMaxDistance = 750;

	const float MAX_GRAPPLE_VELO_SPEED = 25.0;

	int PlayerGrappleCount = 0;
	TPerPlayer<FPlayerGrapplePointAudioData> PlayerGrappleDatas;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return PlayerGrappleCount > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return PlayerGrappleCount == 0;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TArray<UGrapplePointBaseComponent> GrapplePoints;
		HazeOwner.GetComponentsByClass(UGrapplePointBaseComponent, GrapplePoints);

		for(auto GrapplePoint : GrapplePoints)
		{
			GrapplePoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerStartedGrapple");
			GrapplePoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerStoppedGrapple");	
			GrapplePoint.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerStoppedGrapple");
		}
	}

	UFUNCTION()
	void OnPlayerStartedGrapple(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePointComponent)
	{
		auto& PlayerGrappleData = PlayerGrappleDatas[Player];	
		PlayerGrappleData.GrapplePointComp = GrapplePointComponent;

		if(PlayerGrappleData.PlayerGrappleComp == nullptr)
		{
			PlayerGrappleData.PlayerGrappleComp =  UPlayerGrappleComponent::Get(Player);
		}
		if(PlayerGrappleData.PlayerGrappleEmitter == nullptr)
		{
			auto EmitterAttachParams = FHazeAudioEmitterAttachmentParams();
			EmitterAttachParams.Attachment = GrapplePointComponent;
			EmitterAttachParams.EmitterName = n"GrapplePointEmitter";
			EmitterAttachParams.Owner = Player;
			EmitterAttachParams.Instigator = this;
			EmitterAttachParams.bCanAttach = true;

			PlayerGrappleData.PlayerGrappleEmitter = Audio::GetPooledEmitter(EmitterAttachParams);
			PlayerGrappleData.PlayerGrappleEmitter.SetPlayerPanning(Player);

			PlayerGrappleData.Player = Player;
		}

		StartPlayerGrapple(Player, PlayerGrappleData.PlayerGrappleEmitter, GrapplePointComponent.GrappleType);
		++PlayerGrappleCount;
	}

	UFUNCTION()
	void OnPlayerStoppedGrapple(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePointComponent)
	{
		auto& GrappleData = PlayerGrappleDatas[Player];
		if(!GrappleData.IsValid())
			return;

		StopPlayerGrapple(Player, GrappleData.PlayerGrappleEmitter, GrapplePointComponent.GrappleType);			
		GrappleData.GrapplePointComp = nullptr;
		--PlayerGrappleCount;
	}

	UFUNCTION(BlueprintEvent)
	void StartPlayerGrapple(AHazePlayerCharacter Player, UHazeAudioEmitter GrappleEmitter, EGrapplePointVariations GrappleType) {};

	UFUNCTION(BlueprintEvent)
	void StopPlayerGrapple(AHazePlayerCharacter Player, UHazeAudioEmitter GrappleEmitter, EGrapplePointVariations GrappleType) {};

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for(auto& PlayerGrappleData : PlayerGrappleDatas)
		{
			Audio::ReturnPooledEmitter(this, PlayerGrappleData.PlayerGrappleEmitter);
		}
	}
}