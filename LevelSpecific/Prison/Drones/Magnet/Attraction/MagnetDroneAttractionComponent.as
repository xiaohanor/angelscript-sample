/**
 * Data passed through in the AttractionStarted event
 */
struct FMagnetDroneAttractionStartedParams
{
	UPROPERTY()
	float TimeUntilArrival;
};

enum EMagnetDroneIntendedTargetResult
{
	Finish,
	Continue,
	Invalidate
};

enum EMagnetDroneStartAttractionInstigator
{
	None,

	// UMagnetDroneStartAttractAimCapability
	Aim,

	// UMagnetDroneStartAttractClosestSurfaceCapability
	ClosestSurface,

	// UMagnetDroneStartAttractGroundSurfaceCapability
	GroundSurface,

	// UMagnetDroneStartAttractJumpCapability
	Jump,

	// UPinballMagnetDroneMagnetStartAttractAimCapability
	PinballAim,

	// UPinballMagnetDroneMagnetStartAttractBossBallCapability
	PinballBossBall
};

struct FMagnetDroneAttractionMovementIgnoreActorsParams
{
	TArray<AActor> Actors;
	FInstigator Instigator;
	uint ApplyFrame;

	bool IsValid()
	{
		if(Actors.IsEmpty())
			return false;

		if (Time::FrameNumber > ApplyFrame + 1)
			return false;

		return true;
	}
};

namespace MagnetDroneTags
{
	const FName BlockedWhileAttraction = n"BlockedWhileAttraction";
}

UCLASS(Abstract)
class UMagnetDroneAttractionComponent : UActorComponent
{
#if RELEASE
	default PrimaryComponentTick.bStartWithTickEnabled = false;
#else
	default PrimaryComponentTick.bStartWithTickEnabled = true;
#endif

	access Preview = private, UMagnetDroneAttractionPreviewCapability;
	access Input = private, UMagnetDroneAttractionInputCapability, UPinballMagnetAttractionInputCapability;
	access StartAttract = private, UMagnetDroneStartAttractAimCapability, UMagnetDroneStartAttractClosestSurfaceCapability, UMagnetDroneStartAttractGroundSurfaceCapability, UMagnetDroneStartAttractJumpCapability, UPinballMagnetStartAttractAimCapability, UPinballMagnetStartAttractBossBallCapability;
	access StartAttractTarget = private, UMagnetDroneStartAttractAimCapability, UMagnetDroneStartAttractClosestSurfaceCapability, UMagnetDroneStartAttractGroundSurfaceCapability, UMagnetDroneStartAttractJumpCapability, UMagnetDroneAttractionCloseCapability, UMagnetDroneAttractionFarCapability, UMagnetDroneAttractionWallCapability, UMagnetDroneAttractJumpAttractionCapability, UPinballMagnetDroneMagnetAttractionMovementCapability, UMagnetDroneNoMagneticSurfaceFoundCapability;
	access Attraction = private, UMagnetDroneAttractionModesCapability, UPinballMagnetAttractionModesCapability;
	access AttachTo = private, UMagnetDroneAttractionModesCapability, UPinballMagnetAttractionModesCapability;
	access Resolver = private, UMagnetDroneAttractionMovementResolver;

	UPROPERTY(EditDefaultsOnly)
	private UMagnetDroneAttractionSettings DefaultSettings;

	UPROPERTY(EditDefaultsOnly)
	private TArray<TSubclassOf<UMagnetDroneAttractionMode>> AttractionModeClasses;

	private AHazePlayerCharacter Player;
	private UPlayerMovementComponent MoveComp;

	UMagnetDroneAttractionSettings Settings;

	TArray<UMagnetDroneAttractionMode> AttractionModes;

	private FMagnetDroneAttractionMovementIgnoreActorsParams MovementIgnoreActors;

	access:Input bool bAttractionInput;
	
	access:AttachTo FMagnetDroneTargetData AttractionTarget;
	private uint StartAttractFrame = 0;
	private float StartAttractTime = 0;
	private EMagnetDroneStartAttractionInstigator AttractionTargetInstigator;

