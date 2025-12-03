class UVillageStealthPlayerThrowCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AVillageStealthThrowablePile Pile;
	AVillageStealthThrowable Throwable;
	UVillageStealthPlayerComponent StealthPlayerComp;

	bool bThrown = false;
	bool bPickedUp = false;

	FHazeRuntimeSpline ThrowSpline;

	bool bLeftSide = false;

	bool bEntered = false;
	bool bExiting = false;
	bool bCancelled = false;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		if (!CheckInteraction.Owner.IsA(AVillageStealthThrowablePile))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		StealthPlayerComp = UVillageStealthPlayerComponent::Get(Player);
		Throwable = StealthPlayerComp.Throwable;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		bThrown = false;
		bEntered = false;
		bExiting = false;
		bCancelled = false;

		Pile = Cast<AVillageStealthThrowablePile>(ActiveInteraction.Owner);
		bLeftSide = Pile.bLeftSide;

		if (Pile.CameraActor != nullptr)
		{
			Player.ActivateCamera(Pile.CameraActor, 2.0, this, EHazeCameraPriority::High);
		}

		bEntered = false;
		FHazeAnimationDelegate EnterFinishedDelegate;
		EnterFinishedDelegate.BindUFunction(this, n"EnterFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Pile.EnterAnim;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), EnterFinishedDelegate, AnimParams);

		Player.BlockCapabilities(CapabilityTags::Movement, this);

		Timer::SetTimer(this, n"SpawnThrowable", 0.25);

		auto MoveComp = UPlayerMovementComponent::Get(Player);
		if (MoveComp != nullptr)
			MoveComp.ClearVerticalLerp();
	}

	UFUNCTION()
	private void SpawnThrowable()
	{
		if (HasControl() && IsActive())
			CrumbSpawnNewThrowable();
	}

	UFUNCTION()
	private void EnterFinished()
	{
		if (!IsActive())
			return;

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Pile.MhAnim;
		AnimParams.bLoop = true;
		Player.PlaySlotAnimation(AnimParams);
		
		bEntered = true;

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.Text = Pile.ThrowTutorialText;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, Pile.TargetOgre.RootComp, FVector(0.0, 0.0, 400.0), 0.0);

		Player.ShowCancelPrompt(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.RemoveTutorialPromptByInstigator(this);
		Player.RemoveCancelPromptByInstigator(this);

		if (Pile.CameraActor != nullptr)
			Player.DeactivateCamera(Pile.CameraActor);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.StopAllSlotAnimations();

		if (Throwable != nullptr && !Throwable.IsActorDisabled())
			DespawnThrowable();

		// Put the player back on the ground but lerp the mesh there as the player moves
		Player.SnapToGround(bLerpVerticalOffset=true, OverrideTraceDistance = 10);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bEntered)
			return;

		if (bExiting)
			return;

		if (bThrown)
			return;

		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
		{
			Crumb_Throw();
		}
		else if (WasActionStarted(ActionNames::Cancel))
		{
			Crumb_Cancel();
		}
	}

	UFUNCTION(CrumbFunction)
	void Crumb_Cancel()
	{
		Player.RemoveCancelPromptByInstigator(this);
		Player.RemoveTutorialPromptByInstigator(this);

		bExiting = true;
		bCancelled = true;
		FHazeAnimationDelegate CancelAnimFinishedDelegate;
		CancelAnimFinishedDelegate.BindUFunction(this, n"CancelAnimFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Pile.CancelAnim;
		AnimParams.BlendOutTime = Player.IsMio() ? 0.2 : Pile.ZoeCancelBlendTime;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), CancelAnimFinishedDelegate, AnimParams);

		if (Pile.CameraActor != nullptr)
			Player.DeactivateCamera(Pile.CameraActor);

		Timer::SetTimer(this, n"DespawnThrowable", 0.5);
	}

	UFUNCTION()
	private void DespawnThrowable()
	{
		Throwable.AddActorDisable(Throwable);
	}

	UFUNCTION()
	void CancelAnimFinished()
	{
		bExiting = true;
		Pile.InteractionComp.KickAnyPlayerOutOfInteraction();
	}

	UFUNCTION(CrumbFunction)
	void Crumb_Throw()
	{
		bThrown = true;

		Player.RemoveTutorialPromptByInstigator(this);
		Player.RemoveCancelPromptByInstigator(this);

		Throwable.OnHit.AddUFunction(this, n"ThrowableHit");

		FHazeAnimationDelegate ThrowAnimFinishedDelegate;
		ThrowAnimFinishedDelegate.BindUFunction(this, n"ThrowAnimFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Pile.ThrowAnim;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), ThrowAnimFinishedDelegate, AnimParams);
		Timer::SetTimer(this, n"ActuallyThrow", 0.2);
	}

	UFUNCTION()
	void ActuallyThrow()
	{
		ThrowSpline = FHazeRuntimeSpline();
		FVector StartLoc = Throwable.ActorLocation;
		ThrowSpline.AddPoint(StartLoc);
		FVector EndLoc = Pile.TargetOgre.SkelMeshComp.GetSocketLocation(n"Head") - FVector::UpVector * 150.0;
		FVector MidPoint = ((StartLoc + EndLoc)/2) + (FVector::UpVector * 200.0);

		ThrowSpline.AddPoint(MidPoint);
		ThrowSpline.AddPoint(EndLoc);
		Throwable.Throw(ThrowSpline);

		Player.PlayForceFeedback(Pile.ThrowForceFeedback, false, true, this);
	}

	UFUNCTION()
	private void ThrowAnimFinished()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Pile.ThrownMhAnim;
		AnimParams.bLoop = true;
		Player.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION()
	private void ThrowableHit(bool bHitOgre)
	{
		Throwable.OnHit.UnbindObject(this);

		FHazeAnimationDelegate ExitAnimFinishedDelegate;
		ExitAnimFinishedDelegate.BindUFunction(this, n"ExitAnimFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Pile.ExitAnim;
		AnimParams.BlendOutTime = Player.IsMio() ? 0.2 : Pile.ZoeThrownExitBlendTime;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), ExitAnimFinishedDelegate, AnimParams);

		bExiting = true;

		if (Pile.CameraActor != nullptr)
			Player.DeactivateCamera(Pile.CameraActor);

		Player.PlayForceFeedback(Pile.ThrowForceFeedback, false, true, this);
	}

	UFUNCTION()
	private void ExitAnimFinished()
	{
		bExiting = false;
		Pile.InteractionComp.KickAnyPlayerOutOfInteraction();
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnNewThrowable()
	{
		Throwable.ThrowedBy = Player;
		Throwable.PickUp();
		bPickedUp = true;

		FName AttachSocket = bLeftSide ? n"LeftAttach" : n"RightAttach";
		Throwable.AttachToComponent(Player.Mesh, AttachSocket);
		if (bLeftSide)
		{
			// Throwable.SetActorRelativeLocation(FVector(2.0, 1.0, 2.0));
			// Throwable.SetActorRelativeRotation(FRotator(0.0, 0.0, 180.0));
		}
		else
		{
			// Throwable.SetActorRelativeLocation(FVector(0.0, -3.0, 4.0));
		}
	}

	void DrawArc(FHazeRuntimeSpline InSpline)
	{
		FDebugDrawRuntimeSplineParams DrawParams;
		DrawParams.Width = 2;
		DrawParams.LineType = EDebugDrawRuntimeSplineLineType::Lines;
		DrawParams.bDrawStartPoint = false;
		DrawParams.bDrawSplinePoints = false;
		DrawParams.bDrawEndPoint = false;
		DrawParams.bDrawMovingPoint = false;
		DrawParams.LineColor = FLinearColor::White;
		DrawParams.MovingPointSpeed = 1;
		InSpline.DrawDebugSpline(DrawParams);
	}
}