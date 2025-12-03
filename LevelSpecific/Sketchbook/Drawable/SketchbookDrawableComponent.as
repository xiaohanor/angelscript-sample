delegate void FSketchbookDrawableOnRequestQueued(bool bErase);
delegate void FSketchbookDrawableUpdateDrawnFraction(float Fraction, bool bErase);

event void FSketchbookDrawableOnStartBeingDrawn();
delegate void FSketchbookDrawableOnFinishBeingDrawn();

delegate void FSketchbookDrawableOnStartBeingErased();
delegate void FSketchbookDrawableOnFinishBeingErased();

enum ESketchbookDrawableState
{
	NotDrawn,

	BeingDrawn,
	Drawn,

	BeingErased,

	Interrupted,
};

struct FSketchbookDrawableRequest
{
	UPROPERTY(EditAnywhere)
	TSoftObjectPtr<AHazeActor> Actor;

	UPROPERTY(EditAnywhere)
	bool bErase = false;
};

UCLASS(Abstract, HideCategories = "ComponentTick Activation Cooking Disable Tags Navigation")
class USketchbookDrawableComponent : UActorComponent
{
	access Internal = private, USketchbookDrawablePropGroupComponent;

	UPROPERTY(EditAnywhere, Category = "Drawable")
	bool bDrawnFromStart = false;

	UPROPERTY(EditAnywhere, Category = "Drawable", Meta = (EditCondition = "TravelMode == ESketchbookDrawableRequestNextTravelAccelerationMode::AccelerateTo", EditConditionHides))
	float TravelDuration = 0.5;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Drawable|Preview")
	bool bPreviewErase = false;

	UPROPERTY(EditInstanceOnly, Category = "Drawable|Preview", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float PreviewFraction = 1.0;
#endif

	/**
	 * After executing OnFinishedBeingDrawn, these requests will be made.
	 */
	UPROPERTY(EditAnywhere, Category = "Drawable")
	TArray<FSketchbookDrawableRequest> AfterDrawnRequests;

	/**
	 * After executing OnFinishedBeingErased, these requests will be made.
	 */
	UPROPERTY(EditAnywhere, Category = "Drawable")
	TArray<FSketchbookDrawableRequest> AfterErasedRequests;

	FSketchbookDrawableUpdateDrawnFraction OnUpdateDrawnFraction;

	FSketchbookDrawableOnStartBeingDrawn OnStartBeingDrawn;
	FSketchbookDrawableOnFinishBeingDrawn OnFinishedBeingDrawn;

	FSketchbookDrawableOnStartBeingErased OnStartBeingErased;
	FSketchbookDrawableOnFinishBeingErased OnFinishedBeingErased;

	protected ESketchbookDrawableState State = ESketchbookDrawableState::NotDrawn;
	protected float DrawnFraction = 0;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	UHazeAudioEvent OnStartDrawnAudioEvent;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	UHazeAudioEvent OnStartErasedAudioEvent;

	private UHazeAudioEmitter DrawableEmitter;

	UHazeAudioEmitter GetAudioEmitter()
	{
		if (DrawableEmitter != nullptr)
			return DrawableEmitter;

		if (OnStartDrawnAudioEvent == nullptr && OnStartErasedAudioEvent == nullptr)
		{
			return nullptr;
		}

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
		EmitterParams.EmitterName = FName(f"{Owner.ActorNameOrLabel}_{'DrawablePropEmitter'}");
		#endif

		DrawableEmitter = Audio::GetPooledEmitter(EmitterParams);

		return DrawableEmitter;
	}

	#if EDITOR
	private bool bDebugProp = false;
	UFUNCTION()
	void OnToggleDebugAudio(bool bDebug)
	{
		bDebugProp = bDebug;
	}
	#endif


	access:Internal
	bool bInitializing = false;

	access:Internal
	bool bBeingReplaced = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		UpdateInEditor(false);
	}

