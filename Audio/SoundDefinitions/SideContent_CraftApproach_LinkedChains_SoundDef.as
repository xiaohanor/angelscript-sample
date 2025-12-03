
struct FLinkedChainsEmitterState
{
	UPROPERTY()
	bool bActive = true;

	UPROPERTY()
	UHazeAudioEmitter Emitter;

	UPROPERTY()
	USummitChainLinkSpeedAudioComponent Link;

	void LinkTo(USummitChainLinkSpeedAudioComponent InLink)
	{
		Link = InLink;
		Emitter.AudioComponent.AttachToComponent(Link, AttachmentRule = EAttachmentRule::SnapToTarget);
	}

	float GetSpeed() const
	{
		if (Link != nullptr)
			return Link.GetSpeed();

		return 0;
	}
}

UCLASS(Abstract)
class USideContent_CraftApproach_LinkedChains_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLinkMelted(FSummitLinkedChainOnLinkMeltedParams Params){}

	/* END OF AUTO-GENERATED CODE */

	// We spawn them in when needed.
	UPROPERTY()
	TArray<FLinkedChainsEmitterState> LinkedEmitters;

	ASummitLinkedChain LinkedChain;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LinkedChain = Cast<ASummitLinkedChain>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	bool HasAnyEmitters() const
	{
		return LinkedEmitters.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	float GetFirstSpeed() const
	{
		if (LinkedChain.GetFirstLinkedAudioComp() != nullptr)
			return LinkedChain.GetFirstLinkedAudioComp().GetSpeed();

		return 0;
	}
	
	UFUNCTION(BlueprintPure)
	float GetLastSpeed() const
	{
		if (LinkedChain.GetLastLinkedAudioComp() != nullptr)
			return LinkedChain.GetLastLinkedAudioComp().GetSpeed();

		return 0;
	}
	
	UFUNCTION()
	void CreateEmitters()
	{
		if (LinkedEmitters.Num() > 0)
		{
			if (LinkedChain.GetFirstLinkedAudioComp() != nullptr)
				LinkedEmitters[0].LinkTo(LinkedChain.GetFirstLinkedAudioComp());

			if (LinkedChain.GetLastLinkedAudioComp() != nullptr)
				LinkedEmitters[1].LinkTo(LinkedChain.GetLastLinkedAudioComp());
			return;
		}

		auto PoolParams = FHazeAudioEmitterAttachmentParams();
		PoolParams.bCanAttach = false;
		PoolParams.Owner = HazeOwner;
		PoolParams.Instigator = this;
		PoolParams.bSetOverrideTransform = true;
		PoolParams.Transform = HazeOwner.ActorTransform;

		// Attach afterwards so they don't get assume to live on the linked components.
		CreateEmitter(PoolParams, LinkedChain.GetFirstLinkedAudioComp());
		CreateEmitter(PoolParams, LinkedChain.GetLastLinkedAudioComp());
	}

	void CreateEmitter(FHazeAudioEmitterAttachmentParams& Params, USummitChainLinkSpeedAudioComponent Link)
	{
		if (Link == nullptr)
			return;
		
		FLinkedChainsEmitterState EmitterState;
		EmitterState.Emitter = Audio::GetPooledEmitter(Params);
		// Attach afterwards so they don't get assume to live on the linked components.
		EmitterState.LinkTo(Link);
		LinkedEmitters.Add(EmitterState);

		OnCreatedEmitter(LinkedEmitters.Last().Emitter);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (LinkedChain.GetFirstLinkedAudioComp() != nullptr || 
			LinkedChain.GetLastLinkedAudioComp() != nullptr)
		{
			CreateEmitters();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (const auto& EmitterState : LinkedEmitters)
		{
			Audio::ReturnPooledEmitter(this, EmitterState.Emitter);
		}

		LinkedEmitters.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for (int i=0; i<LinkedEmitters.Num(); ++i)
		{
			auto& EmitterState = LinkedEmitters[i];

			bool bPreviousState = EmitterState.bActive;
			// If it has been disabled or no longer exists there is no point in updating it.
			if (bPreviousState == false)
				continue;

			EmitterState.bActive = EmitterState.Emitter != nullptr && EmitterState.Link != nullptr;
			OnUpdateEmitter(EmitterState.Emitter, EmitterState.GetSpeed());
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnCreatedEmitter(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintEvent)
	void OnUpdateEmitter(UHazeAudioEmitter Emitter, float Speed) {}

	UFUNCTION(BlueprintOverride)
	void DebugTick(float DeltaSeconds)
	{
#if TEST
		for (const auto& EmitterState : LinkedEmitters)
		{
			Debug::DrawDebugPoint(EmitterState.Emitter.AudioComponent.WorldLocation, 50, FLinearColor::LucBlue);
		}
#endif
	}
}