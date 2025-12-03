
UCLASS(Abstract)
class UWorld_Sanctuary_Shared_Interactable_DarkPortal_GrabbableObject_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UDarkPortalResponseComponent DarkPortalResponse;
	UFauxPhysicsTranslateComponent FauxTranslation;
	UFauxPhysicsAxisRotateComponent FauxRotation;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = !bUseMultiPosition))
	FName AttachComponentName = NAME_None;

	UPROPERTY(EditDefaultsOnly, Category = Positioning)
	bool bUseMultiPosition = false;

	UPROPERTY(EditDefaultsOnly, Category = Positioning, Meta = (EditCondition = bUseMultiPosition))
	TPerPlayer<bool> TrackPlayers;	

	UPROPERTY(EditDefaultsOnly, Category = Positioning, Meta = (EditCondition = bUseMultiPosition))
	FName MultiPosColliderName;

	UPROPERTY(BlueprintReadOnly, Category = Movement, EditDefaultsOnly, Meta = (ForceUnits = "speed"))
	float MaxTranslationSpeed = 500;

	UPROPERTY(BlueprintReadOnly, Category = Movement, EditDefaultsOnly, Meta = (ForceUnits = "speed"))
	float MaxRotationSpeed = 3;

	UPROPERTY(EditDefaultsOnly)
	bool bAlwaysActive = false;

	// If true, final movement alpha will be calcuated from a combination of rotation and translation for objects that move in both of these ways. If false, max will be used
	UPROPERTY(EditDefaultsOnly, Category = Movement)
	bool bCombineRotationAndTranslationAlpha = true;

	private bool bHasCachedFrameSpeed = false;
	private float CachedFrameSpeed = 0.0;

	UFUNCTION(BlueprintEvent)
	void OnMinRotationConstrainHit(float Strength) {};

	UFUNCTION(BlueprintEvent)
	void OnMaxRotationConstrainHit(float Strength) {};

	private UPrimitiveComponent MultiPosComp;

	bool GetbIsGrabbed() const property
	{
		return DarkPortalResponse.Grabs.Num() > 0;
	}

	bool GetbObjectRotates() const property
	{
		return FauxRotation != nullptr;
	}

	bool GetbObjectTranslates() const property
	{
		return FauxTranslation != nullptr;
	}

	private float CalculateFauxPhysicsAlpha() const
	{
		if(bObjectRotates && bObjectTranslates)
		{
			float RotationAlpha = FauxRotation.GetCurrentAlphaBetweenConstraints();
			float TranslationAlpha = FauxTranslation.GetCurrentAlphaBetweenConstraints().Size();

			if(bCombineRotationAndTranslationAlpha)
				return (RotationAlpha + TranslationAlpha) / 2;

			return Math::Max(RotationAlpha, TranslationAlpha);
		}
		else if(bObjectRotates)
		{
			return FauxRotation.GetCurrentAlphaBetweenConstraints();
		}
		else if(bObjectTranslates)
		{
			return FauxTranslation.GetCurrentAlphaBetweenConstraints().Size(); 
		}

		return 0.0;
	}

	private float CalculateFauxSpeed()
	{
		float TranslationSpeed = 0;
		float RotationSpeed = 0;
		bHasCachedFrameSpeed = true;

		if(bObjectRotates)
			RotationSpeed = Math::Min(1, (FauxRotation.Velocity / MaxRotationSpeed));

		if(bObjectTranslates)
			TranslationSpeed = Math::Min(1, (FauxTranslation.GetVelocity().Size() / MaxTranslationSpeed));

		if(bObjectTranslates && bObjectRotates && bCombineRotationAndTranslationAlpha)
		{			
			return (TranslationSpeed + RotationSpeed) / 2;						
		}
		else if(bObjectRotates)
			return RotationSpeed;
		else if(bObjectTranslates)
			return TranslationSpeed;			

		return 0.0;
	}

	private bool IsSleeping() const
	{
		bool bRotationSleeping = bObjectRotates ? FauxRotation.IsSleeping() : true;
		bool bTranslationSleeping = bObjectTranslates ? FauxTranslation.IsSleeping() : true;		

		return bTranslationSleeping && bRotationSleeping;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DarkPortalResponse == nullptr)
			return false;

		if(bAlwaysActive)
			return true;

		if(bIsGrabbed)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bAlwaysActive)
			return false;

		if(DarkPortalResponse.Grabs.Num() > 0)
			return false;

		if(!IsSleeping())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkPortalResponse = UDarkPortalResponseComponent::Get(HazeOwner);

		if(DarkPortalResponse == nullptr)
		{
			#if EDITOR
			devCheck(false, "No DarkPortalResponseComponent on SoundDef-actor: " + HazeOwner.ActorNameOrLabel);
			#endif

			return;
		}

		FauxTranslation = UFauxPhysicsTranslateComponent::Get(HazeOwner);
		FauxRotation = UFauxPhysicsAxisRotateComponent::Get(HazeOwner);

		DarkPortalResponse.OnInitialGrab.AddUFunction(this, n"OnGrabbed");
		DarkPortalResponse.OnLastRelease.AddUFunction(this, n"OnReleased");

		if(bUseMultiPosition && MultiPosColliderName != NAME_None)
		{
			MultiPosComp = UPrimitiveComponent::Get(HazeOwner, MultiPosColliderName);
		}
		else if(AttachComponentName != NAME_None)
		{
			DefaultEmitter.AudioComponent.AttachToComponent(USceneComponent::Get(HazeOwner, AttachComponentName));
		}

		if(bObjectRotates)
		{			
			FauxRotation.OnMinConstraintHit.AddUFunction(this, n"OnMinRotationConstrainHit");
			FauxRotation.OnMaxConstraintHit.AddUFunction(this, n"OnMaxRotationConstrainHit");
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		#if EDITOR
		Log();
		#endif

		if(MultiPosComp != nullptr)
		{
			TArray<FAkSoundPosition> SoundPositions;
			for(auto Player : Game::GetPlayers())
			{
				if(!TrackPlayers[Player])
					continue;

				FVector ClosestPlayerPos;
				MultiPosComp.GetClosestPointOnCollision(Player.ActorLocation, ClosestPlayerPos);

				SoundPositions.Add(FAkSoundPosition(ClosestPlayerPos));
			}

			DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
		}

		bHasCachedFrameSpeed = false;
	}

	UFUNCTION(BlueprintEvent)
	void OnGrabbed(ADarkPortalActor DarkPortal, UDarkPortalTargetComponent DarkPortalTargetComp) {}

	UFUNCTION(BlueprintEvent)
	void OnReleased(ADarkPortalActor DarkPortal, UDarkPortalTargetComponent DarkPortalTargetComp) {}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Movement Range Alpha"))
	float GetMovementRangeAlpha()
	{
		auto Alpha = CalculateFauxPhysicsAlpha();
		return Alpha;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Normalized Movement Speed"))
	float GetMovementSpeed()
	{
		if(!bHasCachedFrameSpeed)
		{
		 CachedFrameSpeed = Math::Abs(CalculateFauxSpeed());

		}

		return CachedFrameSpeed;
	}
	
	private void Log()
	{
		FTemporalLog Log = TEMPORAL_LOG(this, "Audio");

		if(bObjectRotates)
			Log.Value("Rotation Speed: ", FauxRotation.Velocity);

		if(bObjectTranslates)
			Log.Value("Translation Speed: ", FauxTranslation.GetVelocity().Size());

		Log.Value("Alpha: ", CalculateFauxPhysicsAlpha());
	}
}