struct FGameShowArenaAnnouncerAnimData
{
	UPROPERTY(Interp)
	float LowerPistonExtend;
	UPROPERTY(Interp)
	float UpperPistonExtend;
	UPROPERTY(Interp)
	float BaseTwist;
	UPROPERTY(Interp)
	float BodyRotation;
	UPROPERTY(Interp)
	float TargetSplineDistance;
	UPROPERTY(Interp)
	FVector IKArm8CtrlLocation;
	UPROPERTY(Interp)
	FTransform IKArm13Ctrl;
}

enum EGameShowArenaAnnouncerFaceType
{
	Happy,
	Angry,
	Sad,
	Glitch,
	MAX
}

enum EGameShowArenaAnnouncerFaceState
{
	Normal,
	Glitching
}

enum EGameShowArenaAnnouncerState
{
	NoGlitching,
	RareGlitching,
	OccasionalGlitching,
	FrequentGlitching,
	PermanentGlitching
}

struct FGameShowArenaAnnouncerStateData
{
	FGameShowArenaAnnouncerStateData(float InGlitchLikeliHood, FVector2D InTimeInGlitchStateRange, FVector2D InTimeInNormalStateRange)
	{
		GlitchLikelihood = InGlitchLikeliHood;
		TimeInGlitchStateRange = InTimeInGlitchStateRange;
		TimeInNormalStateRange = InTimeInNormalStateRange;
	}

	float GlitchLikelihood = 0.0;

	FVector2D TimeInGlitchStateRange = FVector2D::ZeroVector;
	FVector2D TimeInNormalStateRange = FVector2D(1.0, 1.0);
}

struct FGameShowArenaAnnouncerFaceStateOverrideData
{
	FGameShowArenaAnnouncerFaceStateOverrideData(float Duration, EGameShowArenaAnnouncerFaceState NewState, FInstigator InInstigator)
	{
		RemainingDuration = Duration;
		State = NewState;
		Instigator = InInstigator;
	}

	FInstigator Instigator;
	float RemainingDuration;
	EGameShowArenaAnnouncerFaceState State;
}

struct FGameShowArenaAnnouncerFaceOverrideData
{
	FGameShowArenaAnnouncerFaceOverrideData(float Duration, int Face, FInstigator InInstigator)
	{
		FaceNr = Face;
		RemainingDuration = Duration;
		Instigator = InInstigator;
	}
	FInstigator Instigator;
	float RemainingDuration;
	int FaceNr;
}

asset UGameShowAnnouncerCapabilitySheet of UHazeCapabilitySheet
{
	Capabilities.Add(UGameShowArenaAnnouncerSplineFollowTargetCapability);
	Capabilities.Add(UGameShowArenaAnnouncerSplineMovementCapability);
	Capabilities.Add(UGameShowArenaAnnouncerLookAtTargetCapability);
	Capabilities.Add(UGameShowArenaAnnouncerFaceSwapCapability);
	Capabilities.Add(UGameShowArenaAnnouncerGlitchingFaceSwapCapability);
	Capabilities.Add(UGameShowArenaAnnouncerFaceModeSelectionCapability);
	Capabilities.Add(UGameShowArenaAnnouncerFaceUpdateCapability);
}

event void FGameShowArenaAnnouncerOnBombDunkedInHead();
class AGameShowArenaAnnouncer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent SkeletalMeshComp;
	default SkeletalMeshComp.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = SkeletalMeshComp, AttachSocket = "FaceSocket")
	UStaticMeshComponent FaceMeshComp;
	default FaceMeshComp.RelativeRotation = FRotator::MakeFromEuler(FVector(180, -90, 0));

	UPROPERTY(DefaultComponent, Attach = SkeletalMeshComp, AttachSocket = "HatchSocket")
	UStaticMeshComponent HatchMeshComp;
	default HatchMeshComp.RelativeRotation = HatchRelativeRotation;

	UPROPERTY(DefaultComponent, Attach = SkeletalMeshComp, AttachSocket = "Arm13")
	UInteractionComponent MioInteractionComp;
	default MioInteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	default MioInteractionComp.bStartDisabled = true;
	default MioInteractionComp.InteractionCapabilityClass = UGameShowArenaHatchInteractionCapability;

	UPROPERTY(DefaultComponent, Attach = SkeletalMeshComp, AttachSocket = "Arm13")
	UInteractionComponent ZoeInteractionComp;
	default ZoeInteractionComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ZoeInteractionComp.bStartDisabled = true;
	default ZoeInteractionComp.InteractionCapabilityClass = UGameShowArenaHatchInteractionCapability;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(UGameShowAnnouncerCapabilitySheet);

	UPROPERTY(DefaultComponent)
	UGameShowArenaAnnouncerFaceComponent FaceComp;

	UPROPERTY(DefaultComponent)
	UGameShowArenaAnnouncerBodyComponent BodyComp;

