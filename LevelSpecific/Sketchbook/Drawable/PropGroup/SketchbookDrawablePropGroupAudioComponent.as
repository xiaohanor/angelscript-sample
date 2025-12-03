struct FSketchbookDrawablePropGroupAudioEventData
{
	UPROPERTY(EditInstanceOnly, Meta = (UIMin = 0.0, UIMax = 1.0, ClampMin = 0.0, ClampMax = 1.0))
	float TriggerFraction = 0.0;

	UPROPERTY(EditInstanceOnly, DisplayName)
	bool bTriggerOnDraw = true;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent Event;
}

class USketchbookDrawablePropGroupAudioComponent : UActorComponent
{
	private UHazeAudioEmitter DrawableEmitter;

	UPROPERTY(EditInstanceOnly, Category = "Drawable", Meta = (TitleProperty = {Event}))
	TArray<FSketchbookDrawablePropGroupAudioEventData> DrawableEvents;

	private float LastFraction = -1.0;
	default ComponentTickEnabled = false;
	private FVector2D PreviousScreenPosition;

	UHazeAudioEmitter GetEmitter()
	{
		if (DrawableEmitter != nullptr)
			return DrawableEmitter;

		// We never know if this object will be loaded before or after the pencil.
		// Since we will only get the emitter when needed, this shouldn't be a problem.
		auto Pencil = Sketchbook::GetPencil();
		// Safety first.
		if (Pencil == nullptr)
			return nullptr;
		
		FHazeAudioEmitterAttachmentParams EmitterParams;
		EmitterParams.Attachment = Sketchbook::GetPencil().Root;
		EmitterParams.Owner = this;
		EmitterParams.Instigator = this;

		#if TEST
		EmitterParams.EmitterName = FName(f"{GetOwner().ActorNameOrLabel}_{'DrawablePropGroupEmitter'}");
		#endif
		DrawableEmitter = Audio::GetPooledEmitter(EmitterParams);

		return DrawableEmitter;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LastFraction = -1.0;
		auto DrawablePropGroupComponent = USketchbookDrawablePropGroupComponent::Get(Owner);
		if(!devEnsure(DrawablePropGroupComponent != nullptr, f"Tried to use {Class.Name} on an actor without a {USketchbookDrawablePropGroupComponent.Get().Name}, that is verboden!"))
			return;

		DrawablePropGroupComponent.OnUpdateDrawnFraction.BindUFunction(this, n"OnUpdateDrawFraction");
	}

	#if EDITOR
	void UpdateInEditor(float Fraction)
	{
		const bool bIsErase = Fraction < LastFraction;
		OnUpdateDrawFraction(Fraction, bIsErase);
		LastFraction = Fraction;
	}
	#endif

	UFUNCTION()
	void OnUpdateDrawFraction(float Fraction, bool bErase)
	{
		for(auto EventData : DrawableEvents)
		{
			if(EventData.Event == nullptr)
				continue;
			

			if((EventData.bTriggerOnDraw && bErase) || (!EventData.bTriggerOnDraw && !bErase))
				continue;


			bool bCanTriggerOnFraction = (!bErase && (LastFraction < EventData.TriggerFraction && Fraction >= EventData.TriggerFraction))
			|| (bErase && (LastFraction > EventData.TriggerFraction && Fraction <= EventData.TriggerFraction));
			if(bCanTriggerOnFraction)
			{
				#if EDITOR
				if(!Editor::IsPlaying())
				{
					AudioComponent::PostGlobalEvent(EventData.Event);
					return;
				}
				#endif

				// The emitter must be possible to create at this point.
				GetEmitter().PostEvent(EventData.Event, FOnHazeAudioPostEventCallback(this, n"OnPostEventCallback"));
				SetComponentTickEnabled(true);
			}

		}

		LastFraction = Fraction;
	}

	UFUNCTION()
	void OnPostEventCallback(EAkCallbackType CallbackType, UHazeAudioCallbackInfo CallbackInfo)
	{	
		if(CallbackType == EAkCallbackType::EndOfEvent)
		{
			SetComponentTickEnabled(GetEmitter().IsPlaying());
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Emitter = GetEmitter();
		if (Emitter == nullptr)
			return;

		float X;
		float Y_;
		if (!Audio::GetScreenPositionRelativePanningValue(Emitter.AudioComponent.WorldLocation, PreviousScreenPosition, X, Y_))
			return;

		Emitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(DrawableEmitter != nullptr)
			Audio::ReturnPooledEmitter(this, DrawableEmitter);
	}
}