	void UpdateInEditor(bool bForce)
	{
		for(int i = 0; i < AfterDrawnRequests.Num(); i++)
		{
			if(AfterDrawnRequests[i].Actor.IsValid() && !Sketchbook::IsDrawableActor(AfterDrawnRequests[i].Actor.Get()))
				AfterDrawnRequests[i].Actor = nullptr;
		}

		for(int i = 0; i < AfterErasedRequests.Num(); i++)
		{
			if(AfterErasedRequests[i].Actor.IsValid() && !Sketchbook::IsDrawableActor(AfterErasedRequests[i].Actor.Get()))
				AfterErasedRequests[i].Actor = nullptr;
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bInitializing = true;

		if(bDrawnFromStart)
		{
			FinishBeingDrawn();
			SetState(ESketchbookDrawableState::Drawn);
		}
		else
		{
			UpdateDrawnFraction(0.0, false);
			SetState(ESketchbookDrawableState::NotDrawn);
		}

		bInitializing = false;

#if EDITOR
		Sketchbook::DrawableProps::AudioDebugProps.BindOnChanged(this, n"OnToggleDebugAudio");
		Sketchbook::DrawableProps::AudioDebugProps.MakeVisible();
		bDebugProp = Sketchbook::DrawableProps::AudioDebugProps.IsEnabled();			
#endif

#if EDITOR
		TEMPORAL_LOG("Drawables").PersistentValue(f"{GetEditorString()};Actor", Owner);
		TEMPORAL_LOG("Drawables").PersistentValue(f"{GetEditorString()};Actor Enabled", !Owner.IsActorDisabled());
		TEMPORAL_LOG("Drawables").PersistentValue(f"{GetEditorString()};bDrawnFromStart", bDrawnFromStart);
#endif

	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
#if EDITOR
		TEMPORAL_LOG("Drawables").PersistentValue(f"{GetEditorString()};Actor Enabled", true);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
#if EDITOR
		TEMPORAL_LOG("Drawables").PersistentValue(f"{GetEditorString()};Actor Enabled", false);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Emitter = GetAudioEmitter();
		if(Emitter != nullptr && Emitter.IsPlaying())
		{	
			float X;
			float Y_;
			FVector2D Previous;
			Audio::GetScreenPositionRelativePanningValue(Emitter.AudioComponent.WorldLocation, Previous, X, Y_);	

			Emitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
		}	

		#if EDITOR
		if(IsDrawnOrBeingDrawn())
		{
			auto Log = TEMPORAL_LOG(Game::GetMio(), "Audio/DrawableProps");
			Log.Value(f"Props; {Owner.GetName().ToString()}", GetDrawnFraction());	
		}
		#endif	
	}

	void RequestDraw()
	{
		Sketchbook::GetPencil().RequestDraw(FSketchbookPencilRequest(this, false));
	}

	void UpdateDrawnFraction(float Fraction, bool bErase, FPlane DrawPlane = FPlane())
	{
		check(bInitializing || State == ESketchbookDrawableState::BeingDrawn || State == ESketchbookDrawableState::BeingErased);
		OnUpdateDrawnFraction.ExecuteIfBound(Fraction, bErase);
		DrawnFraction = Fraction;
	}

	float GetDrawnFraction() const
	{
		return DrawnFraction;
	}

	void StartBeingDrawn()
	{
		SetState(ESketchbookDrawableState::BeingDrawn);
		OnStartBeingDrawn.Broadcast();

		if(OnStartDrawnAudioEvent != nullptr)
			GetAudioEmitter().PostEvent(OnStartDrawnAudioEvent);
	}

	void FinishBeingDrawn()
	{
		check(bInitializing || State == ESketchbookDrawableState::BeingDrawn);
		UpdateDrawnFraction(1.0, false);
		SetState(ESketchbookDrawableState::Drawn);
		OnFinishedBeingDrawn.ExecuteIfBound();

		if(!bInitializing)
			RequestNext(AfterDrawnRequests);
	}

	void RequestErase()
	{
		Sketchbook::GetPencil().RequestErase(FSketchbookPencilRequest(this, true));
	}

	void StartBeingErased()
	{
		SetState(ESketchbookDrawableState::BeingErased);

		if(bBeingReplaced)
			return;

		OnStartBeingErased.ExecuteIfBound();
		
		if(OnStartErasedAudioEvent != nullptr)
			GetAudioEmitter().PostEvent(OnStartErasedAudioEvent);
	}

	void FinishBeingErased()
	{
		check(State == ESketchbookDrawableState::BeingErased);
		UpdateDrawnFraction(1.0, true);
		SetState(ESketchbookDrawableState::NotDrawn);

		if(bBeingReplaced)
			return;

		OnFinishedBeingErased.ExecuteIfBound();

		if(!bInitializing)
			RequestNext(AfterErasedRequests);
	}

	void ImmediatelyErase()
	{
		if(State == ESketchbookDrawableState::NotDrawn)
			return;
		
		SetState(ESketchbookDrawableState::BeingErased);
		UpdateDrawnFraction(0, true);
		SetState(ESketchbookDrawableState::NotDrawn);
	}

	void Interrupt()
	{
		check(!bInitializing);

		if(!IsBeingDrawnOrErased())
			return;

		SetState(ESketchbookDrawableState::Interrupted);
	}

	access:Internal
	void SetState(ESketchbookDrawableState NewState)
	{
#if EDITOR
		TEMPORAL_LOG("Drawables").PersistentValue(f"{GetEditorString()};State", NewState);
#endif

		if(NewState == ESketchbookDrawableState::NotDrawn)
		{
			if(!Owner.IsActorDisabledBy(this))
			{
#if EDITOR
				TEMPORAL_LOG("Drawables").Event(f"Disabled Drawable {Owner.GetActorNameOrLabel()}");
#endif
				Owner.AddActorDisable(this);
			}
		}
		else
		{
			if(Owner.IsActorDisabledBy(this))
			{
#if EDITOR
				TEMPORAL_LOG("Drawables").Event(f"Enabled Drawable {Owner.GetActorNameOrLabel()}");
#endif
				Owner.RemoveActorDisable(this);
			}	
		}

		State = NewState;
	}

	void RequestNext(TArray<FSketchbookDrawableRequest>& NextRequests) const
	{
		if(!Sketchbook::GetPencil().HasControl())
			return;

		for(auto NextRequest : NextRequests)
		{
			if(NextRequest.Actor.IsNull())
				continue;
			
			if (!NextRequest.bErase)
				Sketchbook::SketchbookRequestDrawActor(NextRequest.Actor.Get());
			else
				Sketchbook::SketchbookRequestEraseActor(NextRequest.Actor.Get());
		}
	}

	ESketchbookDrawableState GetState() const
	{
		return State;
	}

	bool IsDrawnOrBeingDrawn() const
	{
		switch (State)
		{
			case ESketchbookDrawableState::NotDrawn:
				return false;

			case ESketchbookDrawableState::BeingDrawn:
			case ESketchbookDrawableState::Drawn:
				return true;

			case ESketchbookDrawableState::BeingErased:
				return false;

			case ESketchbookDrawableState::Interrupted:
				return false;
		}
	}

	bool IsBeingDrawnOrErased() const
	{
		if(State == ESketchbookDrawableState::BeingDrawn)
			return true;

		if(State == ESketchbookDrawableState::BeingErased)
			return true;

		return false;
	}

	bool IsFinishedDrawing() const
	{
		return State == ESketchbookDrawableState::Drawn;
	}

	bool WasInterrupted() const
	{
		return State == ESketchbookDrawableState::Interrupted;
	}

	/**
	 * Interface
	 */

	// Called before the pencil starts traveling to us.
	void PrepareTravelTo(bool bErase, FVector TravelFromLocation)
	{
	}

	// @return Where the pencil should travel to begin.
	FVector GetTravelToLocation(bool bErase) const
	{
		return Owner.ActorLocation;
	}

	// @return Where the pencil should travel from when it is finished.
	FVector GetTravelFromLocation(bool bErase) const
	{
		check(false);
		return Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(DrawableEmitter != nullptr)
			Audio::ReturnPooledEmitter(this, DrawableEmitter);
	}

#if EDITOR
	FString GetEditorString() const
	{
		return Owner.ActorNameOrLabel;
	}

	void CalculateEditorBounds(FVector&out OutOrigin, FVector&out OutExtents) const
	{
		OutOrigin = Owner.ActorLocation;
		OutExtents = FVector(100);
	}

	UFUNCTION(CallInEditor, Category = "Drawable")
	private void OpenSketchbookToolsWindow()
	{
		Sketchbook::Editor::OpenToolsWindow();
	}
#endif
};

#if EDITOR
class USketchbookDrawableVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USketchbookDrawableComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Drawable = Cast<USketchbookDrawableComponent>(Component);
		if(Drawable == nullptr)
			return;