	access:Attraction FMagnetDroneAttractionStartedParams AttractionStartedParams;

	private bool bIsAttracting = false;
	private float AttractionAlpha = 0.0;
	private FInstigator AttractingInstigator;

	// A kind of hacky way for the resolver to tell us we might be stuck
	access:Resolver uint AttractionMightBeStuckFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);

		Player.ApplyDefaultSettings(DefaultSettings);
		Settings = UMagnetDroneAttractionSettings::GetSettings(Player);

		for(auto AttractionModeClass : AttractionModeClasses)
		{
			auto AttractionMode = Cast<UMagnetDroneAttractionMode>(NewObject(this, AttractionModeClass));
			AttractionMode.MakeNetworked(this, AttractionMode.Name);
			AttractionModes.Add(AttractionMode);
		}

		AttractionModes.Sort();

		for(auto AttractionMode : AttractionModes)
		{
			auto SetupParams = FMagnetDroneAttractionModeSetupParams(Player);
			AttractionMode.Setup(SetupParams);
		}

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneAttraction");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		FTemporalLog InputLog = TemporalLog.Section("Input", 1);
		FTemporalLog AttractionTargetLog = TemporalLog.Section("Attraction Target", 2);
		FTemporalLog AttractionLog = TemporalLog.Section("Attraction", 3);

		InputLog.Value("bAttractionInput", bAttractionInput);

		AttractionTarget.LogToTemporalLog(AttractionTargetLog);
		AttractionTargetLog.Value("AttractionTargetInstigator", AttractionTargetInstigator);

		if(IsAttracting())
		{
			AttractionLog.Value("StartAttractFrame", StartAttractFrame);
			AttractionLog.Value("StartAttractTime", StartAttractTime);
			AttractionLog.Value("AttractingInstigator", AttractingInstigator);

			AttractionLog.Value("AttractionAlpha", AttractionAlpha);
			AttractionLog.Value("AttractionMightBeStuckFrame", AttractionMightBeStuckFrame);
		}

		for(int i = 0; i < AttractionModes.Num(); i++)
		{
			auto AttractionMode = AttractionModes[i];
			TemporalLog.Value(f"Attraction Mode;[{i}]", AttractionMode.Class);
		}
