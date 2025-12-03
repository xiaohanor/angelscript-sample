event void FLightBirdAttachSignature();
event void FLightBirdIlluminateSignature();

class ULightBirdResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	/**
	 * Whether we want illumination events to only be sent to us when the bird is attached.
	 * If false, events will be sent to any object within it's illumination radius.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Response")
	bool bExclusiveAttachedIllumination = false;

	/**
	 * Whether this response component can be illuminated when the bird is in proximity,
	 * not just when it is attached to us.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Response")
	bool bCanBeIlluminatedFromProximity = false;

	/**
	 * Binds this response component's events to the response components of the selected actors.
	 * NOTE: If the array contains any actor, this response component will not receive events from the bird directly.
	 */
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Response")
	TArray<AActor> ListenToActors;

	UPROPERTY(Category = "Response")
	FLightBirdAttachSignature OnAttached;
	UPROPERTY(Category = "Response")
	FLightBirdAttachSignature OnDetached;
	UPROPERTY(Category = "Response")
	FLightBirdIlluminateSignature OnIlluminated;
	UPROPERTY(Category = "Response")
	FLightBirdIlluminateSignature OnUnilluminated;

	private bool bAttached = false;
	private bool bIlluminated = false;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FSoundDefReference SoundDefAsset;

	bool GetbIsAttached() const property
	{
		return bAttached;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = ListenToActors.Num() - 1; i >= 0; --i)
		{
			auto Actor = ListenToActors[i];
			if (Actor == nullptr || Actor == Owner)
			{
				ListenToActors.RemoveAt(i);
				continue;
			}

			AddListenToResponseActor(Actor);
		}

		if(SoundDefAsset.SoundDef.IsValid())
		{
			SoundDefAsset.SpawnSoundDefAttached(Owner, Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Actor : ListenToActors)
		{
			if (Actor == nullptr || Actor == Owner)
				continue;

			RemoveListenToResponseActor(Actor);
		}
	}

	void AddListenToResponseActor(AActor Actor)
	{
		auto ListenToResponse = ULightBirdResponseComponent::GetOrCreate(Actor);
		if (ListenToResponse != nullptr)
		{
			// Probably not technically any worse to chain, but I don't wanna deal with the untangling :^)
			if (ListenToResponse.IsListener())
			{
				devError(f"Attempting to chain response components by binding to a listening response component.\nBind this to the same actors as the other response component instead.");
			}

			ListenToResponse.OnAttached.AddUFunction(this, n"Attach");
			ListenToResponse.OnDetached.AddUFunction(this, n"Detach");
			ListenToResponse.OnIlluminated.AddUFunction(this, n"Illuminate");
			ListenToResponse.OnUnilluminated.AddUFunction(this, n"Unilluminate");
		}		

		// Audio needs this
		EffectEvent::LinkActorToReceiveEffectEventsFrom(Cast<AHazeActor>(Owner), Cast<AHazeActor>(Actor));
	}

	void RemoveListenToResponseActor(AActor Actor)
	{
		auto ListenToResponse = ULightBirdResponseComponent::Get(Actor);
		if (ListenToResponse != nullptr)
		{
			ListenToResponse.OnAttached.UnbindObject(this);
			ListenToResponse.OnDetached.UnbindObject(this);
			ListenToResponse.OnIlluminated.UnbindObject(this);
			ListenToResponse.OnUnilluminated.UnbindObject(this);
		}		
	}

	UFUNCTION(NotBlueprintCallable)
	void Attach()
	{
		bAttached = true;
		OnAttached.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void Detach()
	{
		bAttached = false;
		OnDetached.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void Illuminate()
	{
		bIlluminated = true;
		OnIlluminated.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void Unilluminate()
	{
		bIlluminated = false;
		OnUnilluminated.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void ConsumeAttachedIllumination()
	{
		if (bAttached)
		{
			auto UserComp = ULightBirdUserComponent::Get(Game::Mio);
			UserComp.ConsumeIllumination();
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsAttached() const
	{
		return bAttached;
	}
	
	UFUNCTION(BlueprintPure)
	bool IsIlluminated() const
	{
		return bIlluminated;
	}

	UFUNCTION(BlueprintPure)
	bool IsListener() const
	{
		return ListenToActors.Num() != 0;
	}
}