#if EDITOR // SequenceResponseComponent only needed to preview faces, in gameplay handled by UGameShowArenaAnnouncerFaceUpdateCapability
	UPROPERTY(DefaultComponent)
	UHazeLevelSequenceResponseComponent SequenceResponseComponent;
	default SequenceResponseComponent.OnSequenceUpdate.AddUFunction(this, n"OnSequenceUpdate");
#endif

	UPROPERTY()
	UHazeAudioEffectShareSet GlitchEffectShareSet;

	UPROPERTY(EditAnywhere)
	AGameShowArenaAnnouncer TalkingAnnouncer;

	/** Spline that the root can move along */
	UPROPERTY(EditAnywhere)
	ASplineActor MovementSpline;

	UPROPERTY(EditAnywhere)
	EHazePlayer PlayerToFollow;

	UPROPERTY()
	FGameShowArenaAnnouncerOnBombDunkedInHead OnBombDunkedInHead;

	AHazePlayerCharacter TargetPlayer;
	AGameShowArenaAnnouncerTarget TargetPoint;

	FSplinePosition CurrentSplinePosition;

	float StoppingDistance = 2000;

	FVector2D LowerPistonRange = FVector2D(-700, 0);
	FVector2D UpperPistonRange = FVector2D(-1500, 0);

	bool bFollowTarget = false;
	bool bHasQueuedMoveSnap = false;

	UPROPERTY(EditAnywhere)
	bool bLookAtTarget = true;

	UPROPERTY(EditAnywhere)
	EGameShowArenaAnnouncerState InitialState;

	UPROPERTY(EditAnywhere)
	bool bStartDisabled = true;

	UPROPERTY(EditAnywhere)
	bool bAutoChangeBetweenHappyFaces = false;

	FVector SplineCenter;

	TInstigated<EGameShowArenaAnnouncerFaceState> FaceState;
	default FaceState.DefaultValue = EGameShowArenaAnnouncerFaceState::Normal;

	TInstigated<EGameShowArenaAnnouncerState> State;

	TMap<EGameShowArenaAnnouncerState, FGameShowArenaAnnouncerStateData> StateData;
	default StateData.Add(EGameShowArenaAnnouncerState::NoGlitching,
						  FGameShowArenaAnnouncerStateData());

	default StateData.Add(EGameShowArenaAnnouncerState::RareGlitching,
						  FGameShowArenaAnnouncerStateData(0.1, FVector2D(0.1, 0.1), FVector2D(2.0, 2.5)));

	default StateData.Add(EGameShowArenaAnnouncerState::OccasionalGlitching,
						  FGameShowArenaAnnouncerStateData(0.3, FVector2D(0.2, 0.4), FVector2D(1.0, 1.6)));

	default StateData.Add(EGameShowArenaAnnouncerState::FrequentGlitching,
						  FGameShowArenaAnnouncerStateData(0.62, FVector2D(0.3, 0.5), FVector2D(0.4, 0.8)));

	TInstigated<AHazeActor> TargetOverride;

	TPerPlayer<bool> InitializedPlayerComps;

	UPROPERTY(EditAnywhere)
	float LowerPistonExtend;
	UPROPERTY(EditAnywhere)
	float UpperPistonExtend;
	UPROPERTY(EditAnywhere)
	float BaseTwist;
	UPROPERTY(EditAnywhere)
	float BodyRotation;
	UPROPERTY(EditAnywhere)
	float TargetSplineDistance;
	UPROPERTY(EditAnywhere)
	FVector IKArm8CtrlLocation;
	UPROPERTY(EditAnywhere)
	FTransform IKArm13Ctrl;

	/** Face override from sequence, disabled when FaceEyesIndex or FaceMouthIndex are used. */
	UPROPERTY(Interp, Category = "Sequence")
	int SEQFaceIndex = -1;

	/** Glitch state override from sequence, has prio over SEQFaceIndex*/
	UPROPERTY(Interp, Category = "Sequence")
	bool bIsSEQGlitching;

	UPROPERTY(Interp, Category = "Sequence")
	float GlitchEffectAlpha = 0;

	UPROPERTY(Interp, Category = "Sequence")
	int SEQFaceEyesIndex = -1;

	UPROPERTY(Interp, Category = "Sequence")
	int SEQFaceMouthIndex = -1;

	FRandomStream RandStream;

	int PreviousFace;

	UGameShowArenaAnnouncerHatchComponent HatchComp;
	FRotator HatchRelativeRotation = FRotator(0, 0, 180);

	bool bHasJustSnappedBody;


	UPROPERTY(EditAnywhere)
	bool bIsEndingAnnouncer = false;