		for(auto AfterDrawnRequest : Drawable.AfterDrawnRequests)
		{
			if(AfterDrawnRequest.Actor == nullptr)
				continue;

			DrawArrowToRequest(Drawable, AfterDrawnRequest, false);
		}

		for(auto AfterErasedRequest : Drawable.AfterErasedRequests)
		{
			if(AfterErasedRequest.Actor == nullptr)
				continue;

			DrawArrowToRequest(Drawable, AfterErasedRequest, true);
		}
	}

	private void DrawArrowToRequest(USketchbookDrawableComponent Drawable, FSketchbookDrawableRequest Request, bool bAfterErase) const
	{
		const auto RequestDrawable = USketchbookDrawableComponent::Get(Request.Actor.Get());
		if(RequestDrawable == nullptr)
			return;

		const FVector TravelFromLocation = Drawable.GetTravelFromLocation(bAfterErase);
		const FVector TravelToLocation = RequestDrawable.GetTravelToLocation(Request.bErase);

		FLinearColor EventColor = bAfterErase ? FLinearColor::Red : FLinearColor::Green;
		FLinearColor ActionColor = Request.bErase ? FLinearColor::Red : FLinearColor::Green;
		DrawArrow(TravelFromLocation, TravelToLocation, EventColor, 5, 3);

		FVector Origin;
		FVector Extents;
		RequestDrawable.CalculateEditorBounds(Origin, Extents);
		DrawWireBox(Origin, Extents, FQuat::Identity, ActionColor);

		const FVector CenterLocation = (TravelFromLocation + TravelToLocation) / 2;
		
		FString DebugText = bAfterErase ? "After Erase:\n" : "After Drawn:\n";
		DebugText += Request.bErase ? "Erase " : "Draw ";

		if(RequestDrawable == Drawable)
		{
			DebugText += "self";
		}
		else
		{
			DebugText += f"\"{RequestDrawable.GetEditorString()}\"";
		}

		DrawWorldString(DebugText, CenterLocation, EventColor, bCenterText = true);
	}
}
#endif

namespace Sketchbook
{
	bool IsDrawableActor(const AActor Actor)
	{
		if(Actor == nullptr)
			return false;

		auto Drawable = USketchbookDrawableComponent::Get(Actor);
		if(Drawable == nullptr)
			return false;

		return true;
	}
}