#endif
	}

	UMagnetDroneAttractionMode GetAttractionMode(TSubclassOf<UMagnetDroneAttractionMode> AttractionModeClass) const
	{
		for(auto AttractionMode : AttractionModes)
		{
			if(AttractionMode.Class == AttractionModeClass)
				return AttractionMode;
		}

		check(false);
		return nullptr;
	}

	bool IsAttractionInputAllowed() const
	{
		if(bIsAttracting)
			return false;

		// If we were just attracting, wait a while
		if(Time::GetGameTimeSince(StartAttractTime) < Settings.MinimumAttractionInterval)
			return false;

		return true;
	}

	bool IsInputtingAttract() const
	{
		return bAttractionInput;
	}

	access:StartAttract
	void SetStartAttractTarget(FMagnetDroneTargetData InAttractionTarget, EMagnetDroneStartAttractionInstigator Instigator)
	{
		check(!IsAttracting());
		check(InAttractionTarget.IsValidTarget());

		AttractionTarget = InAttractionTarget;
		AttractionTargetInstigator = Instigator;
		StartAttractFrame = Time::FrameNumber;
		StartAttractTime = Time::GameTimeSeconds;
	}

	bool HasSetStartAttractTargetThisFrame() const
	{
		if(!AttractionTarget.IsValidTarget())
			return false;

		return StartAttractFrame == Time::FrameNumber;
	}

	float GetStartAttractTime() const
	{
		return StartAttractTime;
	}

	bool HasAttractionTarget() const 
	{
		return AttractionTarget.IsValidTarget();
	}

	const FMagnetDroneTargetData& GetAttractionTarget() const
	{
		check(HasAttractionTarget());
		return AttractionTarget;
	}

	EMagnetDroneStartAttractionInstigator GetAttractionTargetInstigator() const
	{
		return AttractionTargetInstigator;
	}

	void IgnoreActorsWhileAttracting(TArray<AActor> Actors, FInstigator Instigator)
	{
		if(!ensure(!MovementIgnoreActors.IsValid(), f"IgnoreActorsWhileAttracting has already been called by {MovementIgnoreActors.Instigator}!"))
			return;
		
		MovementIgnoreActors.Instigator = Instigator;
		MovementIgnoreActors.Actors = Actors;
		MovementIgnoreActors.ApplyFrame = Time::FrameNumber;
	}

	access:Attraction
	void StartAttraction(FInstigator Instigator)
	{
		check(!IsAttracting());
		check(AttractionTarget.IsValidTarget());

		bIsAttracting = true;
		AttractionAlpha = 0;
		
		AttractingInstigator = Instigator;

		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileAttraction, Instigator);

		if(MovementIgnoreActors.IsValid())
			MoveComp.AddMovementIgnoresActors(this, MovementIgnoreActors.Actors);

		FOnMagnetDroneStartAttractionParams StartAttractionParams;
		if(AttractionTarget.IsSocket())
		{
			AttractionTarget.GetSocketComp().OnMagnetDroneStartAttraction.Broadcast(StartAttractionParams);
		}
		else if(AttractionTarget.IsSurface())
		{
			AttractionTarget.GetSurfaceComp().OnMagnetDroneStartAttraction.Broadcast(StartAttractionParams);
		}
	}

	const FMagnetDroneAttractionStartedParams& GetAttractionStartedParams() const
	{
		return AttractionStartedParams;
	}

	access:Attraction
	void FinishAttraction(bool bSuccess, FInstigator Instigator)
	{
		check(AttractingInstigator == Instigator);

		FOnMagnetDroneEndAttractionParams EndAttractionParams;
		EndAttractionParams.bSuccess = bSuccess;
		
		if(AttractionTarget.IsSocket())
		{
			AttractionTarget.GetSocketComp().OnMagnetDroneEndAttraction.Broadcast(EndAttractionParams);
		}
		else if(AttractionTarget.IsSurface())
		{
			AttractionTarget.GetSurfaceComp().OnMagnetDroneEndAttraction.Broadcast(EndAttractionParams);
		}

		if(bSuccess)
		{
			AttractionAlpha = 1.0;
		}
		else
		{
			AttractionAlpha = 0;
			AttractionTarget.Invalidate(n"AttractionTarget FinishAttraction", Instigator);
		}

		bIsAttracting = false;
		AttractingInstigator = nullptr;

		Player.UnblockCapabilities(MagnetDroneTags::BlockedWhileAttraction, Instigator);

		MoveComp.RemoveMovementIgnoresActor(this);
	}

	access:Attraction
	void SetAttractionAlpha(float InAttractionAlpha)
	{
		// use time to predict when we reach the target
		AttractionAlpha = InAttractionAlpha;
	}

	float GetAttractionAlpha() const
	{
		return AttractionAlpha;
	}

	bool IsAttracting() const
	{
		if(!AttractionTarget.IsValidTarget())
			return false;

		return bIsAttracting;
	}

	bool HasFinishedAttracting() const
	{
		return AttractionAlpha > 1.0 - KINDA_SMALL_NUMBER;
	}

	bool ShouldApplyAttractionFOV() const
	{
		// Never apply FOV while in full screen
		if(SceneView::IsFullScreen() || SceneView::IsPendingFullscreen())
			return false;

		if(Player.GetCurrentGameplayPerspectiveMode() != EPlayerMovementPerspectiveMode::ThirdPerson)
			return false;

		// Don't apply attraction FOV when using an activated camera
		if(Player.CurrentlyUsedCamera.Owner != Player)
			return false;

		return true;
	}

	bool CanApplyCameraSettings() const
	{
		if(SceneView::IsFullScreen())
			return false;

		if(SceneView::IsPendingFullscreen())
			return false;

		return true;
	}

	bool GetAttractionMightBeStuckThisFrame() const
	{
		return AttractionMightBeStuckFrame >= Time::FrameNumber - 1;
	}

#if !RELEASE
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(this);
	}
#endif
};