#if EDITOR
	float CurrentPreviewTime;

	UFUNCTION(CallInEditor)
	void SnapInteractionsToAnimationPosition()
	{
		FTransform MioTransform(FRotator(0, 180, 0), FVector(113.7715, -3869.10678, -6205.232404), FVector::OneVector);
		FTransform ZoeTransform(FRotator(0.000000, 0.0, 0), FVector(-121.021105, -3869.185441, -6205.232404), FVector::OneVector);
		FTransform SocketTransform = SkeletalMeshComp.GetSocketTransform(n"Arm13", ERelativeTransformSpace::RTS_Component);
		MioInteractionComp.RelativeTransform = MioTransform.GetRelativeTransform(SocketTransform);
		ZoeInteractionComp.RelativeTransform = ZoeTransform.GetRelativeTransform(SocketTransform);
	}

	UFUNCTION()
	void OnSequenceUpdate(const FHazeLevelSequenceResponseData&in ResponseData)
	{
		if (bIsPreviewedBySequencer)
		{
			if (CurrentPreviewTime > ResponseData.CurrentTime || ResponseData.CurrentTime - CurrentPreviewTime > 1.0)
			{
				FaceComp.InitializeSEQPreview();
			}
			CurrentPreviewTime = ResponseData.CurrentTime;

			if (bIsSEQGlitching)
			{
				FaceComp.PreviewGlitching(ResponseData.CurrentTime);
				FaceComp.UpdateGlitchStrength(GlitchEffectAlpha);
			}
			else
			{
				FaceComp.UpdateFaceMaterialColor(FaceComp.DefaultFaceColor);
				FaceComp.UpdateFaceMaterialParams(SEQFaceIndex, SEQFaceEyesIndex, SEQFaceMouthIndex);
				FaceComp.UpdateGlitchStrength(GlitchEffectAlpha);
			}
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (HasControl())
		{
			CrumbInitRandStream(Math::Rand());
		}

		HatchComp = UGameShowArenaAnnouncerHatchComponent::Get(this);

		State.SetDefaultValue(InitialState);
		if (bStartDisabled)
		{
			DeactivateAnnouncer();
		}
		TargetPlayer = Game::GetPlayer(PlayerToFollow);

		if (MovementSpline == nullptr)
			return;

		SplineCenter = MovementSpline.Spline.BoundsOrigin;

		CurrentSplinePosition = MovementSpline.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		GameShowAnnouncer::DebugMovementLock.MakeVisible();

		for (auto Player : Game::Players)
		{
			auto Comp = UGameShowArenaBombTossPlayerComponent::Get(Player);
			if (Comp != nullptr)
			{
				Comp.OnPlayerCaughtBomb.AddUFunction(this, n"OnPlayerCaughtBomb");
				InitializedPlayerComps[Player] = true;
			}
		}
	}

	UFUNCTION()
	void HandleBombDunkedInHead()
	{
		UGameShowArenaHatchPlayerComponent::Get(Game::Mio).bFinalSequenceCompleted = true;
		UGameShowArenaHatchPlayerComponent::Get(Game::Zoe).bFinalSequenceCompleted = true;
		FGameShowArenaHatchBothPlayerParams Params;
		Params.PlayerHoldingBomb = HatchComp.BombHoldingPlayer;
		Params.PlayerHoldingHatch = HatchComp.HatchHoldingPlayer;
		UGameShowArenaAnnouncerEffectHandler::Trigger_OnBombDisposed(this, Params);
		OnBombDunkedInHead.Broadcast();
	}

	UFUNCTION()
	void DeactivateAnnouncer()
	{
		AddActorDisable(this);
	}
	UFUNCTION()
	void ActivateAnnouncer()
	{
		RemoveActorDisable(this);
		MioInteractionComp.EnableAfterStartDisabled();
		ZoeInteractionComp.EnableAfterStartDisabled();
	}

	UFUNCTION()
	void ActivateVoxMouthMovement(UHazeVoxAsset VoxAsset)
	{
		// if (VOComponent.HasActiveVox(VoxAsset))
		// 	return;

		// VOComponent.StartVox(VoxAsset);
	}

	UFUNCTION(CrumbFunction)
	void CrumbInitRandStream(int RandSeed)
	{
		RandStream = FRandomStream(RandSeed);
	}

	FGameShowArenaAnnouncerStateData GetCurrentStateData() const
	{
		return StateData[State.Get()];
	}

	UFUNCTION()
	void ChangeState(EGameShowArenaAnnouncerState NewState, FInstigator Instigator, EInstigatePriority Priority)
	{
		State.Apply(NewState, Instigator, Priority);
	}

	UFUNCTION(DevFunction)
	void AddLookAtTargetOverride(AHazeActor Target, FInstigator Instigator)
	{
		TargetOverride.Apply(Target, Instigator, EInstigatePriority::Override);
	}

	UFUNCTION(DevFunction)
	void ClearLookAtTargetOverride(FInstigator Instigator)
	{
		TargetOverride.Clear(Instigator);
	}

	UFUNCTION(DevFunction)
	void CopyDesiredHeadLocationRelative()
	{
		FTransform DesiredHeadTransform = BodyComp.GetDesiredHeadTransform(TargetPlayer);
		FVector RelativeHeadLocation = ActorTransform.InverseTransformPosition(DesiredHeadTransform.Location);
		FRotator RelativeHeadRotation = ActorTransform.InverseTransformRotation(DesiredHeadTransform.Rotation.Rotator());
		FTransform RelativeTransform = FTransform(RelativeHeadRotation, RelativeHeadLocation);
		Editor::CopyToClipBoard(RelativeTransform.ToString());
	}
	UFUNCTION(DevFunction)
	void CopyDesiredArm8LocationRelative()
	{
		FVector DesiredArm8Location = BodyComp.GetDesiredArm8Location(TargetPlayer);
		FVector RelativeLocation = ActorTransform.InverseTransformPosition(DesiredArm8Location);
		Editor::CopyToClipBoard(RelativeLocation.ToString());
	}
	UFUNCTION(DevFunction)
	void GoToTargetPoint(AGameShowArenaAnnouncerTarget Target, bool bSnap = false)
	{
		TargetPoint = Target;
		bFollowTarget = false;
		if (bSnap)
		{
			BlockCapabilities(CapabilityTags::Movement, this);
			auto SplinePos = MovementSpline.Spline.GetClosestSplinePositionToWorldLocation(Target.ActorLocation);
			TeleportActor(SplinePos.WorldLocation, SplinePos.WorldRotation.Rotator(), this);
			// Some nice values to initialize to when snapping
			BaseTwist = -81.13;
			BodyRotation = 0.013;
			LowerPistonExtend = -360.81;
			UpperPistonExtend = -773.17;
			IKArm13Ctrl = FTransform();
			IKArm8CtrlLocation = FVector::ZeroVector;
			bHasJustSnappedBody = true;
			Timer::SetTimer(this, n"SnapRotationsTimerTimeout", 0.1);
		}
	}

	UFUNCTION()
	private void SnapRotationsTimerTimeout()
	{
		UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(DevFunction)
	void FollowPlayers()
	{
		bFollowTarget = true;
		TargetPoint = nullptr;
	}

	UFUNCTION()
	private void OnPlayerCaughtBomb(AHazePlayerCharacter Player, AGameShowArenaBomb Bomb)
	{
		TargetPlayer = Player;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		TEMPORAL_LOG(this)
			.Value("BaseTwist", BaseTwist)
			.Value("BodyRotation", BodyRotation)
			.Value("IKArm13Ctrl", IKArm13Ctrl)
			.Sphere("IKArm8CtrlLocation", IKArm8CtrlLocation, 200, FLinearColor::LucBlue)
			.Value("LowerPistonExtend", LowerPistonExtend)
			.Value("UpperPistonExtend", UpperPistonExtend);
#endif
		if (!InitializedPlayerComps[Game::Mio] && !InitializedPlayerComps[Game::Zoe])
		{
			for (auto Player : Game::Players)
			{
				if (InitializedPlayerComps[Player])
					continue;

				auto Comp = UGameShowArenaBombTossPlayerComponent::Get(Player);
				if (Comp != nullptr)
				{
					Comp.OnPlayerCaughtBomb.AddUFunction(this, n"OnPlayerCaughtBomb");
					InitializedPlayerComps[Player] = true;
				}
			}
		}
	}

	UFUNCTION()
	private void OnZoeCaughtBomb()
	{
		TargetPlayer = Game::Zoe;
	}

	UFUNCTION()
	private void OnMioCaughtBomb()
	{
		TargetPlayer = Game::Mio;
	}

	UFUNCTION(DevFunction)
	void ChangeFollowPlayer()
	{
		if (TargetPlayer.IsMio())
			TargetPlayer = Game::Zoe;
		else
			TargetPlayer = Game::Mio;
	}
};

namespace GameShowAnnouncer
{
	const FHazeDevToggleBool DebugMovementLock = FHazeDevToggleBool(FHazeDevToggleCategory(n"AnnouncerMovement"), n"Movement Lock");

	UFUNCTION()
	void TriggerAnnouncerPresentationIntro(AGameShowArenaAnnouncer TalkingAnnouncer)
	{
		FGameShowArenaAnnouncerVOParams Params(TalkingAnnouncer);
		UGameShowArenaAnnouncerEffectHandler::Trigger_PresentationIntro(TalkingAnnouncer, Params);
	}
	UFUNCTION()
	void TriggerAnnouncerPresentationTutorial(AGameShowArenaAnnouncer TalkingAnnouncer)
	{
		FGameShowArenaAnnouncerVOParams Params(TalkingAnnouncer);
		UGameShowArenaAnnouncerEffectHandler::Trigger_PresentationTutorial(TalkingAnnouncer, Params);
	}
	UFUNCTION()
	void TriggerAnnouncerPresentationBombTossA(AGameShowArenaAnnouncer TalkingAnnouncer)
	{
		FGameShowArenaAnnouncerVOParams Params(TalkingAnnouncer);
		UGameShowArenaAnnouncerEffectHandler::Trigger_PresentationBombTossA(TalkingAnnouncer, Params);
	}
	UFUNCTION()
	void TriggerAnnouncerPresentationBombTossB(AGameShowArenaAnnouncer TalkingAnnouncer)
	{
		FGameShowArenaAnnouncerVOParams Params(TalkingAnnouncer);
		UGameShowArenaAnnouncerEffectHandler::Trigger_PresentationBombTossB(TalkingAnnouncer, Params);
	}
	UFUNCTION()
	void TriggerAnnouncerPresentationBombTossC(AGameShowArenaAnnouncer TalkingAnnouncer)
	{
		FGameShowArenaAnnouncerVOParams Params(TalkingAnnouncer);
		UGameShowArenaAnnouncerEffectHandler::Trigger_PresentationBombTossC(TalkingAnnouncer, Params);
	}
	UFUNCTION()
	void TriggerAnnouncerPresentationBombTossD(AGameShowArenaAnnouncer TalkingAnnouncer)
	{
		FGameShowArenaAnnouncerVOParams Params(TalkingAnnouncer);
		UGameShowArenaAnnouncerEffectHandler::Trigger_PresentationBombTossD(TalkingAnnouncer, Params);
	}
	UFUNCTION()
	void TriggerAnnouncerPresentationBombTossE(AGameShowArenaAnnouncer TalkingAnnouncer)
	{
		FGameShowArenaAnnouncerVOParams Params(TalkingAnnouncer);
		UGameShowArenaAnnouncerEffectHandler::Trigger_PresentationBombTossE(TalkingAnnouncer, Params);
	}
	UFUNCTION()
	void TriggerAnnouncerPresentationBombTossEnding(AGameShowArenaAnnouncer TalkingAnnouncer)
	{
		FGameShowArenaAnnouncerVOParams Params(TalkingAnnouncer);
		UGameShowArenaAnnouncerEffectHandler::Trigger_PresentationBombTossEnding(TalkingAnnouncer, Params);
	}
}